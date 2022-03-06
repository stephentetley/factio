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

    use X.Cursor;
    use X.Cursor.{Cursor};
    use System.FilePath.{FilePath};
    use Text.Charset.{Charset};

    use FactIO.CsvFormat;
    use FactIO.CsvFormat.{CsvFormat};
    use FactIO.CsvRowEvaluator;
    use FactIO.CsvRowEvaluator.{CsvRowEvaluator};

    ///
    /// Represents a CSV row.
    ///
    type alias CsvRow = ##flixspt.factio.csv.CsvRow

    ///
    /// Returns a new Csv Cursor.
    ///
    pub def newCsvCursor(format: CsvFormat,
                        cs: Text.Charset,
                        path: System.FilePath): Cursor[String, CsvRow] & Impure =
        import static flixspt.factio.csv.CsvCursor.createCursorForFile(##java.nio.file.Path, ##org.apache.commons.csv.CSVFormat, ##java.nio.charset.Charset): ##flixspt.factio.csv.CsvCursor & Impure;
        import flixspt.factio.csv.CsvCursor.hasNext(): Bool & Impure;
        import flixspt.factio.csv.CsvCursor.next(): ##flixspt.factio.csv.CsvRow & Impure;
        import flixspt.factio.csv.CsvCursor.close(): Unit & Impure;
        try {
            let FilePath(path1) = path;
            let CsvFormat(fmt1) = format;
            let Charset(cs1) = cs;
            let iter = createCursorForFile(path1, fmt1, cs1);
            let cursorIter =  {
                  hasNext = () -> hasNext(iter)
                , next = X/Cursor.guardThunk(_ -> next(iter), "next failed")
                , finalize = () -> close(iter)
            };
            X/Cursor.makeCursor(cursorIter)
        } catch {
            case _: ##java.io.FileNotFoundException => X/Cursor.failure("newCsvStream - file not found")
            case _: ##java.io.IOException => X/Cursor.failure("IOException")
        }

    ///
    /// Returns a new Csv Stream from a file with a BOM.
    ///
    pub def newCsvCursorWithBOM(format: CsvFormat,
                                path: System.FilePath): Cursor[String, CsvRow] & Impure =
        import static flixspt.factio.csv.CsvCursor.createCursorForBOMFile(##java.nio.file.Path, ##org.apache.commons.csv.CSVFormat): ##flixspt.factio.csv.CsvCursor & Impure;
        import flixspt.factio.csv.CsvCursor.hasNext(): Bool & Impure;
        import flixspt.factio.csv.CsvCursor.next(): ##flixspt.factio.csv.CsvRow & Impure;
        import flixspt.factio.csv.CsvCursor.close(): Unit & Impure;
        try {
            let FilePath(path1) = path;
            let CsvFormat(fmt1) = format;
            let iter = createCursorForBOMFile(path1, fmt1);
            let cursorIter =  {
                  hasNext = () -> hasNext(iter)
                , next = X/Cursor.guardThunk(_ -> next(iter), "next failed")
                , finalize = () -> close(iter)
            };
            X/Cursor.makeCursor(cursorIter)
        } catch {
            case _: ##java.io.FileNotFoundException => X/Cursor.failure("newCsvStream - file not found")
            case _: ##java.io.IOException => X/Cursor.failure("newCsvStream - io exception")
        }

    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRows(eval: CsvRowEvaluator[#{| reln}],
                        iter: Cursor[String, CsvRow]): Result[#{| reln}, String] & Impure =
        let CsvRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.importRows(mf, iter)

    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount(eval: Int32 -> CsvRowEvaluator[#{| reln}],
                                iter: Cursor[String, CsvRow]): Result[#{| reln}, String] & Impure =
        let mf = (row, ix) -> { let CsvRowEvaluator(r1) = eval(ix); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCount(mf, iter)

    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum(eval: st -> CsvRowEvaluator[(#{| reln}, st)],
                                state: st,
                                iter: Cursor[String, CsvRow]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, st) -> { let CsvRowEvaluator(r1) = eval(st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithAccum(mf, state, iter)

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum(eval: (Int32, st) -> CsvRowEvaluator[(#{| reln}, st)],
                                        state: st,
                                        iter: Cursor[String, CsvRow]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, ix, st) -> { let CsvRowEvaluator(r1) = eval(ix, st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCountAndAccum(mf, state, iter)

    ///
    /// Returns a list of applying `eval` to all rows in the input stream `src`.
    ///
    pub def evaluateRows(eval: CsvRowEvaluator[a],
                         iter: Cursor[String, CsvRow]): Result[List[a], String] & Impure =
        let CsvRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.getRows(mf, iter)

    /// Version of `evaluateRows` that skips empty rows in the source Csv.
    pub def evaluateRowsSkipEmptyRows(eval: CsvRowEvaluator[a],
                                        iter: Cursor[String, CsvRow]): Result[List[a], String] & Impure =
        let CsvRowEvaluator(mf) = eval;
        iter
            |> X/Cursor.filter(x -> not isEmptyRow(x))
            |> X/Cursor.mapResult(mf)
            |> X/Cursor.toList!

    def isEmptyRow(row: CsvRow): Bool & Impure =
        import flixspt.factio.csv.CsvRow.isEmptyRow(): Bool & Impure;
        isEmptyRow(row)

}
