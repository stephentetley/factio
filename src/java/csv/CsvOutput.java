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

package flix.runtime.spt.factio.csv;

import org.apache.commons.csv.*;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.nio.charset.Charset;
import java.util.Arrays;


public class CsvOutput {

    /// This is a nested writer "handle".
    /// There are two levels - at the `row` we set individual cells;
    /// at the `printer` level we write a row to the output stream.
    /// The handle `outw` is at class level so we can close it manually.
    /// The decision not to move a row represented as Array[String] from
    /// Flix to Java was due to a runtime errors in the (automatic)
    /// marshalling which might not still be present.
    private final Writer outw;
    private final CSVPrinter printer;
    private final String[] row;

    public CsvOutput(String filename, CSVFormat format, int columnCount, Charset cs) throws Exception {
        outw = new OutputStreamWriter(new FileOutputStream(filename), cs);
        printer = format.print(outw);
        row = new String[columnCount];
        return;
    }

    public void setCellString(int ix, String value) {
        row[ix] = value;
    }

    public void writeRow() throws Exception {
        Iterable<String> cells = Arrays.asList(row);
        printer.printRecord(cells);
    }

    public void clearCells() throws Exception {
        Arrays.fill(row, "");
    }

    public void close() throws Exception {
        outw.close();
    }
}
