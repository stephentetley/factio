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

///
/// Represents a SQLite row.
///
opaque type SQLiteRow = ##flix.runtime.factimport.SQLiteRow

///
/// Represents a SQLite iterator.
///
opaque type SQLiteSource = ##flix.runtime.factimport.SQLiteIterator

type alias SQLiteResult[t] = Validation[t, String]

namespace SQLiteImport {

    ///
    /// Returns a new SQLite reader.
    ///
    pub def newSQLiteSource(filepath: String, query: String): Result[SQLiteSource, String] =
        try {
            import new flix.runtime.factimport.SQLiteIterator(String, String) as newSQLiteIterator;
            let iterator = newSQLiteIterator(filepath, query);
            SQLiteSource(iterator) |> Ok
        } catch {
            case _: ##java.sql.SQLException => Err("newSQLiteSource - file not found")
            case _: ##java.io.IOException => Err("newSQLiteSource - io exception")
        }

    def hasNext(iterator: SQLiteSource): Bool =
        let SQLiteSource(rator1) = iterator;
        try {
            import flix.runtime.factimport.SQLiteIterator.next();
            rator1.next()
        } catch {
            case _: ##java.sql.SQLException => false
        }

    def getRow(iterator: SQLiteSource): SQLiteRow =
        let SQLiteSource(rator1) = iterator;
        import flix.runtime.factimport.SQLiteIterator.getRow();
        let row = rator1.getRow();
        SQLiteRow(row)

    def finalize(_: SQLiteSource): Unit = ()

    def makeSQLiteIterator(): RowIterator[SQLiteSource, SQLiteRow] =
        { hasNext = hasNext,  getRow = getRow, finalize = finalize }

    pub def collect(f: SQLiteRow -> SQLiteResult[reln], src: SQLiteSource): Result[reln, String] =
        let iterator = makeSQLiteIterator();
        Strategies.collect(iterator, f, src)

    pub def collectWithCount(f: (SQLiteRow, Int32) -> SQLiteResult[reln], src: SQLiteSource): Result[reln, String] =
        let iterator = makeSQLiteIterator();
        Strategies.collectWithCount(iterator, f, src)



    pub def collectAccum(f: (SQLiteRow, st) -> SQLiteResult[(reln, st)], state: st, src: SQLiteSource): Result[(reln, st), String] =
        let iterator = makeSQLiteIterator();
        Strategies.collectAccum(iterator, f, state, src)

    pub def choose(f: SQLiteRow -> SQLiteResult[Option[reln]], src: SQLiteSource): Result[reln, String] =
        let iterator = makeSQLiteIterator();
        Strategies.choose(iterator, f, src)


    pub def chooseWithCount(f: (SQLiteRow, Int32) -> SQLiteResult[Option[reln]], src: SQLiteSource): Result[reln, String] =
        let iterator = makeSQLiteIterator();
        Strategies.chooseWithCount(iterator, f, src)


    pub def chooseAccum(f: (SQLiteRow, st) -> SQLiteResult[(Option[reln], st)], state: st, src: SQLiteSource): Result[(reln, st), String] =
        let iterator = makeSQLiteIterator();
        Strategies.chooseAccum(iterator, f, state, src)

    // Cell readers

    pub def getStringByIndex(row: SQLiteRow, ix: Int32): SQLiteResult[String] =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factimport.SQLiteRow.getStringByIndex(Int32);
            let a = r1.getStringByIndex(ix);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getStringByIndex: " + Int32.toString(ix))
        }

    pub def getStringByLabel(row: SQLiteRow, label: String): SQLiteResult[String] =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factimport.SQLiteRow.getStringByLabel(String);
            let a = r1.getStringByLabel(label);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getStringByLabel: " + label)
        }

    pub def getInt8ByIndex(row: SQLiteRow, ix: Int32): SQLiteResult[Int8] =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factimport.SQLiteRow.getByteByIndex(Int32);
            let a = r1.getByteByIndex(ix);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt8ByIndex: " + Int32.toString(ix))
        }

    pub def getInt8ByLabel(row: SQLiteRow, label: String): SQLiteResult[Int8] =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factimport.SQLiteRow.getByteByLabel(String);
            let a = r1.getByteByLabel(label);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt8ByLabel: " + label)
        }

    pub def getInt16ByIndex(row: SQLiteRow, ix: Int32): SQLiteResult[Int16] =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factimport.SQLiteRow.getShortByIndex(Int32);
            let a = r1.getShortByIndex(ix);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt16ByIndex: " + Int32.toString(ix))
        }

    pub def getInt16ByLabel(row: SQLiteRow, label: String): SQLiteResult[Int16] =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factimport.SQLiteRow.getShortByLabel(String);
            let a = r1.getShortByLabel(label);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt16ByLabel: " + label)
        }

    pub def getInt32ByIndex(row: SQLiteRow, ix: Int32): SQLiteResult[Int32] =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factimport.SQLiteRow.getIntByIndex(Int32);
            let a = r1.getIntByIndex(ix);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt32ByIndex: " + Int32.toString(ix))
        }

    pub def getInt32ByLabel(row: SQLiteRow, label: String): SQLiteResult[Int32] =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factimport.SQLiteRow.getIntByLabel(String);
            let a = r1.getIntByLabel(label);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt32ByLabel: " + label)
        }

    pub def getInt64ByIndex(row: SQLiteRow, ix: Int32): SQLiteResult[Int64] =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factimport.SQLiteRow.getLongByIndex(Int32);
            let a = r1.getLongByIndex(ix);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt64ByIndex: " + Int32.toString(ix))
        }

    pub def getInt64ByLabel(row: SQLiteRow, label: String): SQLiteResult[Int64] =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factimport.SQLiteRow.getLongByLabel(String);
            let a = r1.getLongByLabel(label);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt64ByLabel: " + label)
        }

    pub def getFloat32ByIndex(row: SQLiteRow, ix: Int32): SQLiteResult[Float32] =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factimport.SQLiteRow.getFloatByIndex(Int32);
            let a = r1.getFloatByIndex(ix);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getFloat32ByIndex: " + Int32.toString(ix))
        }

    pub def getFloat32ByLabel(row: SQLiteRow, label: String): SQLiteResult[Float32] =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factimport.SQLiteRow.getFloatByLabel(String);
            let a = r1.getFloatByLabel(label);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getFloat32ByLabel: " + label)
        }

    pub def getFloat64ByIndex(row: SQLiteRow, ix: Int32): SQLiteResult[Float64] =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factimport.SQLiteRow.getDoubleByIndex(Int32);
            let a = r1.getDoubleByIndex(ix);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getFloat64ByIndex: " + Int32.toString(ix))
        }

    pub def getFloat64ByLabel(row: SQLiteRow, label: String): SQLiteResult[Float64] =
        let SQLiteRow(r1) = row;
        try {
            import flix.runtime.factimport.SQLiteRow.getDoubleByLabel(String);
            let a = r1.getDoubleByLabel(label);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getFloat64ByLabel: " + label)
        }

}