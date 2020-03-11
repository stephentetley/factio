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
/// Represents a CSV row.
///
opaque type CsvRow = ##flix.runtime.factio.CsvRow

///
/// Represents a CSV source (internally an iterator on a CSV file).
///
opaque type CsvSource = ##flix.runtime.factio.CsvIterator

type alias CsvResult[t] = Validation[t, String]

namespace CsvImport {

    ///
    /// See Apache Commons CSV User Guide for details:
    /// http://commons.apache.org/proper/commons-csv/user-guide.html
    ///
    pub enum CsvFormat {
        case Default,
        case Excel,
        case InformixUnload,
        case InformixUnloadCsv,
        case MongodbCsv,
        case MongodbTsv,
        case Mysql,
        case Rfc4180,
        case Oracle,
        case PostgresqlCsv,
        case PostgresqlText,
        case Tdf
    }

    def formatToInt(format: CsvFormat): Int32 = match format {
        case Default => 0
        case Excel => 1
        case InformixUnload => 2
        case InformixUnloadCsv => 3
        case MongodbCsv => 4
        case MongodbTsv => 5
        case Mysql => 6
        case Rfc4180 => 7
        case Oracle => 8
        case PostgresqlCsv => 9
        case PostgresqlText => 10
        case Tdf => 11
    }

    ///
    /// Returns a new CsvSource.
    ///
    pub def newCsvSource(filepath: String, format: CsvFormat, hasHeaders: Bool): Result[CsvSource, String] & Impure =
        let fmt = formatToInt(format);
        try {
            import new flix.runtime.factio.CsvIterator(String, Int32, Bool) as newCsvIterator;
            let iterator = newCsvIterator(filepath, fmt, hasHeaders);
            CsvSource(iterator) |> Ok
        } catch {
            case _: ##java.io.FileNotFoundException => Err("newCsvSource - file not found")
            case _: ##java.io.IOException => Err("newCsvSource - io exception")
        }

    def hasNext(src: CsvSource): Bool & Impure =
        let CsvSource(iterator) = src;
        import flix.runtime.factio.CsvIterator.hasNext();
        iterator.hasNext()

    def getRow(src: CsvSource): CsvRow & Impure =
        let CsvSource(iterator) = src;
        import flix.runtime.factio.CsvIterator.next();
        let csvRow = iterator.next();
        CsvRow(csvRow)

    def finalize(src: CsvSource): Unit & Impure =
        let CsvSource(iterator) = src;
        import flix.runtime.factio.CsvIterator.close();
        iterator.close()

    def makeCsvIterator(): RowIterator[CsvSource, CsvRow] =
        { hasNext = hasNext,  getRow = getRow, finalize = finalize }

    ///
    /// Track row number for errors.
    ///
    pub def eachrow(f: CsvRow -> CsvResult[reln] & e, src: CsvSource): Result[reln, String] & Impure =
        let iterator = makeCsvIterator();
        Strategies.eachrow(iterator, f, src)


    pub def eachrowWithCount(f: (CsvRow, Int32) -> CsvResult[reln] & e, src: CsvSource): Result[reln, String] & Impure =
        let iterator = makeCsvIterator();
        Strategies.eachrowWithCount(iterator, f, src)

    pub def eachrowAccum(f: (CsvRow, st) -> CsvResult[(reln, st)] & e, state: st, src: CsvSource): Result[(reln, st), String] & Impure =
        let iterator = makeCsvIterator();
        Strategies.eachrowAccum(iterator, f, state, src)


    pub def choose(f: CsvRow -> CsvResult[Option[reln]] & e, src: CsvSource): Result[reln, String] & Impure =
        let iterator = makeCsvIterator();
        Strategies.choose(iterator, f, src)

    pub def chooseWithCount(f: (CsvRow,Int32) -> CsvResult[Option[reln]] & e, src: CsvSource): Result[reln, String] & Impure =
        let iterator = makeCsvIterator();
        Strategies.chooseWithCount(iterator, f, src)


    pub def chooseAccum(f: (CsvRow, st) -> CsvResult[(Option[reln], st)] & e, state: st, src: CsvSource): Result[(reln, st), String] & Impure =
        let iterator = makeCsvIterator();
        Strategies.chooseAccum(iterator, f, state, src)


    // Cell readers

