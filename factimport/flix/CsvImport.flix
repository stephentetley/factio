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
opaque type CsvRow = ##flix.runtime.factimport.CsvRow

///
/// Represents a CSV source (internally an iterator on a CSV file).
///
opaque type CsvSource = ##flix.runtime.factimport.CsvIterator

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
    pub def newCsvSource(filepath: String, format: CsvFormat, hasHeaders: Bool): Result[CsvSource, String] =
        let fmt = formatToInt(format);
        try {
            import new flix.runtime.factimport.CsvIterator(String, Int32, Bool) as newCsvIterator;
            let iterator = newCsvIterator(filepath, fmt, hasHeaders);
            CsvSource(iterator) |> Ok
        } catch {
            case _: ##java.io.FileNotFoundException => Err("newCsvSource - file not found")
            case _: ##java.io.IOException => Err("newCsvSource - io exception")
        }

    def hasNext(src: CsvSource): Bool =
        let CsvSource(iterator) = src;
        import flix.runtime.factimport.CsvIterator.hasNext();
        iterator.hasNext()

    def getRow(src: CsvSource): CsvRow =
        let CsvSource(iterator) = src;
        import flix.runtime.factimport.CsvIterator.next();
        let csvRow = iterator.next();
        CsvRow(csvRow)

    def finalize(_: CsvSource): Unit = ()

    def makeCsvIterator(): RowIterator[CsvSource, CsvRow] =
        { hasNext = hasNext,  getRow = getRow, finalize = finalize }

    ///
    /// Track row number for errors.
    ///
    pub def collect(f: CsvRow -> CsvResult[reln], src: CsvSource): Result[reln, String] =
        let iterator = makeCsvIterator();
        Strategies.collect(iterator, f, src)


    pub def collectWithCount(f: (CsvRow, Int32) -> CsvResult[reln], src: CsvSource): Result[reln, String] =
        let iterator = makeCsvIterator();
        Strategies.collectWithCount(iterator, f, src)

    pub def collectAccum(f: (CsvRow, st) -> CsvResult[(reln, st)], state: st, src: CsvSource): Result[(reln, st), String] =
        let iterator = makeCsvIterator();
        Strategies.collectAccum(iterator, f, state, src)


    pub def choose(f: CsvRow -> CsvResult[Option[reln]], src: CsvSource): Result[reln, String] =
        let iterator = makeCsvIterator();
        Strategies.choose(iterator, f, src)

    pub def chooseWithCount(f: (CsvRow,Int32) -> CsvResult[Option[reln]], src: CsvSource): Result[reln, String] =
        let iterator = makeCsvIterator();
        Strategies.chooseWithCount(iterator, f, src)


    pub def chooseAccum(f: (CsvRow, st) -> CsvResult[(Option[reln], st)], state: st, src: CsvSource): Result[(reln, st), String] =
        let iterator = makeCsvIterator();
        Strategies.chooseAccum(iterator, f, state, src)


    // Cell readers

    pub def getStringByIndex(row: CsvRow, ix: Int32): CsvResult[String] =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factimport.CsvRow.getStringByIndex(Int32);
            let a = r1.getStringByIndex(ix);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getStringByIndex: " + Int32.toString(ix))
        }

    ///
    /// Get a string
    /// TODO - does not appear to be working...
    pub def getStringByLabel(row: CsvRow, label: String): CsvResult[String] =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factimport.CsvRow.getStringByLabel(String);
            let a = r1.getStringByLabel(label);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getStringByLabel:" + label)
        }

    pub def getInt8ByIndex(row: CsvRow, ix: Int32): CsvResult[Int8] =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factimport.CsvRow.getByteByIndex(Int32);
            let a = r1.getByteByIndex(ix);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt8ByIndex: " + Int32.toString(ix))
        }

    pub def getInt8ByLabel(row: CsvRow, label: String): CsvResult[Int8] =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factimport.CsvRow.getByteByLabel(String);
            let a = r1.getByteByLabel(label);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt8ByLabel:" + label)
        }

    pub def getInt16ByIndex(row: CsvRow, ix: Int32): CsvResult[Int16] =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factimport.CsvRow.getShortByIndex(Int32);
            let a = r1.getShortByIndex(ix);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt16ByIndex: " + Int32.toString(ix))
        }

    pub def getInt16ByLabel(row: CsvRow, label: String): CsvResult[Int16] =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factimport.CsvRow.getShortByLabel(String);
            let a = r1.getShortByLabel(label);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt16ByLabel: " + label)
        }

    pub def getInt32ByIndex(row: CsvRow, ix: Int32): CsvResult[Int32] =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factimport.CsvRow.getIntByIndex(Int32);
            let a = r1.getIntByIndex(ix);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt32ByIndex: " + Int32.toString(ix))
        }

    pub def getInt32ByLabel(row: CsvRow, label: String): CsvResult[Int32] =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factimport.CsvRow.getIntByLabel(String);
            let a = r1.getIntByLabel(label);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt32ByLabel: " + label)
        }

    pub def getInt64ByIndex(row: CsvRow, ix: Int32): CsvResult[Int64] =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factimport.CsvRow.getLongByIndex(Int32);
            let a = r1.getLongByIndex(ix);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt64ByIndex: " + Int32.toString(ix))
        }

    pub def getInt64ByLabel(row: CsvRow, label: String): CsvResult[Int64] =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factimport.CsvRow.getLongByLabel(String);
            let a = r1.getLongByLabel(label);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getInt64ByLabel: " + label)
        }

    pub def getFloat32ByIndex(row: CsvRow, ix: Int32): CsvResult[Float32] =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factimport.CsvRow.getFloatByIndex(Int32);
            let a = r1.getFloatByIndex(ix);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getFloat32ByIndex: " + Int32.toString(ix))
        }

    pub def getFloat32ByLabel(row: CsvRow, label: String): CsvResult[Float32] =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factimport.CsvRow.getFloatByLabel(String);
            let a = r1.getFloatByLabel(label);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getFloat32ByLabel: " + label)
        }

    pub def getFloat64ByIndex(row: CsvRow, ix: Int32): CsvResult[Float64] =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factimport.CsvRow.getDoubleByIndex(Int32);
            let a = r1.getDoubleByIndex(ix);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getFloat64ByIndex: " + Int32.toString(ix))
        }

    pub def getFloat64ByLabel(row: CsvRow, label: String): CsvResult[Float64] =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factimport.CsvRow.getDoubleByLabel(String);
            let a = r1.getDoubleByLabel(label);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getFloat64ByLabel: " + label)
        }

    pub def getBigIntByIndex(row: CsvRow, ix: Int32): CsvResult[BigInt] =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factimport.CsvRow.getBigIntegerByIndex(Int32);
            let a = r1.getBigIntegerByIndex(ix);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getBigIntByIndex: " + Int32.toString(ix))
        }

    pub def getBigIntByLabel(row: CsvRow, label: String): CsvResult[BigInt] =
        let CsvRow(r1) = row;
        try {
            import flix.runtime.factimport.CsvRow.getBigIntegerByLabel(String);
            let a = r1.getBigIntegerByLabel(label);
            Validation.valid(a)
        } catch {
            case _: ##java.lang.Exception => Validation.error("getBigIntByLabel: " + label)
        }
}