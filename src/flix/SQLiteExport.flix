/*
 * Copyright 2020 Stephen Tetley
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

use Data/Transient.DList;
use System.Error.{IOException, Generic};
use Text.Charset.{Charset};

use FactIO.SQLiteExport;
use FactIO.SQLiteExport.{SQLiteExport};
use FactIO.SQLiteWriteList;
use FactIO.SQLiteWriteList.{SQLiteWriteList};

use FactIO.SQLiteRowWriter;
use FactIO.SQLiteRowWriter.{SQLiteRowWriter};



namespace FactIO {

    pub opaque type SQLiteExport[a] = FactIO/Internal/SQLite.Output ~> Result[a, System.Error]

    ///
    /// CsvWriteList is a workaround because fixpoint fold is our only way of
    /// extracting data from a relation and the step function of fixpoint fold
    /// must be pure - solution we build a list of impure "write" functions
    /// to be invoked after the fold.
    ///
    pub opaque type SQLiteWriteList = DList[SQLiteRowWriter[Unit]]

}

namespace FactIO/SQLiteExport {

    type alias PreparedStatement = FactIO/Internal/SQLite.PreparedStatement

    def makeConnectString(dbpath: String): String = "jdbc:sqlite:" + dbpath

    pub def runSQLiteExport(mx: SQLiteExport[a], dbpath: System.FilePath): Result[a, System.Error] & Impure =
        use Result.flatMap;
        use System/FilePath.{normalize, toString};
        use FactIO/Internal/SQLite/Output.{new => newOutput};
        let url = makeConnectString(dbpath.normalize().toString());
        let* store = newOutput(url);
        apply1(mx, store)



    pub def return(x: a): SQLiteExport[a] =
        SQLiteExport(_ -> Ok(x) as & Impure)

    def apply1(x: SQLiteExport[a], r: FactIO/Internal/SQLite.Output): Result[a, System.Error] & Impure =
        let SQLiteExport(f) = x;
        f(r)

    pub def fail(e: System.Error): SQLiteExport[a] =
        SQLiteExport(_ -> Err(e) as & Impure)

    pub def map(f: a -> b & ef, x: SQLiteExport[a]): SQLiteExport[b] =
        SQLiteExport(r ->
            match apply1(x, r) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )

    pub def ap(mf: SQLiteExport[a -> b & ef], ma: SQLiteExport[a]): SQLiteExport[b] =
        SQLiteExport(r ->
            match apply1(mf, r) {
                case Ok(f) => {
                    match apply1(ma, r) {
                        case Ok(a) => Ok(f(a) as & Impure)
                        case Err(e2) => Err(e2)
                    }
                }
                case Err(e1) => Err(e1)
            }
        )


    pub def bind(x: SQLiteExport[a], k: a -> SQLiteExport[b]): SQLiteExport[b] =
        SQLiteExport(r ->
            match apply1(x, r) {
                case Ok(a) => { let ans = k(a); apply1(ans, r) }
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> SQLiteExport[b], x: SQLiteExport[a]): SQLiteExport[b] = bind(x, k)


    pub def mapM(mf: a -> SQLiteExport[b], xs: List[a]): SQLiteExport[List[b]] =
        SQLiteExport(r ->
            mapMHelper(r, mf, xs, e -> Err(e), ys -> Ok(ys))
        )

    ///
    /// Helper function for `mapM`.
    ///
    def mapMHelper(r: FactIO/Internal/SQLite.Output, mf: a -> SQLiteExport[b], xs: List[a], fk: System.Error -> Result[List[b], System.Error], sk: List[b] -> Result[List[b], System.Error]): Result[List[b], System.Error] & Impure =
        match xs {
            case Nil => sk(Nil)
            case x :: rs => {
                let ma = mf(x);
                match apply1(ma, r) {
                    case Err(e) => fk(e)
                    case Ok(x1) => mapMHelper(r, mf, rs, fk, ks -> sk(x1 :: ks))
                }
            }
        }

    pub def mapX(mf: a -> SQLiteExport[b], xs: List[a]): SQLiteExport[Unit] =
        SQLiteExport(r ->
            mapXHelper(r, mf, xs, e -> Err(e), _ -> Ok())
        )

    def mapXHelper(r: FactIO/Internal/SQLite.Output, mf: a -> SQLiteExport[b], xs: List[a], fk: System.Error -> Result[Unit, System.Error], sk: Unit -> Result[Unit, System.Error]): Result[Unit, System.Error] & Impure =
        match xs {
            case Nil => sk()
            case x :: rs => {
                let ma = mf(x);
                match apply1(ma, r) {
                    case Err(e) => fk(e)
                    case Ok(_) => mapXHelper(r, mf, rs, fk, sk)
                }
            }
        }


    pub def sequence(xs: List[SQLiteExport[a]]): SQLiteExport[List[a]] =
        SQLiteExport(r ->
            sequenceHelper(r, xs, e -> Err(e), ks -> Ok(ks))
        )

    ///
    /// Helper function for `sequence`.
    ///
    def sequenceHelper(r: FactIO/Internal/SQLite.Output, xs: List[SQLiteExport[a]], fk: System.Error -> Result[List[a], System.Error], sk: List[a] -> Result[List[a], System.Error]): Result[List[a], System.Error] & Impure =
        match xs {
            case Nil => sk(Nil)
            case mx :: rs => match apply1(mx, r) {
                case Err(e) => fk(e)
                case Ok(x) => sequenceHelper(r, rs, fk, ks -> sk(x :: ks))
            }
        }


    ///
    /// Returns `(v1 :: v2 :: ... v :: vn)` if each of `f(xs_i)` is successful.
    /// Otherwise fails with the first error encountered.
    ///
    /// `traverse` is a synonym for `mapM`.
    ///
    pub def traverse(f: a -> SQLiteExport[b], xs: List[a]): SQLiteExport[List[b]] = mapM(f, xs)

    ///
    /// `traverseX` is a synonym for `mapX`.
    ///
    pub def traverseX(f: a -> SQLiteExport[b], xs: List[a]): SQLiteExport[Unit] = mapX(f, xs)

    ///
    /// `forM` is `mapM` with its arguments flipped.
    ///
    pub def forM(xs: List[a], f: a -> SQLiteExport[b]): SQLiteExport[List[b]] = mapM(f, xs)

    ///
    /// `forX` is `mapX` with its arguments flipped.
    ///
    pub def forX(xs: List[a], f: a -> SQLiteExport[b]): SQLiteExport[Unit] = mapX(f, xs)


    pub def foldM(mf: (b, a) -> SQLiteExport[b], start: b, xs: List[a]): SQLiteExport[b] =
        SQLiteExport(r ->
            foldMHelper(r, mf, start, xs, e -> Err(e), ac -> Ok(ac))
        )

    def foldMHelper(r: FactIO/Internal/SQLite.Output, mf: (b, a) -> SQLiteExport[b], acc: b, xs: List[a], fk: System.Error -> Result[b, System.Error], sk: b -> Result[b, System.Error]): Result[b, System.Error] & Impure =
        match xs {
            case Nil => sk(acc)
            case x :: rs => {
                let ma = mf(acc, x);
                match apply1(ma, r) {
                    case Err(e) => fk(e)
                    case Ok(acc1) => foldMHelper(r, mf, acc1, rs, fk, sk)
                }
            }
        }


    pub def mapAccumM(mf: (ac, a) -> SQLiteExport[(ac, b)], start: ac, xs: List[a]): SQLiteExport[(ac, List[b])] =
        SQLiteExport(r ->
            mapAccumMHelper(r, mf, start, xs, e -> Err(e), (ac, ks) -> Ok((ac, ks)))
        )

    def mapAccumMHelper(r: FactIO/Internal/SQLite.Output,
                        mf: (ac, a) -> SQLiteExport[(ac, b)],
                        ac: ac,
                        xs: List[a],
                        fk: System.Error -> Result[(ac, List[b]), System.Error],
                        sk: (ac, List[b]) -> Result[(ac, List[b]), System.Error]): Result[(ac, List[b]), System.Error] & Impure =
        match xs {
            case Nil => sk(ac, Nil)
            case x :: rs => {
                let ma = mf(ac, x);
                match apply1(ma, r) {
                    case Err(e) => fk(e)
                    case Ok((ac1, x1)) => mapAccumMHelper(r, mf, ac1, rs, fk, (ac2, ks) -> sk(ac2, x1 :: ks))
                }
            }
        }

    ///
    /// `mapAccumX` is a synonym for `foldM`.
    ///
    pub def mapAccumX(mf: (ac, a) -> SQLiteExport[ac], start: ac, xs: List[a]): SQLiteExport[ac] = foldM(mf, start, xs)

    pub def liftAction(fn: Unit ~> Result[a, System.Error]): SQLiteExport[a] =
        SQLiteExport(_ -> fn())


    def liftPrim(prim: FactIO/Internal/SQLite.Output ~> Result[a, System.Error]): SQLiteExport[a] =
        SQLiteExport(r -> prim(r))

    pub def close(): SQLiteExport[Unit] =
        use FactIO/Internal/SQLite/Output.{close};
        liftPrim(x -> x.close())

    pub def setAutoCommit(autoCommit: Bool): SQLiteExport[Unit] =
        use FactIO/Internal/SQLite/Output.{setAutoCommit};
        liftPrim(x -> x.setAutoCommit(autoCommit))

    pub def commit(): SQLiteExport[Unit] =
        use FactIO/Internal/SQLite/Output.{commit};
        liftPrim(x -> x.commit())

    pub def execute(sql: String): SQLiteExport[Bool] =
        use FactIO/Internal/SQLite/Output.{execute};
        liftPrim(x -> x.execute(sql))


    pub def prepareStatement(sql: String): SQLiteExport[PreparedStatement] =
        use FactIO/Internal/SQLite/Output.{prepareStatement};
        liftPrim(x -> x.prepareStatement(sql))

    pub def emptySQLiteWriteList(): SQLiteWriteList =
        use Data/Transient/DList.{empty};
        SQLiteWriteList(empty())

    pub def makeSQLiteWriteStep(f: x -> SQLiteRowWriter[Unit]): (x, SQLiteWriteList) -> SQLiteWriteList =
        (x, ws) ->
            let SQLiteWriteList(ws1) = ws;
            let w1 = f(x);
            SQLiteWriteList(Data/Transient/DList.snoc(ws1, w1))

    pub def execWriteList(sql: String, xs: SQLiteWriteList): SQLiteExport[Int32] =
        let SQLiteWriteList(xs1) = xs;
        let writes = Data/Transient/DList.toList(xs1);
        let* stmt = prepareStatement(sql);
        execWriteListHelper(stmt, 0, writes)

    def execWriteListHelper(stmt: PreparedStatement, ac: Int32, xs: List[SQLiteRowWriter[Unit]]): SQLiteExport[Int32] = match xs {
        case Nil => return(ac)
        case mx :: rs => {
            let* n = writeRow(stmt, mx);
            execWriteListHelper(stmt, ac + n, rs)
        }
    }

    pub def writeRow(stmt: PreparedStatement, mx: SQLiteRowWriter[a]): SQLiteExport[Int32] =
        let SQLiteRowWriter(mf) = mx;
        let* _ = liftAction(_ -> FactIO/Internal/SQLite/PreparedStatement.clearParameters!(stmt));
        let* _ = liftAction(_ -> mf(stmt));
        let* n = liftAction(_ -> FactIO/Internal/SQLite/PreparedStatement.executeUpdate(stmt));
        return(n)

    ///
    pub def mapRowWriterX(stmt: PreparedStatement, f: a -> SQLiteRowWriter[b], xs: List[a]): SQLiteExport[Unit] = match xs {
        case Nil            => return()
        case x :: rs        => {
            let mx = f(x);
            let* _ = writeRow(stmt, mx);
            mapRowWriterX(stmt, f, rs)
        }
    }

    pub def streamRowWriterX(stmt: PreparedStatement, f: a -> SQLiteRowWriter[b], ss: Data.Stream[a]): SQLiteExport[Unit] =
        use Data/Stream.{foreachResult};
        SQLiteExport(r ->
            foreachResult(x -> apply1(writeRow(stmt, f(x)), r), ss)
        )

 }