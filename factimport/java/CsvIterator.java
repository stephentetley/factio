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

package flix.runtime.factimport;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVRecord;

import java.io.FileReader;
import java.util.Iterator;

public class CsvIterator {

    private Iterator<CSVRecord> rator;

    // 0 DEFAULT
    // 1 EXCEL
    // 2 INFORMIX_UNLOAD
    // 3 INFORMIX_UNLOAD_CSV
    // 4 MONGODB_CSV
    // 5 MONGODB_TSV
    // 6 MYSQL
    // 7 RFC4180
    // 8 ORACLE
    // 9 POSTGRESQL_CSV
    // 10 POSTGRESQL_TEXT
    // 11 TDF
    private CSVFormat selectFormat(int fmt) {
        switch (fmt) {
            case 1:
                return CSVFormat.EXCEL;
            case 2:
                return CSVFormat.INFORMIX_UNLOAD;
            case 3:
                return CSVFormat.INFORMIX_UNLOAD_CSV;
            case 4:
                return CSVFormat.MONGODB_CSV;
            case 5:
                return CSVFormat.MONGODB_TSV;
            case 6:
                return CSVFormat.MYSQL;
            case 7:
                return CSVFormat.RFC4180;
            case 8:
                return CSVFormat.ORACLE;
            case 9:
                return CSVFormat.POSTGRESQL_CSV;
            case 10:
                return CSVFormat.POSTGRESQL_CSV;
            case 11:
                return CSVFormat.POSTGRESQL_TEXT;
            case 12:
                return CSVFormat.TDF;
            default:
                return CSVFormat.DEFAULT;
        }
    }

    /// TODO - more options than hasHeasers...
    public CsvIterator(String filepath, int format, boolean hasHeaders) throws Exception {
        FileReader in = new FileReader(filepath);
        Iterable<CSVRecord> rable = null;
        CSVFormat csvformat = selectFormat(format);
        if (hasHeaders) {
            rable = csvformat.withFirstRecordAsHeader().parse(in);
        } else {
            rable = csvformat.parse(in);
        }
        rator = rable.iterator();
    }

    public boolean hasNext() {
        return rator.hasNext();
    }

    public CsvRow next() {
        CsvRow row = new CsvRow(rator.next());
        return row;
    }
}
