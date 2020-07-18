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

use System.Error.{InputMismatchException, Generic};

use FactIO.FlatFileLineEvaluator;
use FactIO.FlatFileLineEvaluator.{FlatFileLineEvaluator};

namespace FactIO {

    pub opaque type FlatFileLineEvaluator[a] = String ~> Result[a, System.Error]
}

namespace FactIO/FlatFileLineEvaluator {


    pub def return(x: a): FlatFileLineEvaluator[a] =
        FlatFileLineEvaluator(_ -> Ok(x) as & Impure)

    def apply1(x: FlatFileLineEvaluator[a], s: String): Result[a, System.Error] & Impure =
        let FlatFileLineEvaluator(f) = x;
        f(s)

    pub def map(f: a -> b & ef, x: FlatFileLineEvaluator[a]): FlatFileLineEvaluator[b] =
        FlatFileLineEvaluator(s ->
            match apply1(x, s) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )        

    pub def ap(mf: FlatFileLineEvaluator[a -> b & ef], ma: FlatFileLineEvaluator[a]): FlatFileLineEvaluator[b] =
        FlatFileLineEvaluator(s ->
            match apply1(mf, s) {
                case Ok(f) => { 
                    match apply1(ma, s) {
                        case Ok(a) => Ok(f(a) as & Impure)
                        case Err(e2) => Err(e2)
                    }
                }
                case Err(e1) => Err(e1)
            }
        )

    pub def bind(x: FlatFileLineEvaluator[a], k: a -> FlatFileLineEvaluator[b]): FlatFileLineEvaluator[b] =
        FlatFileLineEvaluator(s ->
            match apply1(x, s) { 
                case Ok(a) => apply1(k(a), s)
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> FlatFileLineEvaluator[b], x: FlatFileLineEvaluator[a]): FlatFileLineEvaluator[b] = bind(x, k)

    pub def optional(x: FlatFileLineEvaluator[a]): FlatFileLineEvaluator[Option[a]] =
        FlatFileLineEvaluator(s ->
            match apply1(x, s) {
                case Ok(a) => Ok(Some(a))
                case Err(_) => Ok(None)
            }
        )

    pub def liftResult(x: Result[a, System.Error]): FlatFileLineEvaluator[a] =
        FlatFileLineEvaluator(_ -> x as & Impure)

    pub def liftOperation(f: Unit ~> Result[a, System.Error]): FlatFileLineEvaluator[a] =
        FlatFileLineEvaluator(_ -> f())

    pub def throwError(err: System.Error): FlatFileLineEvaluator[a] =
        FlatFileLineEvaluator(_ -> Err(err) as & Impure)

    pub def choice(xs: List[FlatFileLineEvaluator[a]]): FlatFileLineEvaluator[a] =
        FlatFileLineEvaluator(r -> choiceHelper(r, xs))

    def choiceHelper(r: String, xs: List[FlatFileLineEvaluator[a]]): Result[a, System.Error] & Impure =
        match xs {
            case Nil => Err(InputMismatchException) as & Impure
            case x1 :: rs => match apply1(x1, r) {
                case Ok(a) => Ok(a)
                case Err(_) => choiceHelper(r, rs)
            }
        }

    /// Line readers

    pub def content(): FlatFileLineEvaluator[String] =
        FlatFileLineEvaluator(s -> Ok(s) as & Impure)

    pub def matches(patt: Text/Regex.Pattern, eval: Text/Regex.MatchEvaluator[a]): FlatFileLineEvaluator[a] =
        use Result.flatMap;
        use Text/Regex.{evalMatches};
        FlatFileLineEvaluator(s ->
            let* ans = evalMatches(s, patt, eval);
            Ok(ans)
        )

    pub def matchesRegex(regex: String, eval: Text/Regex.MatchEvaluator[a]): FlatFileLineEvaluator[a] =
        let* patt = liftResult(Text/Regex/Pattern.compile(regex));
        matches(patt, eval)

    pub def find(patt: Text/Regex.Pattern, eval: Text/Regex.MatchEvaluator[a]): FlatFileLineEvaluator[a] =
        use Result.flatMap;
        use Text/Regex.{evalContains};
        FlatFileLineEvaluator(s ->
            let* ans = evalContains(s, patt, eval);
            Ok(ans)
        )

    pub def findRegex(regex: String, eval: Text/Regex.MatchEvaluator[a]): FlatFileLineEvaluator[a] =
        let* patt = liftResult(Text/Regex/Pattern.compile(regex));
        find(patt, eval)

    pub def ifThen(cond: FlatFileLineEvaluator[Bool], eval: FlatFileLineEvaluator[a]): FlatFileLineEvaluator[Option[a]] =
        bind(cond, b -> if (b) map(Some, eval) else return(None))



    ///
    /// Applies the binary function `f` to the values in `o1` and `o2`.
    ///
    /// Returns an error if either `o1` or `o2` are errors.
    ///
    pub def lift2(f: (t1, t2) -> u & ef, o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2]): FlatFileLineEvaluator[u] =
        ap(map(f, o1), o2)

