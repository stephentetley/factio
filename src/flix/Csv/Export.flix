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

use Data/Transient.DList;
use System.Error.{IOException, Generic};
use Text.Charset.{Charset};


use FactIO/Csv.CsvWriter;
use FactIO/Csv.CsvWriter.{CsvWriter};
use FactIO/Csv.CsvWriteList;
use FactIO/Csv.CsvWriteList.{CsvWriteList};

namespace FactIO/Csv {

    ///
    /// Represents a CsvWriter.
    ///
    pub opaque type CsvWriter = ##flix.runtime.spt.factio.csv.CsvWriter


    /// CsvWriteList is a workaround because fixpoint fold is our only way of
    /// extracting data from a relation and the step function of fixpoint fold
    /// must be pure - solution we build a list of impure "write" functions
    /// to be invoked after the fold.
    pub opaque type CsvWriteList = DList[CsvWriter -> Unit & Impure]

}

namespace FactIO/Csv/Export {

    type alias MarshalRow = ##flix.runtime.spt.factio.csv.marshal.MarshalRow

    ///
    /// Returns a new CsvWriter.
    ///
    pub def new(filename: String, cs: Text.Charset, headers: Array[String]): Result[CsvWriter, System.Error] & Impure =
        import new flix.runtime.spt.factio.csv.CsvWriter(String, ##java.nio.charset.Charset) as newCsvWriter;
        use Result.flatMap;
        try {
            let Charset(cs1) = cs;
            let w1 = CsvWriter(newCsvWriter(filename, cs1));
            let* _ = w1.writeRow(headers);
            Ok(w1)
        } catch {
            case _: ##java.lang.Exception => Err(Generic("new Csv.Writer"))
        }

    def serializeRow(cells: Array[String]): MarshalRow & Impure =
        import new flix.runtime.spt.factio.csv.marshal.MarshalRow() as newMarshalRow;
        import flix.runtime.spt.factio.csv.marshal.MarshalRow.append(String);
        let r = newMarshalRow();
        Array.foreach(x -> r.append(x), cells);
        r


    /// Note - row must not be empty.
    pub def writeRow(w: CsvWriter, row: Array[String]): Result[Unit, System.Error] & Impure =
        import flix.runtime.spt.factio.csv.CsvWriter.writeRow(##flix.runtime.spt.factio.csv.marshal.MarshalRow);
        try {
            let CsvWriter(w1) = w;
            let mrow = serializeRow(row);
            w1.writeRow(mrow);
            Ok()
        } catch {
            case _: ##java.io.IOException => Err(IOException)
            case _: ##java.lang.Exception => Err(Generic("Exception"))
        }

    pub def close(w: CsvWriter): Result[Unit, System.Error] & Impure =
        import flix.runtime.spt.factio.csv.CsvWriter.close();
        try {
            let CsvWriter(w1) = w;
            w1.close();
            Ok()
        } catch {
            case _: ##java.io.IOException => Err(IOException)
            case _: ##java.lang.Exception => Err(Generic("Exception"))
        }

    pub def emptyCsvWriteList(): CsvWriteList =
        use Data/Transient/DList.{empty};
        CsvWriteList(empty())

    pub def makeCsvWriteStep(f: x -> Array[String] & e): (x, CsvWriteList) -> CsvWriteList =
        (x, ws) ->
            let CsvWriteList(ws1) = ws;
            let w1 = { w ->  let cells = f(x) as & Impure; writeRow(w, cells); () };
            CsvWriteList(Data/Transient/DList.snoc(ws1, w1))

    pub def outputCsv(filepath: String, cs: Text.Charset, headers: Array[String], writeList: CsvWriteList): Result[Unit, System.Error] & Impure =
        use Result.flatMap;
        let* w = new(filepath, cs, headers);
        let CsvWriteList(ws1) = writeList;
        let xs = Data/Transient/DList.toList(ws1);
        List.foreach(f -> f(w),  xs);
        close(w);
        Ok()

 }