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

use FactIO/FlatFile.LineEvaluator;
use FactIO/FlatFile.LineEvaluator.{LineEvaluator};

namespace FactIO/FlatFile {

    pub opaque type LineEvaluator[a] = String ~> Result[a, System.Error]
}

namespace FactIO/FlatFile/LineEvaluator {


    pub def return(x: a): LineEvaluator[a] = 
        LineEvaluator(_ -> Ok(x) as & Impure)

    def apply1(x: LineEvaluator[a], s: String): Result[a, System.Error] & Impure =
        let LineEvaluator(f) = x;
        f(s)

    pub def map(f: a -> b & e, x: LineEvaluator[a]): LineEvaluator[b] =
        LineEvaluator(s -> 
            match apply1(x, s) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )        

    pub def ap(mf: LineEvaluator[a -> b], ma: LineEvaluator[a]): LineEvaluator[b] =
        LineEvaluator(s -> 
            match apply1(mf, s) {
                case Ok(f) => { 
                    match apply1(ma, s) {
                        case Ok(a) => Ok(f(a))
                        case Err(e2) => Err(e2)
                    }
                }
                case Err(e1) => Err(e1)
            }
        )

    pub def bind(x: LineEvaluator[a], k: a -> LineEvaluator[b]): LineEvaluator[b] = 
        LineEvaluator(s -> 
            match apply1(x, s) { 
                case Ok(a) => apply1(k(a), s)
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> LineEvaluator[b], x: LineEvaluator[a]): LineEvaluator[b] = bind(x, k)

    pub def liftResult(x: Result[a, System.Error]): LineEvaluator[a] = 
        LineEvaluator(_ -> x as & Impure)

    pub def liftAction(f: Unit ~> Result[a, System.Error]): LineEvaluator[a] =
        LineEvaluator(_ -> f())

    pub def throwError(err: System.Error): LineEvaluator[a] =
        LineEvaluator(_ -> Err(err) as & Impure)

    pub def choice(xs: List[LineEvaluator[a]]): LineEvaluator[a] =
        LineEvaluator(r -> choiceHelper(r, xs))

    def choiceHelper(r: String, xs: List[LineEvaluator[a]]): Result[a, System.Error] & Impure =
        match xs {
            case Nil => Err(InputMismatchException) as & Impure
            case x1 :: rs => match apply1(x1, r) {
                case Ok(a) => Ok(a)
                case Err(_) => choiceHelper(r, rs)
            }
        }

    /// Line readers

    pub def content(): LineEvaluator[String] =
        LineEvaluator(s -> Ok(s) as & Impure)

    pub def matchRegex(pattern: String, eval: Text/Regex.MatchEvaluator[a]): LineEvaluator[a] =
        use Result.flatMap;
        use Text/Regex.{evalMatches};
        LineEvaluator(s ->
            let* patt = Text/Regex/Pattern.compile(pattern);
            let* ans = evalMatches(s, patt, eval);
            Ok(ans)
        )

    pub def findRegex(pattern: String, eval: Text/Regex.MatchEvaluator[a]): LineEvaluator[a] =
        use Result.flatMap;
        use Text/Regex.{evalContains};
        LineEvaluator(s -> 
            let* patt = Text/Regex/Pattern.compile(pattern);
            let* ans = evalContains(s, patt, eval);
            Ok(ans)
        )

    pub def ifThen(cond: LineEvaluator[Bool], eval: LineEvaluator[a]): LineEvaluator[Option[a]] =
        bind(cond, b -> if (b) map(Some, eval) else return(None))



    ///
    /// Applies the binary function `f` to the values in `o1` and `o2`.
    ///
    /// Returns an error if either `o1` or `o2` are errors.
    ///
    pub def lift2(f: (t1, t2) -> u & f, o1: LineEvaluator[t1], o2: LineEvaluator[t2]): LineEvaluator[u] =
        ap(map(f, o1), o2)

    ///
    /// Applies the ternary function `f` to the values in `o1`, `o2` and `o3`.
    ///
    /// Returns an error if any of `o1`, `o2` and `o3` are errors.
    ///
    pub def lift3(f: (t1, t2, t3) -> u & f, o1: LineEvaluator[t1], o2: LineEvaluator[t2], o3: LineEvaluator[t3]): LineEvaluator[u] & f =
        ap(lift2(f, o1, o2), o3)

    ///
    /// Applies the 4-ary function `f` to the values in `o1`, `o2`, `o3` and `o4`.
    ///
    /// Returns an error if any of `o1`, `o2`, `o3` and `o4` are errors.
    ///
    pub def lift4(f: (t1, t2, t3, t4) -> u & f, o1: LineEvaluator[t1], o2: LineEvaluator[t2], o3: LineEvaluator[t3], o4: LineEvaluator[t4]): LineEvaluator[u] & f =
        ap(lift3(f, o1, o2, o3), o4)

    ///
    /// Applies the 5-ary function `f` to the values in `o1`, `o2`, ... `o5`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o5` are errors.
    ///
    pub def lift5(f: (t1, t2, t3, t4, t5) -> u & f, o1: LineEvaluator[t1], o2: LineEvaluator[t2], o3: LineEvaluator[t3], o4: LineEvaluator[t4], o5: LineEvaluator[t5]): LineEvaluator[u] & f =
        ap(lift4(f, o1, o2, o3, o4), o5)

    ///
    /// Applies the 6-ary function `f` to the values in `o1`, `o2`, ... `o6`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o6` are errors.
    ///
    pub def lift6(f: (t1, t2, t3, t4, t5, t6) -> u & f, o1: LineEvaluator[t1], o2: LineEvaluator[t2], o3: LineEvaluator[t3], o4: LineEvaluator[t4], o5: LineEvaluator[t5], o6: LineEvaluator[t6]): LineEvaluator[u] & f =
        ap(lift5(f, o1, o2, o3, o4, o5), o6)

    ///
    /// Applies the 7-ary function `f` to the values in `o1`, `o2`, ... `o7`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o7` are errors.
    ///
    pub def lift7(f: (t1, t2, t3, t4, t5, t6, t7) -> u & f, o1: LineEvaluator[t1], o2: LineEvaluator[t2], o3: LineEvaluator[t3], o4: LineEvaluator[t4], o5: LineEvaluator[t5], o6: LineEvaluator[t6], o7: LineEvaluator[t7]): LineEvaluator[u] & f=
        ap(lift6(f, o1, o2, o3, o4, o5, o6), o7)

    ///
    /// Applies the 8-ary function `f` to the values in `o1`, `o2`, ... `o8`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o8` are errors.
    ///
    pub def lift8(f: (t1, t2, t3, t4, t5, t6, t7, t8) -> u & f, o1: LineEvaluator[t1], o2: LineEvaluator[t2], o3: LineEvaluator[t3], o4: LineEvaluator[t4], o5: LineEvaluator[t5], o6: LineEvaluator[t6], o7: LineEvaluator[t7], o8: LineEvaluator[t8]): LineEvaluator[u] & f =
        ap(lift7(f, o1, o2, o3, o4, o5, o6, o7), o8)

    ///
    /// Applies the 9-ary function `f` to the values in `o1`, `o2`, ... `o9`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o9` are errors.
    ///
    pub def lift9(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> u & f, o1: LineEvaluator[t1], o2: LineEvaluator[t2], o3: LineEvaluator[t3], o4: LineEvaluator[t4], o5: LineEvaluator[t5], o6: LineEvaluator[t6], o7: LineEvaluator[t7], o8: LineEvaluator[t8], o9: LineEvaluator[t9]): LineEvaluator[u] & f =
        ap(lift8(f, o1, o2, o3, o4, o5, o6, o7, o8), o9)

    ///
    /// Applies the 10-ary function `f` to the values in `o1`, `o2`, ... `o10`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o10` are errors.
    ///
    pub def lift10(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> u & f, o1: LineEvaluator[t1], o2: LineEvaluator[t2], o3: LineEvaluator[t3], o4: LineEvaluator[t4], o5: LineEvaluator[t5], o6: LineEvaluator[t6], o7: LineEvaluator[t7], o8: LineEvaluator[t8], o9: LineEvaluator[t9], o10: LineEvaluator[t10]): LineEvaluator[u] & f =
        ap(lift9(f, o1, o2, o3, o4, o5, o6, o7, o8, o9), o10)


}