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

use Data.Stream;
use Text.Charset.{Charset};

use FactIO.CsvFormat;
use FactIO.CsvFormat.{CsvFormat};
use FactIO.CsvRowEvaluator;
use FactIO.CsvRowEvaluator.{CsvRowEvaluator};

namespace FactIO/CsvImport {

    use ToString.toString;

    ///
    /// Represents a CSV row.
    ///
    type alias CsvRow = ##flix.runtime.spt.factio.csv.CsvRow

    ///
    /// Returns a new Csv Stream.
    ///
    pub def newCsvStream(filepath: System.FilePath,
                        format: CsvFormat,
                        cs: Text.Charset): Result[Stream[CsvRow], String] & Impure =
        import flix.runtime.spt.factio.csv.CsvIterator:createIteratorforFile(String, ##org.apache.commons.csv.CSVFormat, ##java.nio.charset.Charset) as newCsvIterator;
        import flix.runtime.spt.factio.csv.CsvIterator.hasNext() as ffiHasNext;
        import flix.runtime.spt.factio.csv.CsvIterator.next() as ffiNext;
        import flix.runtime.spt.factio.csv.CsvIterator.close() as ffiClose;
        try {
            let CsvFormat(fmt1) = format;
            let Charset(cs1) = cs;
            let iter = newCsvIterator(toString(filepath), fmt1, cs1);
            let streamiter =  {
                  hasNext = () -> ffiHasNext(iter)
                , next = () -> ffiNext(iter)
                , finalize = () -> ffiClose(iter)
            };
            Ok(Data/Stream.fromIterator(streamiter))
        } catch {
            case _: ##java.io.FileNotFoundException => Err("newCsvStream - file not found")
            case _: ##java.io.IOException => Err("IOException")
        }

    ///
    /// Returns a new Csv Stream from a file with a BOM.
    ///
    pub def newCsvStreamWithBOM(filepath: System.FilePath,
                                format: CsvFormat,
                                cs: Text.Charset): Result[Stream[CsvRow], String] & Impure =
        import flix.runtime.spt.factio.csv.CsvIterator:createIteratorforBOMFile(String, ##org.apache.commons.csv.CSVFormat, ##java.nio.charset.Charset) as newCsvIteratorWithBOM;
        import flix.runtime.spt.factio.csv.CsvIterator.hasNext() as ffiHasNext;
        import flix.runtime.spt.factio.csv.CsvIterator.next() as ffiNext;
        import flix.runtime.spt.factio.csv.CsvIterator.close() as ffiClose;
        try {
            let CsvFormat(fmt1) = format;
            let Charset(cs1) = cs;
            let iter = newCsvIteratorWithBOM(toString(filepath), fmt1, cs1);
            let streamiter =  {
                  hasNext = () -> ffiHasNext(iter)
                , next = () -> ffiNext(iter)
                , finalize = () -> ffiClose(iter)
            };
            Ok(Data/Stream.fromIterator(streamiter))
        } catch {
            case _: ##java.io.FileNotFoundException => Err("newCsvStream - file not found")
            case _: ##java.io.IOException => Err("newCsvStream - io exception")
        }

    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRows(eval: CsvRowEvaluator[#{| reln}],
                        src: Stream[CsvRow]): Result[#{| reln}, String] & Impure =
        let CsvRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.importRows(mf, src)



    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount(eval: Int32 -> CsvRowEvaluator[#{| reln}],
                                src: Stream[CsvRow]): Result[#{| reln}, String] & Impure =
        let mf = (row, ix) -> { let CsvRowEvaluator(r1) = eval(ix); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCount(mf, src)

    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum(eval: st -> CsvRowEvaluator[(#{| reln}, st)],
                                state: st,
                                src: Stream[CsvRow]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, st) -> { let CsvRowEvaluator(r1) = eval(st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithAccum(mf, state, src)

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum(eval: (Int32, st) -> CsvRowEvaluator[(#{| reln}, st)],
                                        state: st,
                                        src: Stream[CsvRow]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, ix, st) -> { let CsvRowEvaluator(r1) = eval(ix, st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCountAndAccum(mf, state, src)

    ///
    /// Returns a list of applying `eval` to all rows in the input stream `src`.
    ///
    pub def evaluateRows(eval: CsvRowEvaluator[a],
                         src: Stream[CsvRow]): Result[List[a], String] & Impure =
        let CsvRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.getRows(mf, src)

    /// Version of `evaluateRows` that skips empty rows in the source Csv.
    pub def evaluateRowsSkipEmptyRows(eval: CsvRowEvaluator[a],
                                      src: Stream[CsvRow]): Result[List[a], String] & Impure =
        let CsvRowEvaluator(mf) = eval;
        let src1 = Data/Stream.filter(x -> not isEmptyRow(x), src);
        Data/Stream.traverseToListResult(mf, src1)

    def isEmptyRow(row: CsvRow): Bool =
        import flix.runtime.spt.factio.csv.CsvRow.isEmptyRow() as primIsEmptyRow;
        row.primIsEmptyRow() as & Pure

}