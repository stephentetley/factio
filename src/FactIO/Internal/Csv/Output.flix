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


namespace FactIO/Internal/Csv {

    pub opaque type Output = ##flixspt.factio.csv.CsvOutput
}

namespace FactIO/Internal/Csv/Output {

    use FlixSandbox/Text.Charset.{Charset};

    use FactIO/Internal/Csv.Output;
    use FactIO/Internal/Csv.Output.{Output};

    ///
    /// Returns a new Output handle.
    ///
    pub def new(path: String, format: ##org.apache.commons.csv.CSVFormat, cellcount: Int32, cs: FlixSandbox/Text.Charset): Option[Output] & Impure =
        import new flixspt.factio.csv.CsvOutput(String, ##org.apache.commons.csv.CSVFormat, Int32, ##java.nio.charset.Charset): ##flixspt.factio.csv.CsvOutput & Impure as newCsvOutput;
        use Result.flatMap;
        try {
            let Charset(cs1) = cs;
            let ans = Output(newCsvOutput(path, format, cellcount, cs1));
            Some(ans)
        } catch {
            case _: ##java.lang.Exception => None
        }

    ///
    /// Close the CSV output stream.
    ///
    pub def close(x: Output): Option[Unit] & Impure =
        import flixspt.factio.csv.CsvOutput.close(): Unit & Impure;
        try {
            let Output(x1) = x;
            close(x1);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def setCell!(x: Output, ix: Int32, value: String): Option[Unit] & Impure =
        import flixspt.factio.csv.CsvOutput.setCell(Int32, String): Unit & Impure;
        try {
            let Output(x1) = x;
            let _ = setCell(x1, ix, value);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def writeRow(x: Output): Option[Unit] & Impure =
        import flixspt.factio.csv.CsvOutput.writeRow(): Unit & Impure;
        try {
            let Output(x1) = x;
            let _ = writeRow(x1);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def clearCells!(x: Output): Option[Unit] & Impure =
        import flixspt.factio.csv.CsvOutput.clearCells(): Unit & Impure;
        try {
            let Output(x1) = x;
            let _ = clearCells(x1);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

}
