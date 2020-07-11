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

    pub def map(f: a -> b & ef, x: RowWithHeadersEvaluator[a]): RowWithHeadersEvaluator[b] =
        RowWithHeadersEvaluator((ixs, row) ->
            match apply1(x, ixs, row) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )        

    pub def ap(mf: RowWithHeadersEvaluator[a -> b & ef], ma: RowWithHeadersEvaluator[a]): RowWithHeadersEvaluator[b] =
        RowWithHeadersEvaluator((ixs, row) ->
            match apply1(mf, ixs, row) {
                case Ok(f) => { 
                    match apply1(ma, ixs, row) {
                        case Ok(a) => Ok(f(a) as & Impure)
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

    pub def optional(x: RowWithHeadersEvaluator[a]): RowWithHeadersEvaluator[Option[a]] =
        RowWithHeadersEvaluator((ixs, row) ->
            match apply1(x, ixs, row) {
                case Ok(a) => Ok(Some(a))
                case Err(_) => Ok(None)
            }
        )

    pub def liftResult(x: Result[a, System.Error]): RowWithHeadersEvaluator[a] =
        RowWithHeadersEvaluator((_,_) -> x as & Impure)

    pub def liftOperation(fn: Unit ~> Result[a, System.Error] ): RowWithHeadersEvaluator[a] =
        RowWithHeadersEvaluator((_,_) -> fn())

    // Cell readers, by label only

    /// Note - answer is trimmed, use `getCell` if you need exact contents
    pub def getString(label: String): RowWithHeadersEvaluator[String] =
        map(String.trim, getCell(label))

    pub def getCell(label: String): RowWithHeadersEvaluator[String] =
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
        let* ans = liftOperation(_ -> Text/Regex.evalMatches(input, patt, eval));
        return(ans)

    pub def evalContains(label: String, patt: Text/Regex.Pattern, eval: Text/Regex.MatchEvaluator[a]): RowWithHeadersEvaluator[a] =
        let* input = getString(label);
        let* ans = liftOperation(_ -> Text/Regex.evalContains(input, patt, eval));
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

    pub def getLocalDate(label: String, formatter: Time/Format.DateFormatter): RowWithHeadersEvaluator[Time.LocalDate] =
        let* input = getString(label);
        let* ans = liftResult(Time/LocalDate.parse(input, formatter));
        return(ans)

    pub def getLocalDateTime(label: String, formatter: Time/Format.DateTimeFormatter): RowWithHeadersEvaluator[Time.LocalDateTime] =
        let* input = getString(label);
        let* ans = liftResult(Time/LocalDateTime.parse(input, formatter));
        return(ans)

    pub def getLocalTime(label: String, formatter: Time/Format.TimeFormatter): RowWithHeadersEvaluator[Time.LocalTime] =
        let* input = getString(label);
        let* ans = liftResult(Time/LocalTime.parse(input, formatter));
        return(ans)

    ///
    /// Applies the binary function `f` to the values in `o1` and `o2`.
    ///
    /// Returns an error if either `o1` or `o2` are errors.
    ///
    pub def lift2(f: (t1, t2) -> u & ef, o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2]): RowWithHeadersEvaluator[u] =
        ap(map(f, o1), o2)
        
    ///
    /// Applies the ternary function `f` to the values in `o1`, `o2` and `o3`.
    ///
    /// Returns an error if any of `o1`, `o2` and `o3` are errors.
    ///
    pub def lift3(f: (t1, t2, t3) -> u & ef, o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2], o3: RowWithHeadersEvaluator[t3]): RowWithHeadersEvaluator[u] =
        ap(lift2(f, o1, o2), o3)

    ///
    /// Applies the 4-ary function `f` to the values in `o1`, `o2`, `o3` and `o4`.
    ///
    /// Returns an error if any of `o1`, `o2`, `o3` and `o4` are errors.
    ///
    pub def lift4(f: (t1, t2, t3, t4) -> u & ef, o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2], o3: RowWithHeadersEvaluator[t3], o4: RowWithHeadersEvaluator[t4]): RowWithHeadersEvaluator[u] =
        ap(lift3(f, o1, o2, o3), o4)

    ///
    /// Applies the 5-ary function `f` to the values in `o1`, `o2`, ... `o5`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o5` are errors.
    ///
    pub def lift5(f: (t1, t2, t3, t4, t5) -> u & ef, o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2], o3: RowWithHeadersEvaluator[t3], o4: RowWithHeadersEvaluator[t4], o5: RowWithHeadersEvaluator[t5]): RowWithHeadersEvaluator[u] =
        ap(lift4(f, o1, o2, o3, o4), o5)

    ///
    /// Applies the 6-ary function `f` to the values in `o1`, `o2`, ... `o6`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o6` are errors.
    ///
    pub def lift6(f: (t1, t2, t3, t4, t5, t6) -> u & ef, o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2], o3: RowWithHeadersEvaluator[t3], o4: RowWithHeadersEvaluator[t4], o5: RowWithHeadersEvaluator[t5], o6: RowWithHeadersEvaluator[t6]): RowWithHeadersEvaluator[u] =
        ap(lift5(f, o1, o2, o3, o4, o5), o6)

    ///
    /// Applies the 7-ary function `f` to the values in `o1`, `o2`, ... `o7`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o7` are errors.
    ///
    pub def lift7(f: (t1, t2, t3, t4, t5, t6, t7) -> u & ef, o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2], o3: RowWithHeadersEvaluator[t3], o4: RowWithHeadersEvaluator[t4], o5: RowWithHeadersEvaluator[t5], o6: RowWithHeadersEvaluator[t6], o7: RowWithHeadersEvaluator[t7]): RowWithHeadersEvaluator[u] =
        ap(lift6(f, o1, o2, o3, o4, o5, o6), o7)

    ///
    /// Applies the 8-ary function `f` to the values in `o1`, `o2`, ... `o8`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o8` are errors.
    ///
    pub def lift8(f: (t1, t2, t3, t4, t5, t6, t7, t8) -> u & ef, o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2], o3: RowWithHeadersEvaluator[t3], o4: RowWithHeadersEvaluator[t4], o5: RowWithHeadersEvaluator[t5], o6: RowWithHeadersEvaluator[t6], o7: RowWithHeadersEvaluator[t7], o8: RowWithHeadersEvaluator[t8]): RowWithHeadersEvaluator[u] =
        ap(lift7(f, o1, o2, o3, o4, o5, o6, o7), o8)

    ///
    /// Applies the 9-ary function `f` to the values in `o1`, `o2`, ... `o9`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o9` are errors.
    ///
    pub def lift9(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> u & ef, o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2], o3: RowWithHeadersEvaluator[t3], o4: RowWithHeadersEvaluator[t4], o5: RowWithHeadersEvaluator[t5], o6: RowWithHeadersEvaluator[t6], o7: RowWithHeadersEvaluator[t7], o8: RowWithHeadersEvaluator[t8], o9: RowWithHeadersEvaluator[t9]): RowWithHeadersEvaluator[u] =
        ap(lift8(f, o1, o2, o3, o4, o5, o6, o7, o8), o9)

    ///
    /// Applies the 10-ary function `f` to the values in `o1`, `o2`, ... `o10`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o10` are errors.
    ///
    pub def lift10(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> u & ef, o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2], o3: RowWithHeadersEvaluator[t3], o4: RowWithHeadersEvaluator[t4], o5: RowWithHeadersEvaluator[t5], o6: RowWithHeadersEvaluator[t6], o7: RowWithHeadersEvaluator[t7], o8: RowWithHeadersEvaluator[t8], o9: RowWithHeadersEvaluator[t9], o10: RowWithHeadersEvaluator[t10]): RowWithHeadersEvaluator[u] =
        ap(lift9(f, o1, o2, o3, o4, o5, o6, o7, o8, o9), o10)

    ///
    /// Returns a 2 element tuple with the results of applying the evaluators `o1` and `o2`.
    ///
    /// Returns an error if evaluating either `o1` or `o2` is an error.
    ///
    pub def tuple2(o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2]): RowWithHeadersEvaluator[(t1, t2)] =
        lift2((x,y) -> (x,y), o1, o2)

    ///
    /// Returns a 3 element tuple with the results of applying the evaluators `o1`, `o2` and `o3`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2` and `o3` is an error.
    ///
    pub def tuple3(o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2], o3: RowWithHeadersEvaluator[t3]): RowWithHeadersEvaluator[(t1, t2, t3)] =
        lift3((x1, x2, x3) -> (x1, x2, x3), o1, o2, o3)

    ///
    /// Returns a 4 element tuple with the results of applying the evaluators `o1`, `o2`, `o3` and `o4`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, `o3` and `o4` is an error.
    ///
    pub def tuple4(o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2], o3: RowWithHeadersEvaluator[t3], o4: RowWithHeadersEvaluator[t4]): RowWithHeadersEvaluator[(t1, t2, t3, t4)]  =
        lift4((x1, x2, x3, x4) -> (x1, x2, x3, x4), o1, o2, o3, o4)

    ///
    /// Returns a 5 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o5`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o5` is an error.
    ///
    pub def tuple5(o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2], o3: RowWithHeadersEvaluator[t3], o4: RowWithHeadersEvaluator[t4], o5: RowWithHeadersEvaluator[t5]): RowWithHeadersEvaluator[(t1, t2, t3, t4, t5)]  =
        lift5((x1, x2, x3, x4, x5) -> (x1, x2, x3, x4, x5), o1, o2, o3, o4, o5)

    ///
    /// Returns a 6 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o6`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o6` is an error.
    ///
    pub def tuple6(o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2], o3: RowWithHeadersEvaluator[t3], o4: RowWithHeadersEvaluator[t4], o5: RowWithHeadersEvaluator[t5], o6: RowWithHeadersEvaluator[t6]): RowWithHeadersEvaluator[(t1, t2, t3, t4, t5, t6)]  =
        lift6((x1, x2, x3, x4, x5, x6) -> (x1, x2, x3, x4, x5, x6), o1, o2, o3, o4, o5, o6)

    ///
    /// Returns a 7 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o7`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o7` is an error.
    ///
    pub def tuple7(o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2], o3: RowWithHeadersEvaluator[t3], o4: RowWithHeadersEvaluator[t4], o5: RowWithHeadersEvaluator[t5], o6: RowWithHeadersEvaluator[t6], o7: RowWithHeadersEvaluator[t7]): RowWithHeadersEvaluator[(t1, t2, t3, t4, t5, t6, t7)]  =
        lift7((x1, x2, x3, x4, x5, x6, x7) -> (x1, x2, x3, x4, x5, x6, x7), o1, o2, o3, o4, o5, o6, o7)

    ///
    /// Returns a 8 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o8`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o8` is an error.
    ///
    pub def tuple8(o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2], o3: RowWithHeadersEvaluator[t3], o4: RowWithHeadersEvaluator[t4], o5: RowWithHeadersEvaluator[t5], o6: RowWithHeadersEvaluator[t6], o7: RowWithHeadersEvaluator[t7], o8: RowWithHeadersEvaluator[t8]): RowWithHeadersEvaluator[(t1, t2, t3, t4, t5, t6, t7, t8)]  =
        lift8((x1, x2, x3, x4, x5, x6, x7, x8) -> (x1, x2, x3, x4, x5, x6, x7, x8), o1, o2, o3, o4, o5, o6, o7, o8)

    ///
    /// Returns a 9 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o9`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o9` is an error.
    ///
    pub def tuple9(o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2], o3: RowWithHeadersEvaluator[t3], o4: RowWithHeadersEvaluator[t4], o5: RowWithHeadersEvaluator[t5], o6: RowWithHeadersEvaluator[t6], o7: RowWithHeadersEvaluator[t7], o8: RowWithHeadersEvaluator[t8], o9: RowWithHeadersEvaluator[t9]): RowWithHeadersEvaluator[(t1, t2, t3, t4, t5, t6, t7, t8, t9)]  =
        lift9((x1, x2, x3, x4, x5, x6, x7, x8, x9) -> (x1, x2, x3, x4, x5, x6, x7, x8, x9), o1, o2, o3, o4, o5, o6, o7, o8, o9)

    ///
    /// Returns a 10 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o10`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o10` is an error.
    ///
    pub def tuple10(o1: RowWithHeadersEvaluator[t1], o2: RowWithHeadersEvaluator[t2], o3: RowWithHeadersEvaluator[t3], o4: RowWithHeadersEvaluator[t4], o5: RowWithHeadersEvaluator[t5], o6: RowWithHeadersEvaluator[t6], o7: RowWithHeadersEvaluator[t7], o8: RowWithHeadersEvaluator[t8], o9: RowWithHeadersEvaluator[t9], o10: RowWithHeadersEvaluator[t10]): RowWithHeadersEvaluator[(t1, t2, t3, t4, t5, t6, t7, t8, t9, t10)]  =
        lift10((x1, x2, x3, x4, x5, x6, x7, x8, x9, x10) -> (x1, x2, x3, x4, x5, x6, x7, x8, x9, x10), o1, o2, o3, o4, o5, o6, o7, o8, o9, o10)

}