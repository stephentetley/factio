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

use System.Error.{IllegalArgumentException, InputMismatchException};

use FactIO/FlatFile.RowWithHeadersEvaluator;
use FactIO/FlatFile.RowWithHeadersEvaluator.{RowWithHeadersEvaluator};
use FactIO/FlatFile.LineEvaluator;
use FactIO/FlatFile.LineEvaluator.{LineEvaluator};

namespace FactIO/FlatFile {

    pub opaque type RowWithHeadersEvaluator[a] = (Map[String,Int32], Array[String]) ~> Result[a, System.Error]
}

namespace FactIO/FlatFile/RowWithHeadersEvaluator {

    pub def toLineEvaluator(splitter: String ~> Array[String], headers: Map[String, Int32], eval: RowWithHeadersEvaluator[a]): LineEvaluator[a] =
        let RowWithHeadersEvaluator(f) = eval;
        LineEvaluator(s -> let arr = splitter(s); f(headers, arr))

    pub def makeHeaders(names: Array[String]): Map[String,Int32] & Impure =
        let step = (acc, x) -> { let (i, mx) = acc; (i + 1, Map.insert(x, i, mx)) };
        Array.foldLeft(step, (0, Map.empty()), names) |> snd


    pub def return(x: a): RowWithHeadersEvaluator[a] =
        RowWithHeadersEvaluator((_,_) -> Ok(x) as & Impure)

    def apply1(x: RowWithHeadersEvaluator[a], indices: Map[String, Int32], row: Array[String]): Result[a, System.Error] & Impure =
        let RowWithHeadersEvaluator(f) = x;
        f(indices, row)

    pub def map(f: a -> b & e, x: RowWithHeadersEvaluator[a]): RowWithHeadersEvaluator[b] =
        RowWithHeadersEvaluator((ixs, row) ->
            match apply1(x, ixs, row) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )        

    pub def ap(mf: RowWithHeadersEvaluator[a -> b], ma: RowWithHeadersEvaluator[a]): RowWithHeadersEvaluator[b] =
        RowWithHeadersEvaluator((ixs, row) ->
            match apply1(mf, ixs, row) {
                case Ok(f) => { 
                    match apply1(ma, ixs, row) {
                        case Ok(a) => Ok(f(a))
                        case Err(e2) => Err(e2)
                    }
                }
                case Err(e1) => Err(e1)
            }
        )

    pub def bind(x: RowWithHeadersEvaluator[a], k: a -> RowWithHeadersEvaluator[b]): RowWithHeadersEvaluator[b] =
        RowWithHeadersEvaluator((ixs, row) ->
            match apply1(x, ixs, row) { 
                case Ok(a) => apply1(k(a), ixs, row)
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> RowWithHeadersEvaluator[b], x: RowWithHeadersEvaluator[a]): RowWithHeadersEvaluator[b] = bind(x, k)

    def liftResult(x: Result[a, System.Error]): RowWithHeadersEvaluator[a] =
        RowWithHeadersEvaluator((_,_) -> x as & Impure)

    def liftAction(fn: Unit ~> Result[a, System.Error] ): RowWithHeadersEvaluator[a] =
        RowWithHeadersEvaluator((_,_) -> fn())

     // Cell readers, by label only

    pub def getString(label: String): RowWithHeadersEvaluator[String] =
        RowWithHeadersEvaluator((ixs, row) -> match Map.get(label, ixs) {
            case None => Err(IllegalArgumentException)
            case Some(ix) => {
                if (ix >= 0 && ix < Array.length(row)) {
                    let s = row[ix];
                    Ok(s)
                } else {
                    Err(IllegalArgumentException)
                }
            }
        })

    pub def evalMatches(label: String, patt: Text/Regex.Pattern, eval: Text/Regex.MatchEvaluator[a]): RowWithHeadersEvaluator[a] =
        let* input = getString(label);
        let* ans = liftAction(_ -> Text/Regex.evalMatches(input, patt, eval));
        return(ans)

    pub def evalContains(label: String, patt: Text/Regex.Pattern, eval: Text/Regex.MatchEvaluator[a]): RowWithHeadersEvaluator[a] =
        let* input = getString(label);
        let* ans = liftAction(_ -> Text/Regex.evalContains(input, patt, eval));
        return(ans)

    pub def getInt8(label: String): RowWithHeadersEvaluator[Int8] =
        let* s = getString(label);
        liftResult(Int8.fromString(s) |> Result.mapErr(_ -> InputMismatchException))
        
    pub def getInt16(label: String): RowWithHeadersEvaluator[Int16] =
        let* s = getString(label);
        liftResult(Int16.fromString(s) |> Result.mapErr(_ -> InputMismatchException))
    
    pub def getInt32(label: String): RowWithHeadersEvaluator[Int32] =
        let* s = getString(label);
        liftResult(Int32.fromString(s) |> Result.mapErr(_ -> InputMismatchException))
    
    pub def getInt64(label: String): RowWithHeadersEvaluator[Int64] =
        let* s = getString(label);
        liftResult(Int64.fromString(s) |> Result.mapErr(_ -> InputMismatchException))

    pub def getFloat32(label: String): RowWithHeadersEvaluator[Float32] =
        let* s = getString(label);
        liftResult(Float32.fromString(s) |> Result.mapErr(_ -> InputMismatchException))

    pub def getFloat64(label: String): RowWithHeadersEvaluator[Float64] =
        let* s = getString(label);
        liftResult(Float64.fromString(s) |> Result.mapErr(_ -> InputMismatchException))


}