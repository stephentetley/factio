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

use FactIO/FlatFile.RowEvaluator;
use FactIO/FlatFile.RowEvaluator.{RowEvaluator};
use FactIO/FlatFile.LineEvaluator;
use FactIO/FlatFile.LineEvaluator.{LineEvaluator};

namespace FactIO/FlatFile {

    pub opaque type RowEvaluator[a] = Array[String] ~> Result[a, System.Error]
}

namespace FactIO/FlatFile/RowEvaluator {

    pub def toLineEvaluator(splitter: String ~> Array[String], eval: RowEvaluator[a]): LineEvaluator[a] =
        let RowEvaluator(f) = eval;
        LineEvaluator(s -> let arr = splitter(s); f(arr))

    pub def return(x: a): RowEvaluator[a] =
        RowEvaluator(_ -> Ok(x) as & Impure)

    def apply1(x: RowEvaluator[a], row: Array[String]): Result[a, System.Error] & Impure =
        let RowEvaluator(f) = x;
        f(row)

    pub def map(f: a -> b & e, x: RowEvaluator[a]): RowEvaluator[b] =
        RowEvaluator(row ->
            match apply1(x, row) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )        

    pub def ap(mf: RowEvaluator[a -> b], ma: RowEvaluator[a]): RowEvaluator[b] =
        RowEvaluator(row ->
            match apply1(mf, row) {
                case Ok(f) => { 
                    match apply1(ma, row) {
                        case Ok(a) => Ok(f(a))
                        case Err(e2) => Err(e2)
                    }
                }
                case Err(e1) => Err(e1)
            }
        )

    pub def bind(x: RowEvaluator[a], k: a -> RowEvaluator[b]): RowEvaluator[b] =
        RowEvaluator(row ->
            match apply1(x, row) {
                case Ok(a) => apply1(k(a), row)
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> RowEvaluator[b], x: RowEvaluator[a]): RowEvaluator[b] = bind(x, k)

    def liftResult(x: Result[a, System.Error]): RowEvaluator[a] =
        RowEvaluator(_ -> x as & Impure)

    def liftAction(fn: Unit ~> Result[a, System.Error] ): RowEvaluator[a] =
        RowEvaluator(_ -> fn())

    // Cell readers, by index only

    pub def getString(ix: Int32): RowEvaluator[String] =
        RowEvaluator(row ->
            if (ix >= 0 && ix < Array.length(row)) {
                let s = row[ix];
                Ok(s)
            } else {
                Err(IllegalArgumentException)
            }
        )


    pub def evalMatches(ix: Int32, patt: Text/Regex.Pattern, eval: Text/Regex.MatchEvaluator[a]): RowEvaluator[a] =
        let* input = getString(ix);
        let* ans = liftAction(_ -> Text/Regex.evalMatches(input, patt, eval));
        return(ans)

    pub def evalContains(ix: Int32, patt: Text/Regex.Pattern, eval: Text/Regex.MatchEvaluator[a]): RowEvaluator[a] =
        let* input = getString(ix);
        let* ans = liftAction(_ -> Text/Regex.evalContains(input, patt, eval));
        return(ans)

    pub def getInt8(ix: Int32): RowEvaluator[Int8] =
        let* s = getString(ix);
        liftResult(Int8.fromString(s) |> Result.mapErr(_ -> InputMismatchException))
        
    pub def getInt16(ix: Int32): RowEvaluator[Int16] =
        let* s = getString(ix);
        liftResult(Int16.fromString(s) |> Result.mapErr(_ -> InputMismatchException))
    
    pub def getInt32(ix: Int32): RowEvaluator[Int32] =
        let* s = getString(ix);
        liftResult(Int32.fromString(s) |> Result.mapErr(_ -> InputMismatchException))
    
    pub def getInt64(ix: Int32): RowEvaluator[Int64] =
        let* s = getString(ix);
        liftResult(Int64.fromString(s) |> Result.mapErr(_ -> InputMismatchException))

    pub def getFloat32(ix: Int32): RowEvaluator[Float32] =
        let* s = getString(ix);
        liftResult(Float32.fromString(s) |> Result.mapErr(_ -> InputMismatchException))

    pub def getFloat64(ix: Int32): RowEvaluator[Float64] =
        let* s = getString(ix);
        liftResult(Float64.fromString(s) |> Result.mapErr(_ -> InputMismatchException))


}