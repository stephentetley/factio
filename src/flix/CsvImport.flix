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

    use Text.Charset.{Charset};

    use FactIO.CsvFormat;
    use FactIO.CsvFormat.{CsvFormat};
    use FactIO.CsvRowEvaluator;
    use FactIO.CsvRowEvaluator.{CsvRowEvaluator};

    ///
    /// Represents a CSV row.
    ///
    type alias CsvRow = ##flix.runtime.spt.factio.csv.CsvRow

    ///
    /// Returns a new Csv Cursor.
    ///
    pub def newCsvStream(filepath: System.FilePath,
                        format: CsvFormat,
                        cs: Text.Charset): Cursor[String, CsvRow] & Impure =
        import flix.runtime.spt.factio.csv.CsvIterator:createIteratorforFile(String, ##org.apache.commons.csv.CSVFormat, ##java.nio.charset.Charset) as newCsvIterator;
        import flix.runtime.spt.factio.csv.CsvIterator.hasNext() as ffiHasNext;
        import flix.runtime.spt.factio.csv.CsvIterator.next() as ffiNext;
        import flix.runtime.spt.factio.csv.CsvIterator.close() as ffiClose;
        try {
            let CsvFormat(fmt1) = format;
            let Charset(cs1) = cs;
            let iter = newCsvIterator(ToString.toString(filepath), fmt1, cs1);
            let nextF = () ->
                try {
                    Ok(ffiNext(iter))
                } catch {
                    case _: ##java.lang.Exception => Err("next failed")
                };
            let cursorIter =  {
                  hasNext = () -> ffiHasNext(iter)
                , next = nextF
                , finalize = () -> ffiClose(iter)
            };
            Cursor.makeCursor(cursorIter)
        } catch {
            case _: ##java.io.FileNotFoundException => Cursor.failure("newCsvStream - file not found")
            case _: ##java.io.IOException => Cursor.failure("IOException")
        }

    ///
    /// Returns a new Csv Stream from a file with a BOM.
    ///
    pub def newCsvStreamWithBOM(filepath: System.FilePath,
                                format: CsvFormat,
                                cs: Text.Charset): Cursor[String, CsvRow] & Impure =
        import flix.runtime.spt.factio.csv.CsvIterator:createIteratorforBOMFile(String, ##org.apache.commons.csv.CSVFormat, ##java.nio.charset.Charset) as newCsvIteratorWithBOM;
        import flix.runtime.spt.factio.csv.CsvIterator.hasNext() as ffiHasNext;
        import flix.runtime.spt.factio.csv.CsvIterator.next() as ffiNext;
        import flix.runtime.spt.factio.csv.CsvIterator.close() as ffiClose;
        try {
            let CsvFormat(fmt1) = format;
            let Charset(cs1) = cs;
            let iter = newCsvIteratorWithBOM(ToString.toString(filepath), fmt1, cs1);
            let cursorIter =  {
                  hasNext = () -> ffiHasNext(iter)
                , next = Cursor.guardThunk(_ -> ffiNext(iter), "next failed")
                , finalize = () -> ffiClose(iter)
            };
            Cursor.makeCursor(cursorIter)
        } catch {
            case _: ##java.io.FileNotFoundException => Cursor.failure("newCsvStream - file not found")
            case _: ##java.io.IOException => Cursor.failure("newCsvStream - io exception")
        }

    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRows(eval: CsvRowEvaluator[#{| reln}],
                        src: Cursor[String, CsvRow]): Result[#{| reln}, String] & Impure =
        let CsvRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.importRows(mf, src)



    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount(eval: Int32 -> CsvRowEvaluator[#{| reln}],
                                src: Cursor[String, CsvRow]): Result[#{| reln}, String] & Impure =
        let mf = (row, ix) -> { let CsvRowEvaluator(r1) = eval(ix); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCount(mf, src)

    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum(eval: st -> CsvRowEvaluator[(#{| reln}, st)],
                                state: st,
                                src: Cursor[String, CsvRow]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, st) -> { let CsvRowEvaluator(r1) = eval(st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithAccum(mf, state, src)

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum(eval: (Int32, st) -> CsvRowEvaluator[(#{| reln}, st)],
                                        state: st,
                                        src: Cursor[String, CsvRow]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, ix, st) -> { let CsvRowEvaluator(r1) = eval(ix, st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCountAndAccum(mf, state, src)

    ///
    /// Returns a list of applying `eval` to all rows in the input stream `src`.
    ///
    pub def evaluateRows(eval: CsvRowEvaluator[a],
                         src: Cursor[String, CsvRow]): Result[List[a], String] & Impure =
        let CsvRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.getRows(mf, src)

    /// Version of `evaluateRows` that skips empty rows in the source Csv.
    pub def evaluateRowsSkipEmptyRows(eval: CsvRowEvaluator[a],
                                        src: Cursor[String, CsvRow]): Result[List[a], String] & Impure =
        let CsvRowEvaluator(mf) = eval;
        src |> Cursor.filter(x -> not isEmptyRow(x))
            |> Cursor.mapResult(mf)
            |> Cursor.toList

    def isEmptyRow(row: CsvRow): Bool =
        import flix.runtime.spt.factio.csv.CsvRow.isEmptyRow() as primIsEmptyRow;
        row.primIsEmptyRow() as & Pure

}