    ///
    /// Applies the ternary function `f` to the values in `o1`, `o2` and `o3`.
    ///
    /// Returns an error if any of `o1`, `o2` and `o3` are errors.
    ///
    pub def lift3(f: (t1, t2, t3) -> u & ef, o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2], o3: FlatFileLineEvaluator[t3]): FlatFileLineEvaluator[u] =
        ap(lift2(f, o1, o2), o3)

    ///
    /// Applies the 4-ary function `f` to the values in `o1`, `o2`, `o3` and `o4`.
    ///
    /// Returns an error if any of `o1`, `o2`, `o3` and `o4` are errors.
    ///
    pub def lift4(f: (t1, t2, t3, t4) -> u & ef, o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2], o3: FlatFileLineEvaluator[t3], o4: FlatFileLineEvaluator[t4]): FlatFileLineEvaluator[u] =
        ap(lift3(f, o1, o2, o3), o4)

    ///
    /// Applies the 5-ary function `f` to the values in `o1`, `o2`, ... `o5`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o5` are errors.
    ///
    pub def lift5(f: (t1, t2, t3, t4, t5) -> u & ef, o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2], o3: FlatFileLineEvaluator[t3], o4: FlatFileLineEvaluator[t4], o5: FlatFileLineEvaluator[t5]): FlatFileLineEvaluator[u] =
        ap(lift4(f, o1, o2, o3, o4), o5)

    ///
    /// Applies the 6-ary function `f` to the values in `o1`, `o2`, ... `o6`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o6` are errors.
    ///
    pub def lift6(f: (t1, t2, t3, t4, t5, t6) -> u & ef, o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2], o3: FlatFileLineEvaluator[t3], o4: FlatFileLineEvaluator[t4], o5: FlatFileLineEvaluator[t5], o6: FlatFileLineEvaluator[t6]): FlatFileLineEvaluator[u] =
        ap(lift5(f, o1, o2, o3, o4, o5), o6)

    ///
    /// Applies the 7-ary function `f` to the values in `o1`, `o2`, ... `o7`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o7` are errors.
    ///
    pub def lift7(f: (t1, t2, t3, t4, t5, t6, t7) -> u & ef, o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2], o3: FlatFileLineEvaluator[t3], o4: FlatFileLineEvaluator[t4], o5: FlatFileLineEvaluator[t5], o6: FlatFileLineEvaluator[t6], o7: FlatFileLineEvaluator[t7]): FlatFileLineEvaluator[u] =
        ap(lift6(f, o1, o2, o3, o4, o5, o6), o7)

    ///
    /// Applies the 8-ary function `f` to the values in `o1`, `o2`, ... `o8`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o8` are errors.
    ///
    pub def lift8(f: (t1, t2, t3, t4, t5, t6, t7, t8) -> u & ef, o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2], o3: FlatFileLineEvaluator[t3], o4: FlatFileLineEvaluator[t4], o5: FlatFileLineEvaluator[t5], o6: FlatFileLineEvaluator[t6], o7: FlatFileLineEvaluator[t7], o8: FlatFileLineEvaluator[t8]): FlatFileLineEvaluator[u] =
        ap(lift7(f, o1, o2, o3, o4, o5, o6, o7), o8)

    ///
    /// Applies the 9-ary function `f` to the values in `o1`, `o2`, ... `o9`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o9` are errors.
    ///
    pub def lift9(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> u & ef, o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2], o3: FlatFileLineEvaluator[t3], o4: FlatFileLineEvaluator[t4], o5: FlatFileLineEvaluator[t5], o6: FlatFileLineEvaluator[t6], o7: FlatFileLineEvaluator[t7], o8: FlatFileLineEvaluator[t8], o9: FlatFileLineEvaluator[t9]): FlatFileLineEvaluator[u] =
        ap(lift8(f, o1, o2, o3, o4, o5, o6, o7, o8), o9)

    ///
    /// Applies the 10-ary function `f` to the values in `o1`, `o2`, ... `o10`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o10` are errors.
    ///
    pub def lift10(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> u & ef, o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2], o3: FlatFileLineEvaluator[t3], o4: FlatFileLineEvaluator[t4], o5: FlatFileLineEvaluator[t5], o6: FlatFileLineEvaluator[t6], o7: FlatFileLineEvaluator[t7], o8: FlatFileLineEvaluator[t8], o9: FlatFileLineEvaluator[t9], o10: FlatFileLineEvaluator[t10]): FlatFileLineEvaluator[u] =
        ap(lift9(f, o1, o2, o3, o4, o5, o6, o7, o8, o9), o10)

    ///
    /// Returns a 2 element tuple with the results of applying the evaluators `o1` and `o2`.
    ///
    /// Returns an error if evaluating either `o1` or `o2` is an error.
    ///
    pub def tuple2(o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2]): FlatFileLineEvaluator[(t1, t2)] =
        lift2((x,y) -> (x,y), o1, o2)

    ///
    /// Returns a 3 element tuple with the results of applying the evaluators `o1`, `o2` and `o3`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2` and `o3` is an error.
    ///
    pub def tuple3(o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2], o3: FlatFileLineEvaluator[t3]): FlatFileLineEvaluator[(t1, t2, t3)] =
        lift3((x1, x2, x3) -> (x1, x2, x3), o1, o2, o3)

    ///
    /// Returns a 4 element tuple with the results of applying the evaluators `o1`, `o2`, `o3` and `o4`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, `o3` and `o4` is an error.
    ///
    pub def tuple4(o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2], o3: FlatFileLineEvaluator[t3], o4: FlatFileLineEvaluator[t4]): FlatFileLineEvaluator[(t1, t2, t3, t4)]  =
        lift4((x1, x2, x3, x4) -> (x1, x2, x3, x4), o1, o2, o3, o4)

    ///
    /// Returns a 5 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o5`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o5` is an error.
    ///
    pub def tuple5(o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2], o3: FlatFileLineEvaluator[t3], o4: FlatFileLineEvaluator[t4], o5: FlatFileLineEvaluator[t5]): FlatFileLineEvaluator[(t1, t2, t3, t4, t5)]  =
        lift5((x1, x2, x3, x4, x5) -> (x1, x2, x3, x4, x5), o1, o2, o3, o4, o5)

    ///
    /// Returns a 6 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o6`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o6` is an error.
    ///
    pub def tuple6(o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2], o3: FlatFileLineEvaluator[t3], o4: FlatFileLineEvaluator[t4], o5: FlatFileLineEvaluator[t5], o6: FlatFileLineEvaluator[t6]): FlatFileLineEvaluator[(t1, t2, t3, t4, t5, t6)]  =
        lift6((x1, x2, x3, x4, x5, x6) -> (x1, x2, x3, x4, x5, x6), o1, o2, o3, o4, o5, o6)

    ///
    /// Returns a 7 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o7`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o7` is an error.
    ///
    pub def tuple7(o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2], o3: FlatFileLineEvaluator[t3], o4: FlatFileLineEvaluator[t4], o5: FlatFileLineEvaluator[t5], o6: FlatFileLineEvaluator[t6], o7: FlatFileLineEvaluator[t7]): FlatFileLineEvaluator[(t1, t2, t3, t4, t5, t6, t7)]  =
        lift7((x1, x2, x3, x4, x5, x6, x7) -> (x1, x2, x3, x4, x5, x6, x7), o1, o2, o3, o4, o5, o6, o7)

    ///
    /// Returns a 8 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o8`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o8` is an error.
    ///
    pub def tuple8(o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2], o3: FlatFileLineEvaluator[t3], o4: FlatFileLineEvaluator[t4], o5: FlatFileLineEvaluator[t5], o6: FlatFileLineEvaluator[t6], o7: FlatFileLineEvaluator[t7], o8: FlatFileLineEvaluator[t8]): FlatFileLineEvaluator[(t1, t2, t3, t4, t5, t6, t7, t8)]  =
        lift8((x1, x2, x3, x4, x5, x6, x7, x8) -> (x1, x2, x3, x4, x5, x6, x7, x8), o1, o2, o3, o4, o5, o6, o7, o8)

    ///
    /// Returns a 9 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o9`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o9` is an error.
    ///
    pub def tuple9(o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2], o3: FlatFileLineEvaluator[t3], o4: FlatFileLineEvaluator[t4], o5: FlatFileLineEvaluator[t5], o6: FlatFileLineEvaluator[t6], o7: FlatFileLineEvaluator[t7], o8: FlatFileLineEvaluator[t8], o9: FlatFileLineEvaluator[t9]): FlatFileLineEvaluator[(t1, t2, t3, t4, t5, t6, t7, t8, t9)]  =
        lift9((x1, x2, x3, x4, x5, x6, x7, x8, x9) -> (x1, x2, x3, x4, x5, x6, x7, x8, x9), o1, o2, o3, o4, o5, o6, o7, o8, o9)

    ///
    /// Returns a 10 element tuple with the results of applying the evaluators `o1`, `o2`, ... `o10`.
    ///
    /// Returns an error if evaluating any of `o1`, `o2`, ... `o10` is an error.
    ///
    pub def tuple10(o1: FlatFileLineEvaluator[t1], o2: FlatFileLineEvaluator[t2], o3: FlatFileLineEvaluator[t3], o4: FlatFileLineEvaluator[t4], o5: FlatFileLineEvaluator[t5], o6: FlatFileLineEvaluator[t6], o7: FlatFileLineEvaluator[t7], o8: FlatFileLineEvaluator[t8], o9: FlatFileLineEvaluator[t9], o10: FlatFileLineEvaluator[t10]): FlatFileLineEvaluator[(t1, t2, t3, t4, t5, t6, t7, t8, t9, t10)]  =
        lift10((x1, x2, x3, x4, x5, x6, x7, x8, x9, x10) -> (x1, x2, x3, x4, x5, x6, x7, x8, x9, x10), o1, o2, o3, o4, o5, o6, o7, o8, o9, o10)

}