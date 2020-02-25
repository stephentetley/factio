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

package flix.runtime.csvexport;

import org.apache.commons.csv.*;
import java.io.Writer;
import java.io.FileWriter;
import java.util.Arrays;

public class CsvExport {

    Writer outw;
    CSVPrinter printer;

    public static String getDelim() {
        return "\u22B6\u22B7";
    }

    public CsvExport(String filepath, int format, String headerdata) throws Exception {
        outw = new FileWriter(filepath);

        String[] headersArray = headerdata.split(getDelim());
        switch (format) {
            case 1:
                printer = CSVFormat.EXCEL.withHeader(headersArray).print(outw);
                break;
            case 2:
                printer = CSVFormat.INFORMIX_UNLOAD.withHeader(headersArray).print(outw);
                break;
            case 3:
                printer = CSVFormat.INFORMIX_UNLOAD_CSV.withHeader(headersArray).print(outw);
                break;
            case 4:
                printer = CSVFormat.MONGODB_CSV.withHeader(headersArray).print(outw);
                break;
            case 5:
                printer = CSVFormat.MONGODB_TSV.withHeader(headersArray).print(outw);
                break;
            case 6:
                printer = CSVFormat.MYSQL.withHeader(headersArray).print(outw);
                break;
            case 7:
                printer = CSVFormat.RFC4180.withHeader(headersArray).print(outw);
                break;
            case 8:
                printer = CSVFormat.ORACLE.withHeader(headersArray).print(outw);
                break;
            case 9:
                printer = CSVFormat.POSTGRESQL_CSV.withHeader(headersArray).print(outw);
                break;
            case 10:
                printer = CSVFormat.POSTGRESQL_CSV.withHeader(headersArray).print(outw);
                break;
            case 11:
                printer = CSVFormat.POSTGRESQL_TEXT.withHeader(headersArray).print(outw);
                break;
            case 12:
                printer = CSVFormat.TDF.withHeader(headersArray).print(outw);
                break;
            default:
                printer = CSVFormat.DEFAULT.withHeader(headersArray).print(outw);
                break;
        }
        return;
    }

    public void writeRow(String rowdata) throws Exception {
        String[] cells = rowdata.split(getDelim());
        Iterable<String> row = Arrays.asList(cells);

        printer.printRecord(row);
    }

    public void close() throws Exception {
        outw.close();
    }
}
