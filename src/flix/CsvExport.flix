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


    pub opaque type CsvExport[a] = (Map[String, Int32], FactIO/Internal/Csv.Output) ~> Result[a, String]

    /// CsvWriteList is a workaround because fixpoint fold is our only way of
    /// extracting data from a relation and the step function of fixpoint fold
    /// must be pure - solution we build a list of impure "write" functions
    /// to be invoked after the fold.
    pub opaque type CsvWriteList = Chain[CsvRowSetter[Unit]]

}

namespace FactIO/CsvExport {

    use Text.Charset.{Charset};

    use FactIO.CsvExport;
    use FactIO.CsvExport.{CsvExport};
    use FactIO.CsvWriteList;
    use FactIO.CsvWriteList.{CsvWriteList};
    use FactIO.CsvFormat;
    use FactIO.CsvFormat.{CsvFormat};

    use FactIO.CsvRowSetter;
    use FactIO.CsvRowSetter.{CsvRowSetter};


    def makeColumnIndices(headers: Array[String]): Map[String, Int32] & Impure =
        Array.foldLeft((ac, s) -> {let (m,i) = ac; (Map.insert(s, i, m), i+1)}, (Map.empty(), 0), headers) |> fst

    pub def runCsvExport(mx: CsvExport[a], path: System.FilePath, format: CsvFormat, headings: Array[String], cs: Text.Charset): Result[a, String] & Impure =
        use Result.flatMap;
        use FactIO/Internal/Csv/Output.{new => newOutput, close};
        let CsvFormat(fmt1) = format;
        let cellcount       = Array.length(headings);
        let headers         = makeColumnIndices(headings);
        let* handle         = Option.toOk(newOutput(ToString.toString(path), fmt1, cellcount, cs), "runCsvExport failed");
        let* ans            = apply1(bind(writeLine(headings), _ -> mx), headers, handle);
        let _               = handle.close();
        Ok(ans)


    pub def return(x: a): CsvExport[a] =
        CsvExport((_,_) -> Ok(x) as & Impure)

    pub def fail(e: String): CsvExport[a] =
       CsvExport((_,_) -> Err(e) as & Impure)

    def apply1(x: CsvExport[a], headers: Map[String, Int], r: FactIO/Internal/Csv.Output): Result[a, String] & Impure =
        let CsvExport(f) = x;
        f(headers, r)

    pub def map(f: a -> b & ef, x: CsvExport[a]): CsvExport[b] =
        CsvExport((hdrs, r) ->
            match apply1(x, hdrs, r) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )

    pub def ap(mf: CsvExport[a -> b & ef], ma: CsvExport[a]): CsvExport[b] =
        CsvExport((hdrs, r) ->
            match apply1(mf, hdrs, r) {
                case Ok(f) => {
                    match apply1(ma, hdrs, r) {
                        case Ok(a) => Ok(f(a) as & Impure)
                        case Err(e2) => Err(e2)
                    }
                }
                case Err(e1) => Err(e1)
            }
        )


