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



namespace FactIO/CsvExport {

    use Text.Charset.{Charset};

    use FactIO/Internal/Csv.OutputHandle;
    use FactIO.CsvExport;
    use FactIO.CsvExport.{CsvExport};
    use FactIO.CsvWriteList;
    use FactIO.CsvWriteList.{CsvWriteList};
    use FactIO.CsvFormat;
    use FactIO.CsvFormat.{CsvFormat};

    use FactIO.CsvRowSetter;
    use FactIO.CsvRowSetter.{CsvRowSetter};


    def makeColumnIndices(headers: Array[String]): Map[String, Int32] & Impure =
        Array.foldLeft((ac, s) -> {let (m,i) = ac; (Map.insert(s, i, m), i+1)}, (Map.empty(), 0), headers) |> fst

    pub def exportCsv(format: CsvFormat,
                    cs: Text.Charset,
                    headings: Array[String],
                    rowWriter: a -> CsvRowSetter[Unit],
                    rows: Array[a],
                    outpath: System.FilePath): Result[Unit, String] & Impure =
        use Result.flatMap;
        use FactIO/Internal/Csv/OutputHandle.{new => newOutput, close!};
        let CsvFormat(fmt1) = format;
        let cellcount       = Array.length(headings);
        let headers         = makeColumnIndices(headings);
        let* handle         = Option.toOk(newOutput(fmt1, cellcount, cs, outpath), "runCsvExport failed");
        let* _              = Option.toOk(writeHeadingsLine!(handle, headings), "runCsvExport write headings failed");
        let* _              = writeRows!(headers, handle, rowWriter, rows);
        let _               = close!(handle);
        Ok()




    def writeHeadingsLine!(handle: OutputHandle, arr: Array[String]): Option[Unit] & Impure=
        use Option.{flatMap};
        use FactIO/Internal/Csv/OutputHandle.{clearCells!, writeRow!, setCellString!};
        let* _  = clearCells!(handle);
        let _   = Array.foldLeft((ix, x) -> {setCellString!(handle, ix, x); ix + 1}, 0, arr);
        let* _  = writeRow!(handle);
        Some()

    def writeRows!(hdrs: Map[String, Int32],
                handle: OutputHandle,
                rowWriter: a -> CsvRowSetter[Unit],
                rows: Array[a]): Result[Unit, String] & Impure =
        writeRowsHelper(hdrs, handle, rowWriter, 0, rows)

    def writeRowsHelper(hdrs: Map[String, Int32],
                        handle: OutputHandle,
                        rowWriter: a -> CsvRowSetter[Unit],
                        ix: Int32,
                        rows: Array[a]): Result[Unit, String] & Impure =
        if (ix < Array.length(rows)) {
            let x = rows[ix];
            let setter = rowWriter(x);
            match writeRow(hdrs, handle, setter) {
                case Ok() => writeRowsHelper(hdrs, handle, rowWriter, ix + 1, rows)
                case Err(msg) => Err(msg)
            }
        } else Ok()

    def writeRow(hdrs: Map[String, Int32], handle: OutputHandle, mx: CsvRowSetter[a]): Result[Unit, String] & Impure =
        use Result.{flatMap};
        use FactIO/Internal/Csv/OutputHandle.{clearCells!, writeRow! => primWriteRow!, setCellString!};
        let* _ = Option.toOk(clearCells!(handle), "writeRow! - clearCells!");
        let* _ = execCsvRowSetter(hdrs, handle, mx);
        let* _ = Option.toOk(primWriteRow!(handle), "writeRow! - primWriteRow!");
        Ok()


    def execCsvRowSetter(hdrs: Map[String, Int32], handle: OutputHandle, mx: CsvRowSetter[a]): Result[Unit, String] & Impure =
        let CsvRowSetter(mf) = mx;
        match mf(hdrs, handle) {
            case Ok(_) => Ok()
            case Err(e) => Err(e)
        }



}
