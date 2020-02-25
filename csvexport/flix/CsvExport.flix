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
/// Represents a StringBuilder.
///
opaque type CsvWriter = ##flix.runtime.csvexport.CsvExport


namespace CsvExport {

    ///
    /// Returns a new FilePath.
    ///
    def getDelim(): String = 
        import flix.runtime.csvexport.CsvExport:getDelim();
        getDelim()

    pub def showDelim(): Unit = 
        getDelim() |> Console.printLine 

    def internalNew (filepath: String, format: Int32, headerdata: String): CsvWriter =
        import new flix.runtime.csvexport.CsvExport(String, Int32, String) as newCsvExport;
        CsvWriter(newCsvExport(filepath, format, headerdata))

    def serializeRow(cells: Array[String]): String =
        let sep = getDelim();
        ExportBase.mkStringBy(x -> x, sep, cells)

    pub def new (filepath: String, headers: Array[String]): CsvWriter =
        internalNew(filepath, 0, serializeRow(headers))

    pub def writeRow(w: CsvWriter, cells: Array[String]): Unit =
        let CsvWriter(handle) = w;
        let rowdata = serializeRow(cells);
        import flix.runtime.csvexport.CsvExport.writeRow(String);
        handle.writeRow(rowdata)

    pub def close(w: CsvWriter): Unit =
        let CsvWriter(handle) = w;
        import flix.runtime.csvexport.CsvExport.close();
        handle.close()

    ///
    /// Wrap a "cell printer" i.e. a function from the tuple of a relations fields
    /// to the step function of a fixpoint fold, the fold should be seeded
    /// with a CsvWriter.
    ///
    /// When all the relations have been folded over the fold emits the CsvWriter
    /// so client code can close it.
    ///
    pub def wrapCellPrinterForFixpointFold(f: x -> Array[String]): (x, CsvWriter) -> CsvWriter =
        (x, w) -> { let cells = f(x); writeRow(w, cells); w }

 }