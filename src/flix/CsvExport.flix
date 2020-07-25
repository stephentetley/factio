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


use FactIO.CsvExport;
use FactIO.CsvExport.{CsvExport};
use FactIO.CsvWriteList;
use FactIO.CsvWriteList.{CsvWriteList};
use FactIO.CsvFormat;
use FactIO.CsvFormat.{CsvFormat};

use FactIO.CsvRowWriter;
use FactIO.CsvRowWriter.{CsvRowWriter};

namespace FactIO {


    pub opaque type CsvExport[a] = (Map[String, Int32], FactIO/Internal/Csv.Output) ~> Result[a, System.Error]

    /// CsvWriteList is a workaround because fixpoint fold is our only way of
    /// extracting data from a relation and the step function of fixpoint fold
    /// must be pure - solution we build a list of impure "write" functions
    /// to be invoked after the fold.
    pub opaque type CsvWriteList = DList[CsvRowWriter[Unit]]

}

namespace FactIO/CsvExport {

    def makeColumnIndices(headers: Array[String]): Map[String, Int32] & Impure =
        Array.foldLeft((ac, s) -> {let (m,i) = ac; (Map.insert(s, i, m), i+1)}, (Map.empty(), 0), headers) |> fst

    pub def runCsvExport(mx: CsvExport[a], path: System.FilePath, format: CsvFormat, headings: Array[String], cs: Text.Charset): Result[a, System.Error] & Impure =
        use Result.flatMap;
        use System/FilePath.{normalize, toString};
        use FactIO/Internal/Csv/Output.{new => newOutput, close};
        let CsvFormat(fmt1) = format;
        let cellcount = Array.length(headings);
        let headers = makeColumnIndices(headings);
        let* handle = newOutput(System/FilePath.toString(path), fmt1, cellcount, cs);
        let* ans = apply1(mx, headers, handle);
        let _ = handle.close();
        Ok(ans)


    pub def return(x: a): CsvExport[a] =
        CsvExport((_,_) -> Ok(x) as & Impure)

    def apply1(x: CsvExport[a], headers: Map[String, Int], r: FactIO/Internal/Csv.Output): Result[a, System.Error] & Impure =
        let CsvExport(f) = x;
        f(headers, r)

    pub def map(f: a -> b & ef, x: CsvExport[a]): CsvExport[b] =
        CsvExport((hdrs, r) ->
            match apply1(x, hdrs, r) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )

    pub def ap(mf: CsvExport[a -> b & ef], ma: CsvExport[a]): CsvExport[b] =
        CsvExport((hdrs, r) ->
            match apply1(mf, hdrs, r) {
                case Ok(f) => {
                    match apply1(ma, hdrs, r) {
                        case Ok(a) => Ok(f(a) as & Impure)
                        case Err(e2) => Err(e2)
                    }
                }
                case Err(e1) => Err(e1)
            }
        )


    pub def bind(x: CsvExport[a], k: a -> CsvExport[b]): CsvExport[b] =
        CsvExport((hdrs, r) ->
            match apply1(x, hdrs, r) {
                case Ok(a) => { let ans = k(a); apply1(ans, hdrs, r) }
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> CsvExport[b], x: CsvExport[a]): CsvExport[b] = bind(x, k)

    pub def liftAction(fn: Unit ~> Result[a, System.Error]): CsvExport[a] =
        CsvExport((_,_) -> fn())

    pub def emptyCsvWriteList(): CsvWriteList =
        use Data/Transient/DList.{empty};
        CsvWriteList(empty())

    pub def makeCsvWriteStep(f: x -> CsvRowWriter[Unit]): (x, CsvWriteList) -> CsvWriteList =
        (x, ws) ->
            let CsvWriteList(ws1) = ws;
            let w1 = f(x);
            CsvWriteList(Data/Transient/DList.snoc(ws1, w1))

    pub def execWriteList(xs: CsvWriteList): CsvExport[Unit] =
        let CsvWriteList(xs1) = xs;
        let writes = Data/Transient/DList.toList(xs1);
        execWriteListHelper(writes)

    def execWriteListHelper(xs: List[CsvRowWriter[Unit]]): CsvExport[Unit] = match xs {
        case Nil => return()
        case mx :: rs => {
            let* _ = execWriteList1(mx);
            execWriteListHelper(rs)
        }
    }

    def execWriteList1(mx: CsvRowWriter[a]): CsvExport[Unit] =
        let* _ = clearCells!();
        let* _ = applyCsvRowWriter(mx);
        let* _ = writeRow();
        return()

    def clearCells!(): CsvExport[Unit] =
        CsvExport((_, r) -> FactIO/Internal/Csv/Output.clearCells!(r))

    def writeRow(): CsvExport[Unit] =
        CsvExport((_, r) -> FactIO/Internal/Csv/Output.writeRow(r))

    def applyCsvRowWriter(mx: CsvRowWriter[a]): CsvExport[Unit] =
        CsvExport((hdrs, r) ->
            let CsvRowWriter(mf) = mx;
            match mf(hdrs, r) {
                case Ok(_) => Ok()
                case Err(e) => Err(e)
            }
        )


}