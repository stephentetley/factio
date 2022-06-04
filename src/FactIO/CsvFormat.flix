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



namespace FactIO {

    ///
    /// Represents a CSVFormat.
    ///
    pub enum CsvFormat(##org.apache.commons.csv.CSVFormat)

    instance ToString[CsvFormat] {
        pub def toString(x: CsvFormat): String = FactIO/CsvFormat.toString(x)
    }

}


namespace FactIO/CsvFormat {

    use FactIO.CsvFormat;
    use FactIO.CsvFormat.{CsvFormat};
    
    pub enum QuoteMode {
        case All,
        case AllNonNull,
        case Minimal,
        case NonNumeric,
        case NoQuote
    }

    pub def default(): CsvFormat =
        import static get org.apache.commons.csv.CSVFormat.DEFAULT: ##org.apache.commons.csv.CSVFormat & Pure as get_DEFAULT;
        CsvFormat(get_DEFAULT())

    pub def excel(): CsvFormat =
        import static get org.apache.commons.csv.CSVFormat.EXCEL: ##org.apache.commons.csv.CSVFormat & Pure as get_EXCEL;
        CsvFormat(get_EXCEL())

    pub def informix_unload(): CsvFormat =
        import static get org.apache.commons.csv.CSVFormat.INFORMIX_UNLOAD: ##org.apache.commons.csv.CSVFormat & Pure as get_INFORMIX_UNLOAD;
        CsvFormat(get_INFORMIX_UNLOAD())

    pub def informix_unload_csv(): CsvFormat =
        import static get org.apache.commons.csv.CSVFormat.INFORMIX_UNLOAD_CSV: ##org.apache.commons.csv.CSVFormat & Pure as get_INFORMIX_UNLOAD_CSV;
        CsvFormat(get_INFORMIX_UNLOAD_CSV())

    pub def mongodb_csv(): CsvFormat =
        import static get org.apache.commons.csv.CSVFormat.MONGODB_CSV: ##org.apache.commons.csv.CSVFormat & Pure as get_MONGODB_CSV;
        CsvFormat(get_MONGODB_CSV())

    pub def mongodb_tsv(): CsvFormat =
        import static get org.apache.commons.csv.CSVFormat.MONGODB_TSV: ##org.apache.commons.csv.CSVFormat & Pure as get_MONGODB_TSV;
        CsvFormat(get_MONGODB_TSV())

    pub def mysql(): CsvFormat =
        import static get org.apache.commons.csv.CSVFormat.MYSQL: ##org.apache.commons.csv.CSVFormat & Pure as get_MYSQL;
        CsvFormat(get_MYSQL())

    pub def oracle(): CsvFormat =
        import static get org.apache.commons.csv.CSVFormat.ORACLE: ##org.apache.commons.csv.CSVFormat & Pure as get_ORACLE;
        CsvFormat(get_ORACLE())

    pub def postgresql_csv(): CsvFormat =
        import static get org.apache.commons.csv.CSVFormat.POSTGRESQL_CSV: ##org.apache.commons.csv.CSVFormat & Pure as get_POSTGRESQL_CSV;
        CsvFormat(get_POSTGRESQL_CSV())

    pub def postgresql_text(): CsvFormat =
        import static get org.apache.commons.csv.CSVFormat.POSTGRESQL_TEXT: ##org.apache.commons.csv.CSVFormat & Pure as get_POSTGRESQL_TEXT;
        CsvFormat(get_POSTGRESQL_TEXT())

    pub def rfc4180(): CsvFormat =
        import static get org.apache.commons.csv.CSVFormat.RFC4180: ##org.apache.commons.csv.CSVFormat & Pure as get_RFC4180;
        CsvFormat(get_RFC4180())

    pub def tdf(): CsvFormat =
        import static get org.apache.commons.csv.CSVFormat.TDF: ##org.apache.commons.csv.CSVFormat & Pure as get_TDF;
        CsvFormat(get_TDF())


    pub def toString(x: CsvFormat): String =
        import org.apache.commons.csv.CSVFormat.toString(): String & Pure;
        let CsvFormat(x1) = x;
        toString(x1)

    pub def getAllowMissingColumnNames(x: CsvFormat): Bool =
        import org.apache.commons.csv.CSVFormat.getAllowMissingColumnNames(): Bool & Pure;
        let CsvFormat(x1) = x;
        getAllowMissingColumnNames(x1)

