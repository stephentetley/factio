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

use FactIO.Error.{ReadFieldByIndex, ReadFieldByLabel, Generic};


namespace FactIO/SQLiteImport {

    ///
    /// Represents a SQLite row.
    ///
    pub opaque type SQLiteRow = ##flix.runtime.factio.SQLiteRow

    type alias SQLiteResult[t] = Result[t, FactIO.Error]

    ///
    /// Returns a new SQLite Stream.
    ///
    pub def newSQLiteStream(filepath: String, query: String): Result[Stream[SQLiteRow], FactIO.Error] & Impure=
        import new flix.runtime.factio.SQLiteIterator(String, String) as newSQLiteIterator;
        import flix.runtime.factio.SQLiteIterator.next() as ffiHasNext;
        import flix.runtime.factio.SQLiteIterator.getRow() as ffiNext;
        import flix.runtime.factio.SQLiteIterator.close() as ffiClose;
        try {
            let iter = newSQLiteIterator(filepath, query);
            let streamiter =  {
                  hasNext = () -> ffiHasNext(iter)
                , next = () -> { let a = ffiNext(iter); SQLiteRow(a) }
                , finalize = () -> ffiClose(iter)
            };
            Ok(Stream.fromIterator(streamiter))
        } catch {
            case _: ##java.io.FileNotFoundException => Err(Generic("newSQLiteStream - file not found"))
            case _: ##java.io.IOException => Err(Generic("newSQLiteStream - io exception"))
        }

    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRows(rowreader: SQLiteRow -> SQLiteResult[reln] & Impure, src: Stream[SQLiteRow]): Result[reln, FactIO.Error] & Impure =
        FactIO/ImportStrategies.importRows(rowreader, src)

    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount(rowreader: (SQLiteRow, Int32) -> SQLiteResult[reln] & Impure, src: Stream[SQLiteRow]): Result[reln, FactIO.Error] & Impure =
        FactIO/ImportStrategies.importRowsWithCount(rowreader, src)

    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum(rowreader: (SQLiteRow, st) -> SQLiteResult[(reln, st)] & Impure, state: st, src: Stream[SQLiteRow]): Result[(reln, st), FactIO.Error] & Impure =
        FactIO/ImportStrategies.importRowsWithAccum(rowreader, state, src)

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum(rowreader: (SQLiteRow, Int32, st) -> SQLiteResult[(reln, st)] & Impure, state: st, src: Stream[SQLiteRow]): Result[(reln, st), FactIO.Error] & Impure =
        FactIO/ImportStrategies.importRowsWithCountAndAccum(rowreader, state, src)

    // Cell readers

    pub def getStringByIndex(row: SQLiteRow, ix: Int32): SQLiteResult[String] & e =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factio.SQLiteRow.getStringByIndex(Int32);
            let a = r1.getStringByIndex(ix) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.Exception => Err(ReadFieldByIndex(ix, "String"))
        }

    pub def getStringByLabel(row: SQLiteRow, label: String): SQLiteResult[String] & e =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factio.SQLiteRow.getStringByLabel(String);
            let a = r1.getStringByLabel(label) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.Exception => Err(ReadFieldByLabel(label, "String"))
        }

    pub def getInt8ByIndex(row: SQLiteRow, ix: Int32): SQLiteResult[Int8] & e =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factio.SQLiteRow.getByteByIndex(Int32);
            let a = r1.getByteByIndex(ix) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.Exception => Err(ReadFieldByIndex(ix, "Int8"))
        }

    pub def getInt8ByLabel(row: SQLiteRow, label: String): SQLiteResult[Int8] & e =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factio.SQLiteRow.getByteByLabel(String);
            let a = r1.getByteByLabel(label) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.Exception => Err(ReadFieldByLabel(label, "Int8"))
        }

    pub def getInt16ByIndex(row: SQLiteRow, ix: Int32): SQLiteResult[Int16] & e =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factio.SQLiteRow.getShortByIndex(Int32);
            let a = r1.getShortByIndex(ix) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.Exception => Err(ReadFieldByIndex(ix, "Int16"))
        }

    pub def getInt16ByLabel(row: SQLiteRow, label: String): SQLiteResult[Int16] & e =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factio.SQLiteRow.getShortByLabel(String);
            let a = r1.getShortByLabel(label) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.Exception => Err(ReadFieldByLabel(label, "Int16"))
        }

    pub def getInt32ByIndex(row: SQLiteRow, ix: Int32): SQLiteResult[Int32] & e =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factio.SQLiteRow.getIntByIndex(Int32);
            let a = r1.getIntByIndex(ix) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.Exception => Err(ReadFieldByIndex(ix, "Int32"))
        }

    pub def getInt32ByLabel(row: SQLiteRow, label: String): SQLiteResult[Int32] & e =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factio.SQLiteRow.getIntByLabel(String);
            let a = r1.getIntByLabel(label) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.Exception => Err(ReadFieldByLabel(label, "Int32"))
        }

    pub def getInt64ByIndex(row: SQLiteRow, ix: Int32): SQLiteResult[Int64] & e =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factio.SQLiteRow.getLongByIndex(Int32);
            let a = r1.getLongByIndex(ix) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.Exception => Err(ReadFieldByIndex(ix, "Int64"))
        }

    pub def getInt64ByLabel(row: SQLiteRow, label: String): SQLiteResult[Int64] & e =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factio.SQLiteRow.getLongByLabel(String);
            let a = r1.getLongByLabel(label) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.Exception => Err(ReadFieldByLabel(label, "Int64"))
        }

    pub def getFloat32ByIndex(row: SQLiteRow, ix: Int32): SQLiteResult[Float32] & e =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factio.SQLiteRow.getFloatByIndex(Int32);
            let a = r1.getFloatByIndex(ix) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.Exception => Err(ReadFieldByIndex(ix, "Float32"))
        }

    pub def getFloat32ByLabel(row: SQLiteRow, label: String): SQLiteResult[Float32] & e =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factio.SQLiteRow.getFloatByLabel(String);
            let a = r1.getFloatByLabel(label) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.Exception => Err(ReadFieldByLabel(label, "Float32"))
        }

    pub def getFloat64ByIndex(row: SQLiteRow, ix: Int32): SQLiteResult[Float64] & e =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factio.SQLiteRow.getDoubleByIndex(Int32);
            let a = r1.getDoubleByIndex(ix) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.Exception => Err(ReadFieldByIndex(ix, "Float32"))
        }

    pub def getFloat64ByLabel(row: SQLiteRow, label: String): SQLiteResult[Float64] & e =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factio.SQLiteRow.getDoubleByLabel(String);
            let a = r1.getDoubleByLabel(label) as & e;
            Ok(a)
        } catch {
            case _: ##java.lang.Exception => Err(ReadFieldByLabel(label, "Float64"))
        }

}