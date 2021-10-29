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

use FactIO.CsvFormat;
use FactIO.CsvFormat.{CsvFormat};

namespace FactIO {

    ///
    /// Represents a CSVFormat.
    ///
    pub opaque type CsvFormat = ##org.apache.commons.csv.CSVFormat

}


namespace FactIO/CsvFormat {


    pub enum QuoteMode {
        case All,
        case AllNonNull,
        case Minimal,
        case NonNumeric,
        case NoQuote
    }

    pub def default(): CsvFormat =
        import get org.apache.commons.csv.CSVFormat:DEFAULT as get_DEFAULT;
        CsvFormat(get_DEFAULT()) as & Pure

    pub def excel(): CsvFormat =
        import get org.apache.commons.csv.CSVFormat:EXCEL as get_EXCEL;
        CsvFormat(get_EXCEL()) as & Pure

    pub def informix_unload(): CsvFormat =
        import get org.apache.commons.csv.CSVFormat:INFORMIX_UNLOAD as get_INFORMIX_UNLOAD;
        CsvFormat(get_INFORMIX_UNLOAD()) as & Pure

    pub def informix_unload_csv(): CsvFormat =
        import get org.apache.commons.csv.CSVFormat:INFORMIX_UNLOAD_CSV as get_INFORMIX_UNLOAD_CSV;
        CsvFormat(get_INFORMIX_UNLOAD_CSV()) as & Pure

    pub def mongodb_csv(): CsvFormat =
        import get org.apache.commons.csv.CSVFormat:MONGODB_CSV as get_MONGODB_CSV;
        CsvFormat(get_MONGODB_CSV()) as & Pure

    pub def mongodb_tsv(): CsvFormat =
        import get org.apache.commons.csv.CSVFormat:MONGODB_TSV as get_MONGODB_TSV;
        CsvFormat(get_MONGODB_TSV()) as & Pure

    pub def mysql(): CsvFormat =
        import get org.apache.commons.csv.CSVFormat:MYSQL as get_MYSQL;
        CsvFormat(get_MYSQL()) as & Pure

    pub def oracle(): CsvFormat =
        import get org.apache.commons.csv.CSVFormat:ORACLE as get_ORACLE;
        CsvFormat(get_ORACLE()) as & Pure

    pub def postgresql_csv(): CsvFormat =
        import get org.apache.commons.csv.CSVFormat:POSTGRESQL_CSV as get_POSTGRESQL_CSV;
        CsvFormat(get_POSTGRESQL_CSV()) as & Pure

    pub def postgresql_text(): CsvFormat =
        import get org.apache.commons.csv.CSVFormat:POSTGRESQL_TEXT as get_POSTGRESQL_TEXT;
        CsvFormat(get_POSTGRESQL_TEXT()) as & Pure

    pub def rfc4180(): CsvFormat =
        import get org.apache.commons.csv.CSVFormat:RFC4180 as get_RFC4180;
        CsvFormat(get_RFC4180()) as & Pure

    pub def tdf(): CsvFormat =
        import get org.apache.commons.csv.CSVFormat:TDF as get_TDF;
        CsvFormat(get_TDF()) as & Pure


    pub def toString(x: CsvFormat): String =
        import org.apache.commons.csv.CSVFormat.toString();
        let CsvFormat(x1) = x;
        x1.toString() as & Pure

    pub def getAllowMissingColumnNames(x: CsvFormat): Bool =
        import org.apache.commons.csv.CSVFormat.getAllowMissingColumnNames();
        let CsvFormat(x1) = x;
        getAllowMissingColumnNames(x1) as & Pure

    pub def putAllowMissingColumnNames(x: CsvFormat, allow: Bool): CsvFormat =
        import org.apache.commons.csv.CSVFormat.withAllowMissingColumnNames(Bool);
        let CsvFormat(x1) = x;
        CsvFormat(withAllowMissingColumnNames(x1, allow)) as & Pure

    pub def getDelimiter(x: CsvFormat): Char =
        import org.apache.commons.csv.CSVFormat.getDelimiter();
        let CsvFormat(x1) = x;
        getDelimiter(x1) as & Pure

    pub def putDelimiter(x: CsvFormat, delimiter: Char): CsvFormat =
        import org.apache.commons.csv.CSVFormat.withDelimiter(Char);
        let CsvFormat(x1) = x;
        CsvFormat(withDelimiter(x1, delimiter)) as & Pure

    pub def getEscapeChar(x: CsvFormat): Char =
        import org.apache.commons.csv.CSVFormat.getEscapeCharacter();
        import java.lang.Character.charValue();
        let CsvFormat(x1) = x;
        (getEscapeCharacter(x1) |> charValue) as & Pure

    pub def putEscapeChar(x: CsvFormat, escape: Char): CsvFormat =
        import org.apache.commons.csv.CSVFormat.withEscape(Char);
        let CsvFormat(x1) = x;
        CsvFormat(withEscape(x1, escape)) as & Pure


    pub def getIgnoreEmptyLines(x: CsvFormat): Bool =
        import org.apache.commons.csv.CSVFormat.getIgnoreEmptyLines();
        let CsvFormat(x1) = x;
        getIgnoreEmptyLines(x1) as & Pure

    pub def putIgnoreEmptyLines(x: CsvFormat, ignore: Bool): CsvFormat =
        import org.apache.commons.csv.CSVFormat.withIgnoreEmptyLines(Bool);
        let CsvFormat(x1) = x;
        CsvFormat(withIgnoreEmptyLines(x1, ignore)) as & Pure


    pub def getQuoteChar(x: CsvFormat): Char =
        import org.apache.commons.csv.CSVFormat.getQuoteCharacter();
        import java.lang.Character.charValue();
        let CsvFormat(x1) = x;
        (getQuoteCharacter(x1) |> charValue) as & Pure

    pub def putQuoteChar(x: CsvFormat, quote: Char): CsvFormat =
        import org.apache.commons.csv.CSVFormat.withQuote(Char);
        let CsvFormat(x1) = x;
        CsvFormat(withQuote(x1, quote)) as & Pure

    pub def getSkipHeaderRecord(x: CsvFormat): Bool =
        import org.apache.commons.csv.CSVFormat.getSkipHeaderRecord();
        let CsvFormat(x1) = x;
        getSkipHeaderRecord(x1) as & Pure

    pub def putSkipHeaderRecord(x: CsvFormat, skip: Bool): CsvFormat =
        import org.apache.commons.csv.CSVFormat.withSkipHeaderRecord(Bool);
        let CsvFormat(x1) = x;
        CsvFormat(withSkipHeaderRecord(x1, skip)) as & Pure

    pub def getTrim(x: CsvFormat): Bool =
        import org.apache.commons.csv.CSVFormat.getTrim();
        let CsvFormat(x1) = x;
        getTrim(x1) as & Pure

    pub def putTrim(x: CsvFormat, trim: Bool): CsvFormat =
        import org.apache.commons.csv.CSVFormat.withTrim(Bool);
        let CsvFormat(x1) = x;
        CsvFormat(withTrim(x1, trim)) as & Pure

    pub def withFirstRecordAsHeader(x: CsvFormat): CsvFormat =
        import org.apache.commons.csv.CSVFormat.withFirstRecordAsHeader();
        let CsvFormat(x1) = x;
        CsvFormat(withFirstRecordAsHeader(x1)) as & Pure

}