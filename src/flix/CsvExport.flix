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
opaque type CsvWriter = ##flix.runtime.factio.CsvExport

type alias CsvBuilder = List[CsvWriter -> Unit & Impure]

namespace CsvExport {


    def getDelim(): String = 
        import flix.runtime.factio.CsvExport:getDelim();
        getDelim() as & Pure


    def internalNew (filepath: String, format: Int32, headerdata: String): CsvWriter & Impure =
        import new flix.runtime.factio.CsvExport(String, Int32, String) as newCsvExport;
        CsvWriter(newCsvExport(filepath, format, headerdata))

    ///
    /// Returns a new CsvWriter.
    ///
    pub def new (filepath: String, headers: Array[String]): CsvWriter & Impure =
        internalNew(filepath, 0, serializeRow(headers))

    def serializeRow(cells: Array[String]): String & Impure =
        let sep = getDelim();
        Array.formatWith(x -> x, sep, cells)

    pub def writeRow(w: CsvWriter, cells: Array[String]): Unit & Impure =
        let CsvWriter(handle) = w;
        let rowdata = serializeRow(cells);
        import flix.runtime.factio.CsvExport.writeRow(String);
        handle.writeRow(rowdata)

    pub def close(w: CsvWriter): Unit & Impure =
        let CsvWriter(handle) = w;
        import flix.runtime.factio.CsvExport.close();
        handle.close()


    pub def emptyCsvBuilder(): CsvBuilder = Nil

    pub def makeBuildStep(f: x -> Array[String] & e): (x,CsvBuilder) -> CsvBuilder =
        (x, ws) ->
            let w1 = { w ->  let cells = f(x) as & Impure; writeRow(w, cells) };
            w1 :: ws


    pub def outputCsv(filepath: String, headers: Array[String], builder: CsvBuilder): Unit & Impure =
        let w = new(filepath, headers);
        List.foreach(f -> f(w),  builder);
        close(w)

 }