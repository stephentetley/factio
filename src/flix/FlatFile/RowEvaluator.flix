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

    pub def map(f: a -> b & ef, x: RowEvaluator[a]): RowEvaluator[b] =
        RowEvaluator(row ->
            match apply1(x, row) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )        

    pub def ap(mf: RowEvaluator[a -> b & ef], ma: RowEvaluator[a]): RowEvaluator[b] =
        RowEvaluator(row ->
            match apply1(mf, row) {
                case Ok(f) => { 
                    match apply1(ma, row) {
                        case Ok(a) => Ok(f(a) as & Impure)
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

    pub def liftResult(x: Result[a, System.Error]): RowEvaluator[a] =
        RowEvaluator(_ -> x as & Impure)

    pub def liftOperation(fn: Unit ~> Result[a, System.Error]): RowEvaluator[a] =
        RowEvaluator(_ -> fn())

    // Cell readers, by index only

    /// Note - answer is trimmed, use `getCell` if you need exact contents
    pub def getString(ix: Int32): RowEvaluator[String] =
        map(String.trim, getCell(ix))

    pub def getCell(ix: Int32): RowEvaluator[String] =
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
        let* ans = liftOperation(_ -> Text/Regex.evalMatches(input, patt, eval));
        return(ans)

    pub def evalContains(ix: Int32, patt: Text/Regex.Pattern, eval: Text/Regex.MatchEvaluator[a]): RowEvaluator[a] =
        let* input = getString(ix);
        let* ans = liftOperation(_ -> Text/Regex.evalContains(input, patt, eval));
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

    pub def getLocalDate(ix: Int32, formatter: Time/Format.DateFormatter): RowEvaluator[Time.LocalDate] =
        let* input = getString(ix);
        let* ans = liftResult(Time/LocalDate.parse(input, formatter));
        return(ans)


    pub def getLocalDateTime(ix: Int32, formatter: Time/Format.DateTimeFormatter): RowEvaluator[Time.LocalDateTime] =
        let* input = getString(ix);
        let* ans = liftResult(Time/LocalDateTime.parse(input, formatter));
        return(ans)


    pub def getLocalTime(ix: Int32, formatter: Time/Format.TimeFormatter): RowEvaluator[Time.LocalTime] =
        let* input = getString(ix);
        let* ans = liftResult(Time/LocalTime.parse(input, formatter));
        return(ans)

    ///
    /// Applies the binary function `f` to the values in `o1` and `o2`.
    ///
    /// Returns an error if either `o1` or `o2` are errors.
    ///
    pub def lift2(f: (t1, t2) -> u & ef, o1: RowEvaluator[t1], o2: RowEvaluator[t2]): RowEvaluator[u] =
        ap(map(f, o1), o2)

    ///
    /// Applies the ternary function `f` to the values in `o1`, `o2` and `o3`.
    ///
    /// Returns an error if any of `o1`, `o2` and `o3` are errors.
    ///
    pub def lift3(f: (t1, t2, t3) -> u & ef, o1: RowEvaluator[t1], o2: RowEvaluator[t2], o3: RowEvaluator[t3]): RowEvaluator[u] =
        ap(lift2(f, o1, o2), o3)

    ///
    /// Applies the 4-ary function `f` to the values in `o1`, `o2`, `o3` and `o4`.
    ///
    /// Returns an error if any of `o1`, `o2`, `o3` and `o4` are errors.
    ///
    pub def lift4(f: (t1, t2, t3, t4) -> u & ef, o1: RowEvaluator[t1], o2: RowEvaluator[t2], o3: RowEvaluator[t3], o4: RowEvaluator[t4]): RowEvaluator[u] =
        ap(lift3(f, o1, o2, o3), o4)

    ///
    /// Applies the 5-ary function `f` to the values in `o1`, `o2`, ... `o5`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o5` are errors.
    ///
    pub def lift5(f: (t1, t2, t3, t4, t5) -> u & ef, o1: RowEvaluator[t1], o2: RowEvaluator[t2], o3: RowEvaluator[t3], o4: RowEvaluator[t4], o5: RowEvaluator[t5]): RowEvaluator[u] =
        ap(lift4(f, o1, o2, o3, o4), o5)

    ///
    /// Applies the 6-ary function `f` to the values in `o1`, `o2`, ... `o6`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o6` are errors.
    ///
    pub def lift6(f: (t1, t2, t3, t4, t5, t6) -> u & ef, o1: RowEvaluator[t1], o2: RowEvaluator[t2], o3: RowEvaluator[t3], o4: RowEvaluator[t4], o5: RowEvaluator[t5], o6: RowEvaluator[t6]): RowEvaluator[u] =
        ap(lift5(f, o1, o2, o3, o4, o5), o6)

    ///
    /// Applies the 7-ary function `f` to the values in `o1`, `o2`, ... `o7`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o7` are errors.
    ///
    pub def lift7(f: (t1, t2, t3, t4, t5, t6, t7) -> u & ef, o1: RowEvaluator[t1], o2: RowEvaluator[t2], o3: RowEvaluator[t3], o4: RowEvaluator[t4], o5: RowEvaluator[t5], o6: RowEvaluator[t6], o7: RowEvaluator[t7]): RowEvaluator[u] =
        ap(lift6(f, o1, o2, o3, o4, o5, o6), o7)

    ///
    /// Applies the 8-ary function `f` to the values in `o1`, `o2`, ... `o8`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o8` are errors.
    ///
    pub def lift8(f: (t1, t2, t3, t4, t5, t6, t7, t8) -> u & ef, o1: RowEvaluator[t1], o2: RowEvaluator[t2], o3: RowEvaluator[t3], o4: RowEvaluator[t4], o5: RowEvaluator[t5], o6: RowEvaluator[t6], o7: RowEvaluator[t7], o8: RowEvaluator[t8]): RowEvaluator[u] =
        ap(lift7(f, o1, o2, o3, o4, o5, o6, o7), o8)

    ///
    /// Applies the 9-ary function `f` to the values in `o1`, `o2`, ... `o9`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o9` are errors.
    ///
    pub def lift9(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> u & ef, o1: RowEvaluator[t1], o2: RowEvaluator[t2], o3: RowEvaluator[t3], o4: RowEvaluator[t4], o5: RowEvaluator[t5], o6: RowEvaluator[t6], o7: RowEvaluator[t7], o8: RowEvaluator[t8], o9: RowEvaluator[t9]): RowEvaluator[u] =
        ap(lift8(f, o1, o2, o3, o4, o5, o6, o7, o8), o9)

    ///
    /// Applies the 10-ary function `f` to the values in `o1`, `o2`, ... `o10`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o10` are errors.
    ///
    pub def lift10(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> u & ef, o1: RowEvaluator[t1], o2: RowEvaluator[t2], o3: RowEvaluator[t3], o4: RowEvaluator[t4], o5: RowEvaluator[t5], o6: RowEvaluator[t6], o7: RowEvaluator[t7], o8: RowEvaluator[t8], o9: RowEvaluator[t9], o10: RowEvaluator[t10]): RowEvaluator[u] =
        ap(lift9(f, o1, o2, o3, o4, o5, o6, o7, o8, o9), o10)

    ///
    /// Returns a 2 element tuple with the results of applying the evaluators `o1` and `o2`.
    ///
    /// Returns an error if evaluating either `o1` or `o2` is an error.
    ///
    pub def tuple2(o1: RowEvaluator[t1], o2: RowEvaluator[t2]): RowEvaluator[(t1, t2)] =
        lift2((x,y) -> (x,y), o1, o2)

    ///
    /// Returns a 3 element tuple with the results of applying the evaluators `o1`, `o2` and `o3`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2` and `o3` is an error.
    ///
    pub def tuple3(o1: RowEvaluator[t1], o2: RowEvaluator[t2], o3: RowEvaluator[t3]): RowEvaluator[(t1, t2, t3)] =
        lift3((x1, x2, x3) -> (x1, x2, x3), o1, o2, o3)

    ///
    /// Returns a 4 element tuple with the results of applying the evaluators `o1`, `o2`, `o3` and `o4`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, `o3` and `o4` is an error.
    ///
    pub def tuple4(o1: RowEvaluator[t1], o2: RowEvaluator[t2], o3: RowEvaluator[t3], o4: RowEvaluator[t4]): RowEvaluator[(t1, t2, t3, t4)]  =
        lift4((x1, x2, x3, x4) -> (x1, x2, x3, x4), o1, o2, o3, o4)

    ///
    /// Returns a 5 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o5`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o5` is an error.
    ///
    pub def tuple5(o1: RowEvaluator[t1], o2: RowEvaluator[t2], o3: RowEvaluator[t3], o4: RowEvaluator[t4], o5: RowEvaluator[t5]): RowEvaluator[(t1, t2, t3, t4, t5)]  =
        lift5((x1, x2, x3, x4, x5) -> (x1, x2, x3, x4, x5), o1, o2, o3, o4, o5)

    ///
    /// Returns a 6 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o6`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o6` is an error.
    ///
    pub def tuple6(o1: RowEvaluator[t1], o2: RowEvaluator[t2], o3: RowEvaluator[t3], o4: RowEvaluator[t4], o5: RowEvaluator[t5], o6: RowEvaluator[t6]): RowEvaluator[(t1, t2, t3, t4, t5, t6)]  =
        lift6((x1, x2, x3, x4, x5, x6) -> (x1, x2, x3, x4, x5, x6), o1, o2, o3, o4, o5, o6)

    ///
    /// Returns a 7 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o7`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o7` is an error.
    ///
    pub def tuple7(o1: RowEvaluator[t1], o2: RowEvaluator[t2], o3: RowEvaluator[t3], o4: RowEvaluator[t4], o5: RowEvaluator[t5], o6: RowEvaluator[t6], o7: RowEvaluator[t7]): RowEvaluator[(t1, t2, t3, t4, t5, t6, t7)]  =
        lift7((x1, x2, x3, x4, x5, x6, x7) -> (x1, x2, x3, x4, x5, x6, x7), o1, o2, o3, o4, o5, o6, o7)

    ///
    /// Returns a 8 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o8`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o8` is an error.
    ///
    pub def tuple8(o1: RowEvaluator[t1], o2: RowEvaluator[t2], o3: RowEvaluator[t3], o4: RowEvaluator[t4], o5: RowEvaluator[t5], o6: RowEvaluator[t6], o7: RowEvaluator[t7], o8: RowEvaluator[t8]): RowEvaluator[(t1, t2, t3, t4, t5, t6, t7, t8)]  =
        lift8((x1, x2, x3, x4, x5, x6, x7, x8) -> (x1, x2, x3, x4, x5, x6, x7, x8), o1, o2, o3, o4, o5, o6, o7, o8)

    ///
    /// Returns a 9 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o9`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o9` is an error.
    ///
    pub def tuple9(o1: RowEvaluator[t1], o2: RowEvaluator[t2], o3: RowEvaluator[t3], o4: RowEvaluator[t4], o5: RowEvaluator[t5], o6: RowEvaluator[t6], o7: RowEvaluator[t7], o8: RowEvaluator[t8], o9: RowEvaluator[t9]): RowEvaluator[(t1, t2, t3, t4, t5, t6, t7, t8, t9)]  =
        lift9((x1, x2, x3, x4, x5, x6, x7, x8, x9) -> (x1, x2, x3, x4, x5, x6, x7, x8, x9), o1, o2, o3, o4, o5, o6, o7, o8, o9)

    ///
    /// Returns a 10 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o10`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o10` is an error.
    ///
    pub def tuple10(o1: RowEvaluator[t1], o2: RowEvaluator[t2], o3: RowEvaluator[t3], o4: RowEvaluator[t4], o5: RowEvaluator[t5], o6: RowEvaluator[t6], o7: RowEvaluator[t7], o8: RowEvaluator[t8], o9: RowEvaluator[t9], o10: RowEvaluator[t10]): RowEvaluator[(t1, t2, t3, t4, t5, t6, t7, t8, t9, t10)]  =
        lift10((x1, x2, x3, x4, x5, x6, x7, x8, x9, x10) -> (x1, x2, x3, x4, x5, x6, x7, x8, x9, x10), o1, o2, o3, o4, o5, o6, o7, o8, o9, o10)

}