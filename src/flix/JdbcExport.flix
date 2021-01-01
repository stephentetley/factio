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




namespace FactIO {

    use Data/Transient.DList;
    
    pub opaque type JdbcExport[a] = FactIO/Internal/Jdbc.Output ~> Result[a, String]

    ///
    /// CsvWriteList is a workaround because fixpoint fold is our only way of
    /// extracting data from a relation and the step function of fixpoint fold
    /// must be pure - solution we build a list of impure "write" functions
    /// to be invoked after the fold.
    ///
    pub opaque type JdbcWriteList = DList[JdbcRowSetter[Unit]]

}

namespace FactIO/JdbcExport {


    use Data/Transient.DList;
    use Text.Charset.{Charset};

    use FactIO.JdbcExport;
    use FactIO.JdbcExport.{JdbcExport};
    use FactIO.JdbcWriteList;
    use FactIO.JdbcWriteList.{JdbcWriteList};

    use FactIO.JdbcRowSetter;
    use FactIO.JdbcRowSetter.{JdbcRowSetter};

    type alias PreparedStatement = FactIO/Internal/Jdbc.PreparedStatement

    pub def runJdbcExport(ma: JdbcExport[a], url: String): Result[a, String] & Impure =
        use Result.flatMap;
        use FactIO/Internal/Jdbc/Output.{new => newOutput};
        let* store = newOutput(url);
        apply1(ma, store)

    pub def runSQLiteExport(ma: JdbcExport[a], dbpath: System.FilePath): Result[a, String] & Impure =
        use System/FilePath.{normalize};
        let url = "jdbc:sqlite:${normalize(dbpath)}";
        runJdbcExport(ma, url)

    pub def runDuckDBExport(ma: JdbcExport[a], dbpath: System.FilePath): Result[a, String] & Impure =
        use System/FilePath.{normalize};
        let url = "jdbc:duckdb:${normalize(dbpath)}";
        runJdbcExport(ma, url)

    pub def return(x: a): JdbcExport[a] =
        JdbcExport(_ -> Ok(x) as & Impure)

    def apply1(x: JdbcExport[a], r: FactIO/Internal/Jdbc.Output): Result[a, String] & Impure =
        let JdbcExport(f) = x;
        f(r)

    pub def fail(e: String): JdbcExport[a] =
        JdbcExport(_ -> Err(e) as & Impure)

    pub def map(f: a -> b & ef, x: JdbcExport[a]): JdbcExport[b] =
        JdbcExport(r ->
            match apply1(x, r) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )

