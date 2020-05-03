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

package flix.runtime.factio;


import flix.runtime.factio.marshal.MarshalRow;
import org.apache.commons.csv.*;

import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.io.FileWriter;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;


public class CsvWriter {

    private final Writer outw;
    private final CSVPrinter printer;

    public CsvWriter(String filename, Charset cs) throws Exception {
        outw = new OutputStreamWriter(new FileOutputStream(filename), cs);
        printer = CSVFormat.DEFAULT.print(outw);
    }


    public CsvWriter(String filename, Charset cs, int format) throws Exception {
        outw = new OutputStreamWriter(new FileOutputStream(filename), cs);
        switch (format) {
            case 1:
                printer = CSVFormat.EXCEL.print(outw);
                break;
            case 2:
                printer = CSVFormat.INFORMIX_UNLOAD.print(outw);
                break;
            case 3:
                printer = CSVFormat.INFORMIX_UNLOAD_CSV.print(outw);
                break;
            case 4:
                printer = CSVFormat.MONGODB_CSV.print(outw);
                break;
            case 5:
                printer = CSVFormat.MONGODB_TSV.print(outw);
                break;
            case 6:
                printer = CSVFormat.MYSQL.print(outw);
                break;
            case 7:
                printer = CSVFormat.RFC4180.print(outw);
                break;
            case 8:
                printer = CSVFormat.ORACLE.print(outw);
                break;
            case 9:
                printer = CSVFormat.POSTGRESQL_CSV.print(outw);
                break;
            case 10:
                printer = CSVFormat.POSTGRESQL_CSV.print(outw);
                break;
            case 11:
                printer = CSVFormat.POSTGRESQL_TEXT.print(outw);
                break;
            case 12:
                printer = CSVFormat.TDF.print(outw);
                break;
            default:
                printer = CSVFormat.DEFAULT.print(outw);
                break;
        }
        return;
    }

    public void writeRow(MarshalRow rowdata) throws Exception {
        String[] row = rowdata.toArray();
        Iterable<String> cells = Arrays.asList(row);
        printer.printRecord(cells);
    }

    public void close() throws Exception {
        outw.close();
    }
}
