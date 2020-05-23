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

use System.Error.{ArrayIndexOutOfBoundsException, IllegalArgumentException, IllegalStateException, IOException, Generic};
use Text.Charset.{Charset};

use FactIO.CsvFormat;
use FactIO.CsvRowEvaluator;
use FactIO.CsvRowEvaluator.{CsvRowEvaluator};

namespace FactIO/CsvImport {

    ///
    /// Represents a CSV row.
    ///
    type alias CsvRow = ##flix.runtime.factio.CsvRow

    ///
    /// Returns a new Csv Stream.
    ///
    pub def newCsvStream(filepath: String, format: CsvFormat, hasHeaders: Bool): Result[Stream[CsvRow], System.Error] & Impure=
        import new flix.runtime.factio.CsvIterator(String, Int32, Bool) as newCsvIterator;
        import flix.runtime.factio.CsvIterator.hasNext() as ffiHasNext;
        import flix.runtime.factio.CsvIterator.next() as ffiNext;
        import flix.runtime.factio.CsvIterator.close() as ffiClose;
        try {
            let fmt = FactIO/CsvFormat.toInt32(format);
            let iter = newCsvIterator(filepath, fmt, hasHeaders);
            let streamiter =  {
                  hasNext = () -> ffiHasNext(iter)
                , next = () -> ffiNext(iter)
                , finalize = () -> ffiClose(iter)
            };
            Ok(Stream.fromIterator(streamiter))
        } catch {
            case _: ##java.io.FileNotFoundException => Err(Generic("newCsvStream - file not found"))
            case _: ##java.io.IOException => Err(Generic("IOException"))
        }

    ///
    /// Returns a new Csv Stream from a file with a BOM.
    ///
    pub def newCsvStreamWithBOM(filepath: String, cs: Text.Charset, hasHeaders: Bool): Result[Stream[CsvRow], System.Error] & Impure =
        import new flix.runtime.factio.CsvIterator(String, ##java.nio.charset.Charset, Bool) as newCsvIterator;
        import flix.runtime.factio.CsvIterator.hasNext() as ffiHasNext;
        import flix.runtime.factio.CsvIterator.next() as ffiNext;
        import flix.runtime.factio.CsvIterator.close() as ffiClose;
        try {
            let Charset(cs1) = cs;
            let iter = newCsvIterator(filepath, cs1, hasHeaders);
            let streamiter =  {
                  hasNext = () -> ffiHasNext(iter)
                , next = () -> ffiNext(iter)
                , finalize = () -> ffiClose(iter)
            };
            Ok(Stream.fromIterator(streamiter))
        } catch {
            case _: ##java.io.FileNotFoundException => Err(Generic("newCsvStream - file not found"))
            case _: ##java.io.IOException => Err(Generic("newCsvStream - io exception"))
        }

    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRows(eval: CsvRowEvaluator[reln], src: Stream[CsvRow]): Result[reln, System.Error] & Impure =
        let CsvRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.importRows(mf, src)



    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount(eval: Int32 -> CsvRowEvaluator[reln], src: Stream[CsvRow]): Result[reln, System.Error] & Impure =
        let mf = (row, ix) -> { let CsvRowEvaluator(r1) = eval(ix); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCount(mf, src)

    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum(eval: st -> CsvRowEvaluator[(reln, st)], state: st, src: Stream[CsvRow]): Result[(reln, st), System.Error] & Impure =
        let mf = (row, st) -> { let CsvRowEvaluator(r1) = eval(st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithAccum(mf, state, src)

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum(eval: (Int32, st) -> CsvRowEvaluator[(reln, st)], state: st, src: Stream[CsvRow]): Result[(reln, st), System.Error] & Impure =
        let mf = (row, ix, st) -> { let CsvRowEvaluator(r1) = eval(ix, st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCountAndAccum(mf, state, src)



}