    pub def ap(mf: JdbcExport[a -> b & ef], ma: JdbcExport[a]): JdbcExport[b] =
        JdbcExport(r ->
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


    pub def bind(x: JdbcExport[a], k: a -> JdbcExport[b]): JdbcExport[b] =
        JdbcExport(r ->
            match apply1(x, r) {
                case Ok(a) => { let ans = k(a); apply1(ans, r) }
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> JdbcExport[b], x: JdbcExport[a]): JdbcExport[b] = bind(x, k)


    pub def mapM(mf: a -> JdbcExport[b], xs: List[a]): JdbcExport[List[b]] =
        JdbcExport(r ->
            mapMHelper(r, mf, xs, e -> Err(e), ys -> Ok(ys))
        )

    ///
    /// Helper function for `mapM`.
    ///
    def mapMHelper(r: FactIO/Internal/Jdbc.Output, mf: a -> JdbcExport[b], xs: List[a], fk: String -> Result[List[b], String], sk: List[b] -> Result[List[b], String]): Result[List[b], String] & Impure =
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

    pub def mapX(mf: a -> JdbcExport[b], xs: List[a]): JdbcExport[Unit] =
        JdbcExport(r ->
            mapXHelper(r, mf, xs, e -> Err(e), _ -> Ok())
        )

    def mapXHelper(r: FactIO/Internal/Jdbc.Output, mf: a -> JdbcExport[b], xs: List[a], fk: String -> Result[Unit, String], sk: Unit -> Result[Unit, String]): Result[Unit, String] & Impure =
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


    pub def sequence(xs: List[JdbcExport[a]]): JdbcExport[List[a]] =
        JdbcExport(r ->
            sequenceHelper(r, xs, e -> Err(e), ks -> Ok(ks))
        )

    ///
    /// Helper function for `sequence`.
    ///
    def sequenceHelper(r: FactIO/Internal/Jdbc.Output, xs: List[JdbcExport[a]], fk: String -> Result[List[a], String], sk: List[a] -> Result[List[a], String]): Result[List[a], String] & Impure =
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
    pub def traverse(f: a -> JdbcExport[b], xs: List[a]): JdbcExport[List[b]] = mapM(f, xs)

    ///
    /// `traverseX` is a synonym for `mapX`.
    ///
    pub def traverseX(f: a -> JdbcExport[b], xs: List[a]): JdbcExport[Unit] = mapX(f, xs)

    ///
    /// `forM` is `mapM` with its arguments flipped.
    ///
    pub def forM(xs: List[a], f: a -> JdbcExport[b]): JdbcExport[List[b]] = mapM(f, xs)

    ///
    /// `forX` is `mapX` with its arguments flipped.
    ///
    pub def forX(xs: List[a], f: a -> JdbcExport[b]): JdbcExport[Unit] = mapX(f, xs)


    pub def foldM(mf: (b, a) -> JdbcExport[b], start: b, xs: List[a]): JdbcExport[b] =
        JdbcExport(r ->
            foldMHelper(r, mf, start, xs, e -> Err(e), ac -> Ok(ac))
        )

    def foldMHelper(r: FactIO/Internal/Jdbc.Output, mf: (b, a) -> JdbcExport[b], acc: b, xs: List[a], fk: String -> Result[b, String], sk: b -> Result[b, String]): Result[b, String] & Impure =
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


    pub def mapAccumM(mf: (ac, a) -> JdbcExport[(ac, b)], start: ac, xs: List[a]): JdbcExport[(ac, List[b])] =
        JdbcExport(r ->
            mapAccumMHelper(r, mf, start, xs, e -> Err(e), (ac, ks) -> Ok((ac, ks)))
        )

    def mapAccumMHelper(r: FactIO/Internal/Jdbc.Output,
                        mf: (ac, a) -> JdbcExport[(ac, b)],
                        ac: ac,
                        xs: List[a],
                        fk: String -> Result[(ac, List[b]), String],
                        sk: (ac, List[b]) -> Result[(ac, List[b]), String]): Result[(ac, List[b]), String] & Impure =
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
    pub def mapAccumX(mf: (ac, a) -> JdbcExport[ac], start: ac, xs: List[a]): JdbcExport[ac] = foldM(mf, start, xs)

    pub def liftAction(fn: Unit ~> a): JdbcExport[a] =
        JdbcExport(_ -> { let a = fn(); Ok(a) })

    pub def liftActionResult(fn: Unit ~> Result[a, String]): JdbcExport[a] =
        JdbcExport(_ -> fn())

    /// Not exported.
    def liftPrim(prim: FactIO/Internal/Jdbc.Output ~> Result[a, String]): JdbcExport[a] =
        JdbcExport(r -> prim(r))

    pub def close(): JdbcExport[Unit] =
        use FactIO/Internal/Jdbc/Output.{close};
        liftPrim(x -> x.close())

    pub def setAutoCommit(autoCommit: Bool): JdbcExport[Unit] =
        use FactIO/Internal/Jdbc/Output.{setAutoCommit};
        liftPrim(x -> x.setAutoCommit(autoCommit))

    pub def getAutoCommit(): JdbcExport[Bool] =
        use FactIO/Internal/Jdbc/Output.{getAutoCommit};
        liftPrim(x -> x.getAutoCommit())

    /// Performs a check first...
    pub def setAutoCommitOff(): JdbcExport[Unit] =
        let* ans = getAutoCommit();
        if (ans) setAutoCommit(false) else return()

    pub def commit(): JdbcExport[Unit] =
        use FactIO/Internal/Jdbc/Output.{commit};
        liftPrim(x -> x.commit())

    pub def execute(sql: String): JdbcExport[Bool] =
        use FactIO/Internal/Jdbc/Output.{execute};
        liftPrim(x -> x.execute(sql))


    pub def prepareStatement(sql: String): JdbcExport[PreparedStatement] =
        use FactIO/Internal/Jdbc/Output.{prepareStatement};
        liftPrim(x -> x.prepareStatement(sql))

    pub def emptyJdbcWriteList(): JdbcWriteList =
        use Data/Transient/DList.{empty};
        JdbcWriteList(empty())

    pub def makeJdbcWriteStep(f: x -> JdbcRowSetter[Unit]): (x, JdbcWriteList) -> JdbcWriteList =
        (x, ws) ->
            let JdbcWriteList(ws1) = ws;
            let w1 = f(x);
            JdbcWriteList(Data/Transient/DList.snoc(ws1, w1))

    pub def execWriteList(sql: String, xs: JdbcWriteList): JdbcExport[Int32] =
        let JdbcWriteList(xs1) = xs;
        let writes = Data/Transient/DList.toList(xs1);
        let* stmt = prepareStatement(sql);
        execWriteListHelper(stmt, 0, writes)

    def execWriteListHelper(stmt: PreparedStatement, ac: Int32, xs: List[JdbcRowSetter[Unit]]): JdbcExport[Int32] = match xs {
        case Nil => return(ac)
        case mx :: rs => {
            let* n = writeRow(stmt, mx);
            execWriteListHelper(stmt, ac + n, rs)
        }
    }

    pub def writeRow(stmt: PreparedStatement, mx: JdbcRowSetter[a]): JdbcExport[Int32] =
        let JdbcRowSetter(mf) = mx;
        let* _ = liftActionResult(_ -> FactIO/Internal/Jdbc/PreparedStatement.clearParameters!(stmt));
        let* _ = liftActionResult(_ -> mf(stmt));
        let* n = liftActionResult(_ -> FactIO/Internal/Jdbc/PreparedStatement.executeUpdate(stmt));
        return(n)

    ///
    pub def mapRowSetterX(stmt: PreparedStatement, f: a -> JdbcRowSetter[b], xs: List[a]): JdbcExport[Unit] = match xs {
        case Nil            => return()
        case x :: rs        => {
            let mx = f(x);
            let* _ = writeRow(stmt, mx);
            mapRowSetterX(stmt, f, rs)
        }
    }

    pub def streamRowSetterX(stmt: PreparedStatement, f: a -> JdbcRowSetter[b], ss: Data.Stream[a]): JdbcExport[Unit] =
        use Data/Stream.{foreachResult};
        JdbcExport(r ->
            foreachResult(x -> apply1(writeRow(stmt, f(x)), r), ss)
        )

 }