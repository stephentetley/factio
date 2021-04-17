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

    pub opaque type OutputHandle = ##flix.runtime.spt.factio.csv.CsvOutput
}

namespace FactIO/Internal/Csv/OutputHandle {

    use Text.Charset.{Charset};

    use FactIO/Internal/Csv.OutputHandle;
    use FactIO/Internal/Csv.OutputHandle.{OutputHandle};

    ///
    /// Returns a new Output handle.
    ///
    pub def new(format: ##org.apache.commons.csv.CSVFormat, columnCount: Int32, cs: Text.Charset, path: System.FilePath): Option[OutputHandle] & Impure =
        import new flix.runtime.spt.factio.csv.CsvOutput(String, ##org.apache.commons.csv.CSVFormat, Int32, ##java.nio.charset.Charset) as newCsvOutput;
        use Result.flatMap;
        try {
            let Charset(cs1) = cs;
            let ans = OutputHandle(newCsvOutput(ToString.toString(path), format, columnCount, cs1));
            Some(ans)
        } catch {
            case _: ##java.lang.Exception => None
        }

    ///
    /// Close the CSV output stream.
    ///
    pub def close!(x: OutputHandle): Option[Unit] & Impure =
        import flix.runtime.spt.factio.csv.CsvOutput.close();
        try {
            let OutputHandle(x1) = x;
            close(x1);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }


    pub def clearCells!(x: OutputHandle): Option[Unit] & Impure =
        import flix.runtime.spt.factio.csv.CsvOutput.clearCells();
        try {
            let OutputHandle(x1) = x;
            let _ = clearCells(x1);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def setCellString!(x: OutputHandle, ix: Int32, value: String): Option[Unit] & Impure =
        import flix.runtime.spt.factio.csv.CsvOutput.setCellString(Int32, String);
        try {
            let OutputHandle(x1) = x;
            let _ = setCellString(x1, ix, value);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def writeRow!(x: OutputHandle): Option[Unit] & Impure =
        import flix.runtime.spt.factio.csv.CsvOutput.writeRow();
        try {
            let OutputHandle(x1) = x;
            let _ = writeRow(x1);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

}
