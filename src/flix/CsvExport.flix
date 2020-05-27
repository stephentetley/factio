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

use System.Error.{IOException, Generic};
use Text.Charset.{Charset};


use FactIO.CsvWriter;
use FactIO.CsvWriter.{CsvWriter};
use FactIO.CsvBuilder;

namespace FactIO {

    ///
    /// Represents a CsvWriter.
    ///
    pub opaque type CsvWriter = ##flix.runtime.spt.factio.CsvWriter

    type alias CsvBuilder = List[CsvWriter -> Unit & Impure]

}

namespace FactIO/CsvExport {

    type alias MarshalRow = ##flix.runtime.spt.factio.marshal.MarshalRow

    ///
    /// Returns a new CsvWriter.
    ///
    pub def new(filename: String, cs: Text.Charset, headers: Array[String]): Result[CsvWriter, System.Error] & Impure =
        import new flix.runtime.spt.factio.CsvWriter(String, ##java.nio.charset.Charset) as newCsvWriter;
        use Result.flatMap;
        try {
            let Charset(cs1) = cs;
            let w1 = CsvWriter(newCsvWriter(filename, cs1));
            let* _ = w1.writeRow(headers);
            Ok(w1)
        } catch {
            case _: ##java.lang.Exception => Err(Generic("new CsvWriter"))
        }

    def serializeRow(cells: Array[String]): MarshalRow & Impure =
        import new flix.runtime.spt.factio.marshal.MarshalRow() as newMarshalRow;
        import flix.runtime.spt.factio.marshal.MarshalRow.append(String);
        let r = newMarshalRow();
        Array.foreach(x -> r.append(x), cells);
        r


    /// Note - row must not be empty.
    pub def writeRow(w: CsvWriter, row: Array[String]): Result[Unit, System.Error] & Impure =
        import flix.runtime.spt.factio.CsvWriter.writeRow(##flix.runtime.spt.factio.marshal.MarshalRow);
        try {
            let CsvWriter(w1) = w;
            let mrow = serializeRow(row);
            w1.writeRow(mrow);
            Ok()
        } catch {
            case _: ##java.io.IOException => Err(IOException)
            case _: ##java.lang.Exception => Err(Generic("Exception"))
        }

    pub def close(w: CsvWriter): Unit & Impure =
        import flix.runtime.spt.factio.CsvWriter.close();
        let CsvWriter(w1) = w;
        w1.close()

    pub def emptyCsvBuilder(): CsvBuilder = Nil

    pub def makeBuildStep(f: x -> Array[String] & e): (x,CsvBuilder) -> CsvBuilder =
        (x, ws) ->
            let w1 = { w ->  let cells = f(x) as & Impure; writeRow(w, cells); () };
            w1 :: ws


    pub def outputCsv(filepath: String, cs: Text.Charset, headers: Array[String], builder: CsvBuilder): Result[Unit, System.Error] & Impure =
        use Result.flatMap;
        let* w = new(filepath, cs, headers);
        List.foreach(f -> f(w),  builder);
        close(w);
        Ok()

 }