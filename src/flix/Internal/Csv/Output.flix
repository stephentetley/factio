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

use System.Error.{Generic};
use Text.Charset.{Charset};

use FactIO/Internal/Csv.Output;
use FactIO/Internal/Csv.Output.{Output};

namespace FactIO/Internal/Csv {

    pub opaque type Output = ##flix.runtime.spt.factio.csv.CsvOutput
}

namespace FactIO/Internal/Csv/Output {

    ///
    /// Returns a new Output handle.
    ///
    pub def new(path: String, format: ##org.apache.commons.csv.CSVFormat, cellcount: Int32, cs: Text.Charset): Result[Output, System.Error] & Impure =
        import new flix.runtime.spt.factio.csv.CsvOutput(String, ##org.apache.commons.csv.CSVFormat, Int32, ##java.nio.charset.Charset) as newCsvOutput;
        use Result.flatMap;
        try {
            let Charset(cs1) = cs;
            let ans = Output(newCsvOutput(path, format, cellcount, cs1));
            Ok(ans)
        } catch {
            case _: ##java.lang.Exception => Err(Generic("new Csv.Output"))
        }

    ///
    /// Close the CSv output stream.
    ///
    pub def close(x: Output): Result[Unit, System.Error] & Impure =
        import flix.runtime.spt.factio.csv.CsvOutput.close();
        try {
            let Output(x1) = x;
            x1.close();
            Ok()
        } catch {
            case _: ##java.lang.Exception => Err(Generic("Output.close"))
        }



    pub def setCell!(x: Output, ix: Int32, value: String): Result[Unit, System.Error] & Impure =
        import flix.runtime.spt.factio.csv.CsvOutput.setCell(Int32, String);
        try {
            let Output(x1) = x;
            let ans = x1.setCell(ix, value);
            Ok(ans)
        } catch {
            case _: ##java.lang.Exception => Err(Generic("Output.setCell"))
        }

    pub def writeRow(x: Output): Result[Unit, System.Error] & Impure =
        import flix.runtime.spt.factio.csv.CsvOutput.writeRow();
        try {
            let Output(x1) = x;
            let ans = x1.writeRow();
            Ok(ans)
        } catch {
            case _: ##java.lang.Exception => Err(Generic("Output.writeRow"))
        }

    pub def clearCells!(x: Output): Result[Unit, System.Error] & Impure =
        import flix.runtime.spt.factio.csv.CsvOutput.clearCells();
        try {
            let Output(x1) = x;
            let ans = x1.clearCells();
            Ok(ans)
        } catch {
            case _: ##java.lang.Exception => Err(Generic("Output.clearCells"))
        }

}