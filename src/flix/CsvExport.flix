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

use FactIO.CsvWriter;
use FactIO.CsvWriter.{CsvWriter};
use FactIO.CsvBuilder;

namespace FactIO {

    ///
    /// Represents a CsvWriter.
    ///
    pub opaque type CsvWriter = ##flix.runtime.factio.CsvWriter

    type alias CsvBuilder = List[CsvWriter -> Unit & Impure]

}

namespace FactIO/CsvExport {

    ///
    /// Returns a new CsvWriter.
    ///
    pub def new(filename: String, headers: Array[String]): Result[CsvWriter, String] & Impure =
        import new flix.runtime.factio.CsvWriter(String) as newCsvWriter;
        try {
            let w1 = CsvWriter(newCsvWriter(filename));
            w1.writeRow(headers);
            Ok(w1)
        } catch {
            case _: ##java.lang.Exception => Err("new CsvWriter")
        }


    pub def writeRow(w: CsvWriter, row: Array[String]): Unit & Impure =
        import flix.runtime.factio.CsvWriter.writeRow(Array[String]);
        let CsvWriter(w1) = w;
        w1.writeRow(row)

    pub def close(w: CsvWriter): Unit & Impure =
        let CsvWriter(w1) = w;
        import flix.runtime.factio.CsvWriter.close();
        w1.close()

    pub def emptyCsvBuilder(): CsvBuilder = Nil

    pub def makeBuildStep(f: x -> Array[String] & e): (x,CsvBuilder) -> CsvBuilder =
        (x, ws) ->
            let w1 = { w ->  let cells = f(x) as & Impure; writeRow(w, cells) };
            w1 :: ws


    pub def outputCsv(filepath: String, headers: Array[String], builder: CsvBuilder): Result[Unit, String] & Impure =
        use Result.flatMap;
        let* w = new(filepath, headers);
        List.foreach(f -> f(w),  builder);
        close(w);
        Ok()

 }