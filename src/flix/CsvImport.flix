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


namespace FactIO/CsvImport {

    use System.FilePath.{FilePath};
    use Text.Charset.{Charset};

    use FactIO.CsvFormat;
    use FactIO.CsvFormat.{CsvFormat};
    use FactIO.CsvRowEvaluator;
    use FactIO.CsvRowEvaluator.{CsvRowEvaluator};

    ///
    /// Represents a CSV row.
    ///
    type alias CsvRow = ##flix.runtime.spt.factio.csv.CsvRow


    /// Csv needs closing

    pub opaque type CsvReadHandle[a] = (##flix.runtime.spt.factio.csv.CsvCursor, Iterator[Result[a, String]])

    pub def close(handle: CsvReadHandle[a]): Result[Unit, String] & Impure =
        import flix.runtime.spt.factio.csv.CsvCursor.close();
        let CsvReadHandle((x1, _)) = handle;
        try {
            close(x1);
            Ok()
        } catch {
            case _: ##java.lang.Exception => Err("close")
        }

    pub def getIterator(handle: CsvReadHandle[a]): Iterator[Result[a, String]] =
        let CsvReadHandle((_, i1)) = handle;
        i1


    ///
    /// Returns a new Csv Handle (iterator and a "close" handle).
    ///
    pub def newCsvReadHandle(format: CsvFormat,
                            cs: Text.Charset,
                            path: System.FilePath): Result[CsvReadHandle[CsvRow], String] & Impure =
        import flix.runtime.spt.factio.csv.CsvCursor:createCursorForFile(##java.nio.file.Path, ##org.apache.commons.csv.CSVFormat, ##java.nio.charset.Charset);
        import flix.runtime.spt.factio.csv.CsvCursor.hasNext();
        import flix.runtime.spt.factio.csv.CsvCursor.next();
        try {
            let FilePath(path1) = path;
            let CsvFormat(fmt1) = format;
            let Charset(cs1) = cs;
            let primIter = createCursorForFile(path1, fmt1, cs1);
            let iterDone = () -> if (hasNext(primIter)) false else true;
            let iterNext = () -> {
                try {
                    Ok(next(primIter))
                } catch {
                    case _: ##java.lang.Exception => Err("csvReadIter[next]")
                }
            };
            let iter1 = Iterator(iterDone, iterNext);
            let hdl = CsvReadHandle((primIter, iter1));
            Ok(hdl)
        } catch {
            case _: ##java.lang.Exception => Err("newCsvReadHandle")
        }

    ///
    /// Returns a new Csv Handle (iterator and a "close" handle).
    ///
    pub def newCsvReadHandleWithBOM(format: CsvFormat,
                                    path: System.FilePath): Result[CsvReadHandle[CsvRow], String] & Impure =
        import flix.runtime.spt.factio.csv.CsvCursor:createCursorForBOMFile(##java.nio.file.Path, ##org.apache.commons.csv.CSVFormat);
        import flix.runtime.spt.factio.csv.CsvCursor.hasNext();
        import flix.runtime.spt.factio.csv.CsvCursor.next();
        try {
            let FilePath(path1) = path;
            let CsvFormat(fmt1) = format;
            let primIter = createCursorForBOMFile(path1, fmt1);
            let iterDone = () -> if (hasNext(primIter)) false else true;
            let iterNext = () -> {
                try {
                    Ok(next(primIter))
                } catch {
                    case _: ##java.lang.Exception => Err("csvReadIter[next]")
                }
            };
            let iter1 = Iterator(iterDone, iterNext);
            let hdl = CsvReadHandle((primIter, iter1));
            Ok(hdl)
        } catch {
            case _: ##java.lang.Exception => Err("newCsvReadHandle")
        }

    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRows(eval: CsvRowEvaluator[#{| reln}],
                        iter: Iterator[Result[CsvRow, String]]): Result[#{| reln}, String] & Impure =
        let CsvRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.importRows(mf, iter)

    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount(eval: Int32 -> CsvRowEvaluator[#{| reln}],
                                iter: Iterator[Result[CsvRow, String]]): Result[#{| reln}, String] & Impure =
        let mf = (row, ix) -> { let CsvRowEvaluator(r1) = eval(ix); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCount(mf, iter)

    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum(eval: st -> CsvRowEvaluator[(#{| reln}, st)],
                                state: st,
                                iter: Iterator[Result[CsvRow, String]]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, st) -> { let CsvRowEvaluator(r1) = eval(st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithAccum(mf, state, iter)

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum(eval: (Int32, st) -> CsvRowEvaluator[(#{| reln}, st)],
                                        state: st,
                                        iter: Iterator[Result[CsvRow, String]]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, ix, st) -> { let CsvRowEvaluator(r1) = eval(ix, st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCountAndAccum(mf, state, iter)

    ///
    /// Returns a list of applying `eval` to all rows in the input stream `src`.
    ///
    pub def evaluateRows(eval: CsvRowEvaluator[a],
                         iter: Iterator[Result[CsvRow, String]]): Result[List[a], String] & Impure =
        let CsvRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.getRows(mf, iter)

    /// Version of `evaluateRows` that skips empty rows in the source Csv.
    pub def evaluateRowsSkipEmptyRows(eval: CsvRowEvaluator[a],
                                        iter: Iterator[Result[CsvRow, String]]): Result[List[a], String] & Impure =
        let CsvRowEvaluator(mf) = eval;
        let step = (ac, row) -> {
            match mf(row) {
                case Ok(a1) => Ok(a1 :: ac)
                case Err(e) => Err(e)
            }
        };
        iter
            |> Iterator.filter(x1 -> match x1 {
                    case Err(_) => true
                    case Ok(r1) => not isEmptyRow(r1)})
            |> Iterator.foldLeftM(step, Nil)
            |> Result.map(List.reverse)



    def isEmptyRow(row: CsvRow): Bool =
        import flix.runtime.spt.factio.csv.CsvRow.isEmptyRow() as primIsEmptyRow;
        row.primIsEmptyRow() as & Pure

}
