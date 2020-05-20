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

namespace FactIO/CsvImport {

    ///
    /// Represents a CSV row.
    ///
    pub opaque type CsvRow = ##flix.runtime.factio.CsvRow

    
    type alias CsvResult[t] = Result[t, System.Error]


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
                , next = () -> { let a = ffiNext(iter); CsvRow(a) }
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
                , next = () -> { let a = ffiNext(iter); CsvRow(a) }
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
    pub def importRows(rowreader: CsvRow -> CsvResult[reln] & Impure, src: Stream[CsvRow]): Result[reln, System.Error] & Impure =
        FactIO/ImportStrategies.importRows(rowreader, src)



    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount(rowreader: (CsvRow, Int32) -> CsvResult[reln] & Impure, src: Stream[CsvRow]): Result[reln, System.Error] & Impure =
        FactIO/ImportStrategies.importRowsWithCount(rowreader, src)

    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum(rowreader: (CsvRow, st) -> CsvResult[(reln, st)] & Impure, state: st, src: Stream[CsvRow]): Result[(reln, st), System.Error] & Impure =
        FactIO/ImportStrategies.importRowsWithAccum(rowreader, state, src)

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum(rowreader: (CsvRow, Int32, st) -> CsvResult[(reln, st)] & Impure, state: st, src: Stream[CsvRow]): Result[(reln, st), System.Error] & Impure =
        FactIO/ImportStrategies.importRowsWithCountAndAccum(rowreader, state, src)


    // Cell readers

    pub def getStringByIndex(row: CsvRow, ix: Int32): CsvResult[String] & e =
        import flix.runtime.factio.CsvRow.getStringByIndex(Int32);
        try {
            let CsvRow(r1) = row;
            let a = r1.getStringByIndex(ix) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.ArrayIndexOutOfBoundsException => Err(ArrayIndexOutOfBoundsException)
            case _: ##java.lang.Exception => Err(Generic("Exception"))
        }

    ///
    /// Get a string by its column name / label.
    ///
    pub def getStringByLabel(row: CsvRow, label: String): CsvResult[String] & e =
        import flix.runtime.factio.CsvRow.getStringByLabel(String);
        try {
            let CsvRow(r1) = row;
            let a = r1.getStringByLabel(label) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
            case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
        }

    pub def getInt8ByIndex(row: CsvRow, ix: Int32): CsvResult[Int8] & e =
        import flix.runtime.factio.CsvRow.getByteByIndex(Int32);
        try {
            let CsvRow(r1) = row;
            let a = r1.getByteByIndex(ix) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.ArrayIndexOutOfBoundsException => Err(ArrayIndexOutOfBoundsException)
            case _: ##java.lang.Exception => Err(Generic("Exception"))
        }

    pub def getInt8ByLabel(row: CsvRow, label: String): CsvResult[Int8] & e =
        import flix.runtime.factio.CsvRow.getByteByLabel(String);
        try {
            let CsvRow(r1) = row;
            let a = r1.getByteByLabel(label) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
            case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
        }

    pub def getInt16ByIndex(row: CsvRow, ix: Int32): CsvResult[Int16] & e =
        import flix.runtime.factio.CsvRow.getShortByIndex(Int32);
        try {
            let CsvRow(r1) = row;
            let a = r1.getShortByIndex(ix) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.ArrayIndexOutOfBoundsException => Err(ArrayIndexOutOfBoundsException)
            case _: ##java.lang.Exception => Err(Generic("Exception"))
        }

    pub def getInt16ByLabel(row: CsvRow, label: String): CsvResult[Int16] & e =
        import flix.runtime.factio.CsvRow.getShortByLabel(String);
        try {
            let CsvRow(r1) = row;
            let a = r1.getShortByLabel(label) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
            case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
        }

    pub def getInt32ByIndex(row: CsvRow, ix: Int32): CsvResult[Int32] & e =
        import flix.runtime.factio.CsvRow.getIntByIndex(Int32);
        try {
            let CsvRow(r1) = row;
            let a = r1.getIntByIndex(ix) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.ArrayIndexOutOfBoundsException => Err(ArrayIndexOutOfBoundsException)
            case _: ##java.lang.Exception => Err(Generic("Exception"))
        }

    pub def getInt32ByLabel(row: CsvRow, label: String): CsvResult[Int32] & e =
        import flix.runtime.factio.CsvRow.getIntByLabel(String);
        try {
            let CsvRow(r1) = row;
            let a = r1.getIntByLabel(label) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
            case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
        }

    pub def getInt64ByIndex(row: CsvRow, ix: Int32): CsvResult[Int64] & e =
        import flix.runtime.factio.CsvRow.getLongByIndex(Int32);
        try {
            let CsvRow(r1) = row;
            let a = r1.getLongByIndex(ix) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.ArrayIndexOutOfBoundsException => Err(ArrayIndexOutOfBoundsException)
            case _: ##java.lang.Exception => Err(Generic("Exception"))
        }

    pub def getInt64ByLabel(row: CsvRow, label: String): CsvResult[Int64] & e =
        import flix.runtime.factio.CsvRow.getLongByLabel(String);
        try {
            let CsvRow(r1) = row;
            let a = r1.getLongByLabel(label) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
            case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
        }

    pub def getFloat32ByIndex(row: CsvRow, ix: Int32): CsvResult[Float32] & e =
        import flix.runtime.factio.CsvRow.getFloatByIndex(Int32);
        try {
            let CsvRow(r1) = row;
            let a = r1.getFloatByIndex(ix) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.ArrayIndexOutOfBoundsException => Err(ArrayIndexOutOfBoundsException)
            case _: ##java.lang.Exception => Err(Generic("Exception"))
        }

    pub def getFloat32ByLabel(row: CsvRow, label: String): CsvResult[Float32] & e =
        import flix.runtime.factio.CsvRow.getFloatByLabel(String);
        try {
            let CsvRow(r1) = row;
            let a = r1.getFloatByLabel(label) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
            case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
        }

    pub def getFloat64ByIndex(row: CsvRow, ix: Int32): CsvResult[Float64] & e =
        import flix.runtime.factio.CsvRow.getDoubleByIndex(Int32);
        try {
            let CsvRow(r1) = row;
            let a = r1.getDoubleByIndex(ix) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.ArrayIndexOutOfBoundsException => Err(ArrayIndexOutOfBoundsException)
            case _: ##java.lang.Exception => Err(Generic("Exception"))
        }

    pub def getFloat64ByLabel(row: CsvRow, label: String): CsvResult[Float64] & e =
        import flix.runtime.factio.CsvRow.getDoubleByLabel(String);
        try {
            let CsvRow(r1) = row;
            let a = r1.getDoubleByLabel(label) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
            case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
        }

    pub def getBigIntByIndex(row: CsvRow, ix: Int32): CsvResult[BigInt] & e =
        import flix.runtime.factio.CsvRow.getBigIntegerByIndex(Int32);
        try {
            let CsvRow(r1) = row;
            let a = r1.getBigIntegerByIndex(ix) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.ArrayIndexOutOfBoundsException => Err(ArrayIndexOutOfBoundsException)
            case _: ##java.lang.Exception => Err(Generic("Exception"))
        }

    pub def getBigIntByLabel(row: CsvRow, label: String): CsvResult[BigInt] & e =
        import flix.runtime.factio.CsvRow.getBigIntegerByLabel(String);        
        try {
            let CsvRow(r1) = row;
            let a = r1.getBigIntegerByLabel(label) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
            case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
        }

}