    pub def bind(x: CsvExport[a], k: a -> CsvExport[b]): CsvExport[b] =
        CsvExport((hdrs, r) ->
            match apply1(x, hdrs, r) {
                case Ok(a) => { let ans = k(a); apply1(ans, hdrs, r) }
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> CsvExport[b], x: CsvExport[a]): CsvExport[b] = bind(x, k)

    pub def mapM(mf: a -> CsvExport[b], xs: List[a]): CsvExport[List[b]] =
        CsvExport((headers, r) ->
            mapMHelper(headers, r, mf, xs, e -> Err(e), ys -> Ok(ys))
        )

    def mapMHelper(headers: Map[String, Int32], r: FactIO/Internal/Csv.Output, mf: a -> CsvExport[b], xs: List[a], fk: String -> Result[List[b], String], sk: List[b] -> Result[List[b], String]): Result[List[b], String] & Impure =
        match xs {
            case Nil => sk(Nil)
            case x :: rs => {
                let ma = mf(x);
                match apply1(ma, headers, r) {
                    case Err(e) => fk(e)
                    case Ok(x1) => mapMHelper(headers, r, mf, rs, fk, ks -> sk(x1 :: ks))
                }
            }
        }

    pub def mapX(mf: a -> CsvExport[b], xs: List[a]): CsvExport[Unit] =
        CsvExport((headers, r) ->
            mapXHelper(headers, r, mf, xs, e -> Err(e), _ -> Ok())
        )

    def mapXHelper(headers: Map[String, Int32], r: FactIO/Internal/Csv.Output, mf: a -> CsvExport[b], xs: List[a], fk: String -> Result[Unit, String], sk: Unit -> Result[Unit, String]): Result[Unit, String] & Impure =
        match xs {
            case Nil => sk()
            case x :: rs => {
                let ma = mf(x);
                match apply1(ma, headers, r) {
                    case Err(e) => fk(e)
                    case Ok(_) => mapXHelper(headers, r, mf, rs, fk, sk)
                }
            }
        }

    pub def sequence(xs: List[CsvExport[a]]): CsvExport[List[a]] =
        CsvExport((headers, r) ->
            sequenceHelper(headers, r, xs, e -> Err(e), ys -> Ok(ys))
        )

    ///
    /// Helper function for `sequence`.
    ///
    def sequenceHelper(headers: Map[String, Int32], r: FactIO/Internal/Csv.Output, xs: List[CsvExport[a]], fk: String -> Result[List[a], String], sk: List[a] -> Result[List[a], String]): Result[List[a], String] & Impure =
        match xs {
            case Nil => sk(Nil)
            case mx :: rs => match apply1(mx, headers, r) {
                case Err(e) => fk(e)
                case Ok(x) => sequenceHelper(headers, r, rs, fk, ks -> sk(x :: ks))
            }
        }

    pub def liftAction(fn: Unit ~> a): CsvExport[a] =
        CsvExport((_,_) -> { let a = fn(); Ok(a) })

    pub def liftActionResult(fn: Unit ~> Result[a, String]): CsvExport[a] =
        CsvExport((_,_) -> fn())

    pub def emptyCsvWriteList(): CsvWriteList = CsvWriteList(Chain.empty())

    pub def makeCsvWriteStep(f: x -> CsvRowSetter[Unit]): (x, CsvWriteList) -> CsvWriteList =
        (x, ws) ->
            let CsvWriteList(ws1) = ws;
            let w1 = f(x);
            CsvWriteList(Chain.snoc(ws1, w1))

    pub def execWriteList(xs: CsvWriteList): CsvExport[Unit] =
        let CsvWriteList(xs1) = xs;
        let writes = Chain.toList(xs1);
        execWriteListHelper(writes)

    def execWriteListHelper(xs: List[CsvRowSetter[Unit]]): CsvExport[Unit] = match xs {
        case Nil => return()
        case mx :: rs => {
            let* _ = writeRow(mx);
            execWriteListHelper(rs)
        }
    }

    pub def writeLine(arr: Array[String]): CsvExport[Unit] =
        let* xs = liftAction(_ -> Array.toList(arr));
        let mx = makeSimpleWriter(0, xs);
        writeRow(mx)

    def makeSimpleWriter(ix: Int32, xs: List[String]): CsvRowSetter[Unit] =
        use FactIO/CsvRowSetter.{flatMap, putString!};
        match xs {
            case Nil => FactIO/CsvRowSetter.return()
            case x :: rs => {
                let* _ = putString!(ix, x);
                makeSimpleWriter(ix + 1, rs)
            }
        }



    pub def writeRow(mx: CsvRowSetter[a]): CsvExport[Unit] =
        let* _ = clearCells!();
        let* _ = execCsvRowSetter(mx);
        let* _ = primWriteRow();
        return()

    def clearCells!(): CsvExport[Unit] =
        CsvExport((_, r) -> Option.toOk(FactIO/Internal/Csv/Output.clearCells!(r), "clearCells!"))

    def primWriteRow(): CsvExport[Unit] =
        CsvExport((_, r) -> Option.toOk(FactIO/Internal/Csv/Output.writeRow(r), "primWriteRow"))

    def execCsvRowSetter(mx: CsvRowSetter[a]): CsvExport[Unit] =
        CsvExport((hdrs, r) ->
            let CsvRowSetter(mf) = mx;
            match mf(hdrs, r) {
                case Ok(_) => Ok()
                case Err(e) => Err(e)
            }
        )

    ///
    pub def mapRowSetterX(f: a -> CsvRowSetter[b], xs: List[a]): CsvExport[Unit] = match xs {
        case Nil            => return()
        case x :: rs        => {
            let mx = f(x);
            let* _ = writeRow(mx);
            mapRowSetterX(f, rs)
        }
    }

    pub def streamRowSetterX(f: a -> CsvRowSetter[b], iter: Iterator[Result[a, String]]): CsvExport[Unit] =
        CsvExport((hdrs, r) ->
            Iterator.foldLeftM((_, x1) -> {let a1 = f(x1); apply1(writeRow(a1), hdrs, r)}, (), iter)
        )

    ///
    /// Returns `(v1 :: v2 :: ... v :: vn)` if each of `f(xs_i)` is successful.
    /// Otherwise fails with the first error encountered.
    ///
    /// `traverse` is a synonym for `mapM`.
    ///
    pub def traverse(f: a -> CsvExport[b], xs: List[a]): CsvExport[List[b]] = mapM(f, xs)

    ///
    /// `traverseX` is a synonym for `mapX`.
    ///
    pub def traverseX(f: a -> CsvExport[b], xs: List[a]): CsvExport[Unit] = mapX(f, xs)

    ///
    /// `forM` is `mapM` with its arguments flipped.
    ///
    pub def forM(xs: List[a], f: a -> CsvExport[b]): CsvExport[List[b]] = mapM(f, xs)

    ///
    /// `forX` is `mapX` with its arguments flipped.
    ///
    pub def forX(xs: List[a], f: a -> CsvExport[b]): CsvExport[Unit] = mapX(f, xs)


    pub def foldM(mf: (b, a) -> CsvExport[b], start: b, xs: List[a]): CsvExport[b] =
        CsvExport((hdrs, r) ->
            foldMHelper(hdrs, r, mf, start, xs, e -> Err(e), ac -> Ok(ac))
        )

    def foldMHelper(headers: Map[String, Int32], r: FactIO/Internal/Csv.Output, mf: (b, a) -> CsvExport[b], acc: b, xs: List[a], fk: String -> Result[b, String], sk: b -> Result[b, String]): Result[b, String] & Impure =
        match xs {
            case Nil => sk(acc)
            case x :: rs => {
                let ma = mf(acc, x);
                match apply1(ma, headers, r) {
                    case Err(e) => fk(e)
                    case Ok(acc1) => foldMHelper(headers, r, mf, acc1, rs, fk, sk)
                }
            }
        }

    pub def mapAccumM(mf: (ac, a) -> CsvExport[(ac, b)], start: ac, xs: List[a]): CsvExport[(ac, List[b])] =
        CsvExport((hdrs, r) ->
            mapAccumMHelper(hdrs, r, mf, start, xs, e -> Err(e), (ac, ks) -> Ok((ac, ks)))
        )

    def mapAccumMHelper(headers: Map[String, Int32],
                        r: FactIO/Internal/Csv.Output,
                        mf: (ac, a) -> CsvExport[(ac, b)],
                        ac: ac,
                        xs: List[a],
                        fk: String -> Result[(ac, List[b]), String],
                        sk: (ac, List[b]) -> Result[(ac, List[b]), String]): Result[(ac, List[b]), String] & Impure =
        match xs {
            case Nil => sk(ac, Nil)
            case x :: rs => {
                let ma = mf(ac, x);
                match apply1(ma, headers, r) {
                    case Err(e) => fk(e)
                    case Ok((ac1, x1)) => mapAccumMHelper(headers, r, mf, ac1, rs, fk, (ac2, ks) -> sk(ac2, x1 :: ks))
                }
            }
        }

    ///
    /// `mapAccumX` is a synonym for `foldM`.
    ///
    pub def mapAccumX(mf: (ac, a) -> CsvExport[ac], start: ac, xs: List[a]): CsvExport[ac] = foldM(mf, start, xs)

}