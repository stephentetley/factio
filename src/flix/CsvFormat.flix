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

namespace FactIO {

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


}

namespace FactIO/CsvFormat {


    pub def toInt32(format: CsvFormat): Int32 = match format {
        case CsvFormat.Default => 0
        case CsvFormat.Excel => 1
        case CsvFormat.InformixUnload => 2
        case CsvFormat.InformixUnloadCsv => 3
        case CsvFormat.MongodbCsv => 4
        case CsvFormat.MongodbTsv => 5
        case CsvFormat.Mysql => 6
        case CsvFormat.Rfc4180 => 7
        case CsvFormat.Oracle => 8
        case CsvFormat.PostgresqlCsv => 9
        case CsvFormat.PostgresqlText => 10
        case CsvFormat.Tdf => 11
    }

}