    pub def getStringByIndex(row: CsvRow, ix: Int32): CsvResult[String] & e =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factio.CsvRow.getStringByIndex(Int32);
            let a = r1.getStringByIndex(ix) as & e;
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getStringByIndex: " + Int32.toString(ix))
        }

    ///
    /// Get a string by its column name / label.
    ///
    pub def getStringByLabel(row: CsvRow, label: String): CsvResult[String] & e =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factio.CsvRow.getStringByLabel(String);
            let a = r1.getStringByLabel(label) as & e;
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getStringByLabel:" + label)
        }

    pub def getInt8ByIndex(row: CsvRow, ix: Int32): CsvResult[Int8] & e =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factio.CsvRow.getByteByIndex(Int32);
            let a = r1.getByteByIndex(ix) as & e;
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt8ByIndex: " + Int32.toString(ix))
        }

    pub def getInt8ByLabel(row: CsvRow, label: String): CsvResult[Int8] & e =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factio.CsvRow.getByteByLabel(String);
            let a = r1.getByteByLabel(label) as & e;
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt8ByLabel:" + label)
        }

    pub def getInt16ByIndex(row: CsvRow, ix: Int32): CsvResult[Int16] & e =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factio.CsvRow.getShortByIndex(Int32);
            let a = r1.getShortByIndex(ix) as & e;
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt16ByIndex: " + Int32.toString(ix))
        }

    pub def getInt16ByLabel(row: CsvRow, label: String): CsvResult[Int16] & e =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factio.CsvRow.getShortByLabel(String);
            let a = r1.getShortByLabel(label) as & e;
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt16ByLabel: " + label)
        }

    pub def getInt32ByIndex(row: CsvRow, ix: Int32): CsvResult[Int32] & e =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factio.CsvRow.getIntByIndex(Int32);
            let a = r1.getIntByIndex(ix) as & e;
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt32ByIndex: " + Int32.toString(ix))
        }

    pub def getInt32ByLabel(row: CsvRow, label: String): CsvResult[Int32] & e =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factio.CsvRow.getIntByLabel(String);
            let a = r1.getIntByLabel(label) as & e;
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt32ByLabel: " + label)
        }

    pub def getInt64ByIndex(row: CsvRow, ix: Int32): CsvResult[Int64] & e =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factio.CsvRow.getLongByIndex(Int32);
            let a = r1.getLongByIndex(ix) as & e;
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt64ByIndex: " + Int32.toString(ix))
        }

    pub def getInt64ByLabel(row: CsvRow, label: String): CsvResult[Int64] & e =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factio.CsvRow.getLongByLabel(String);
            let a = r1.getLongByLabel(label) as & e;
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt64ByLabel: " + label)
        }

    pub def getFloat32ByIndex(row: CsvRow, ix: Int32): CsvResult[Float32] & e =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factio.CsvRow.getFloatByIndex(Int32);
            let a = r1.getFloatByIndex(ix) as & e;
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getFloat32ByIndex: " + Int32.toString(ix))
        }

    pub def getFloat32ByLabel(row: CsvRow, label: String): CsvResult[Float32] & e =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factio.CsvRow.getFloatByLabel(String);
            let a = r1.getFloatByLabel(label) as & e;
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getFloat32ByLabel: " + label)
        }

    pub def getFloat64ByIndex(row: CsvRow, ix: Int32): CsvResult[Float64] & e =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factio.CsvRow.getDoubleByIndex(Int32);
            let a = r1.getDoubleByIndex(ix) as & e;
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getFloat64ByIndex: " + Int32.toString(ix))
        }

    pub def getFloat64ByLabel(row: CsvRow, label: String): CsvResult[Float64] & e =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factio.CsvRow.getDoubleByLabel(String);
            let a = r1.getDoubleByLabel(label) as & e;
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getFloat64ByLabel: " + label)
        }

    pub def getBigIntByIndex(row: CsvRow, ix: Int32): CsvResult[BigInt] & e =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factio.CsvRow.getBigIntegerByIndex(Int32);
            let a = r1.getBigIntegerByIndex(ix) as & e;
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getBigIntByIndex: " + Int32.toString(ix))
        }

    pub def getBigIntByLabel(row: CsvRow, label: String): CsvResult[BigInt] & e =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factio.CsvRow.getBigIntegerByLabel(String);
            let a = r1.getBigIntegerByLabel(label) as & e;
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getBigIntByLabel: " + label)
        }
}