    pub def putAllowMissingColumnNames(x: CsvFormat, allow: Bool): CsvFormat =
        import org.apache.commons.csv.CSVFormat.withAllowMissingColumnNames(Bool): ##org.apache.commons.csv.CSVFormat & Pure;
        let CsvFormat(x1) = x;
        CsvFormat(withAllowMissingColumnNames(x1, allow))

    pub def getDelimiter(x: CsvFormat): Char =
        import org.apache.commons.csv.CSVFormat.getDelimiter(): Char & Pure;
        let CsvFormat(x1) = x;
        getDelimiter(x1)

    pub def putDelimiter(x: CsvFormat, delimiter: Char): CsvFormat =
        import org.apache.commons.csv.CSVFormat.withDelimiter(Char): ##org.apache.commons.csv.CSVFormat & Pure;
        let CsvFormat(x1) = x;
        CsvFormat(withDelimiter(x1, delimiter))

    pub def getEscapeChar(x: CsvFormat): Char =
        import org.apache.commons.csv.CSVFormat.getEscapeCharacter(): ##java.lang.Character & Pure;
        import java.lang.Character.charValue(): Char & Pure;
        let CsvFormat(x1) = x;
        (getEscapeCharacter(x1) |> charValue)

    pub def putEscapeChar(x: CsvFormat, escape: Char): CsvFormat =
        import org.apache.commons.csv.CSVFormat.withEscape(Char): ##org.apache.commons.csv.CSVFormat & Pure;
        let CsvFormat(x1) = x;
        CsvFormat(withEscape(x1, escape))


    pub def getIgnoreEmptyLines(x: CsvFormat): Bool =
        import org.apache.commons.csv.CSVFormat.getIgnoreEmptyLines(): Bool & Pure;
        let CsvFormat(x1) = x;
        getIgnoreEmptyLines(x1)

    pub def putIgnoreEmptyLines(x: CsvFormat, ignore: Bool): CsvFormat =
        import org.apache.commons.csv.CSVFormat.withIgnoreEmptyLines(Bool): ##org.apache.commons.csv.CSVFormat & Pure;
        let CsvFormat(x1) = x;
        CsvFormat(withIgnoreEmptyLines(x1, ignore))


    pub def getQuoteChar(x: CsvFormat): Char =
        import org.apache.commons.csv.CSVFormat.getQuoteCharacter(): ##java.lang.Character & Pure;
        import java.lang.Character.charValue(): Char & Pure;
        let CsvFormat(x1) = x;
        (getQuoteCharacter(x1) |> charValue)

    pub def putQuoteChar(x: CsvFormat, quote: Char): CsvFormat =
        import org.apache.commons.csv.CSVFormat.withQuote(Char): ##org.apache.commons.csv.CSVFormat & Pure;
        let CsvFormat(x1) = x;
        CsvFormat(withQuote(x1, quote))

    pub def getSkipHeaderRecord(x: CsvFormat): Bool =
        import org.apache.commons.csv.CSVFormat.getSkipHeaderRecord(): Bool & Pure;
        let CsvFormat(x1) = x;
        getSkipHeaderRecord(x1)

    pub def putSkipHeaderRecord(x: CsvFormat, skip: Bool): CsvFormat =
        import org.apache.commons.csv.CSVFormat.withSkipHeaderRecord(Bool): ##org.apache.commons.csv.CSVFormat & Pure;
        let CsvFormat(x1) = x;
        CsvFormat(withSkipHeaderRecord(x1, skip))

    pub def getTrim(x: CsvFormat): Bool =
        import org.apache.commons.csv.CSVFormat.getTrim(): Bool & Pure;
        let CsvFormat(x1) = x;
        getTrim(x1)

    pub def putTrim(x: CsvFormat, trim: Bool): CsvFormat =
        import org.apache.commons.csv.CSVFormat.withTrim(Bool): ##org.apache.commons.csv.CSVFormat & Pure;
        let CsvFormat(x1) = x;
        CsvFormat(withTrim(x1, trim))

    pub def withFirstRecordAsHeader(x: CsvFormat): CsvFormat =
        import org.apache.commons.csv.CSVFormat.withFirstRecordAsHeader(): ##org.apache.commons.csv.CSVFormat & Pure;
        let CsvFormat(x1) = x;
        CsvFormat(withFirstRecordAsHeader(x1))

}