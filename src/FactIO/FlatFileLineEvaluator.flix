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


namespace FactIO {

    pub opaque type FlatFileLineEvaluator[a] = String -> Result[a, String] & Impure

    instance Functor[FlatFileLineEvaluator] {
        pub def map(f: a -> b & ef, x: FlatFileLineEvaluator[a]): FlatFileLineEvaluator[b] & ef =
            FactIO/FlatFileLineEvaluator.map(f, x)
    }

    instance Applicative[FlatFileLineEvaluator] {
        pub def point(x: a): FlatFileLineEvaluator[a] =
            FactIO/FlatFileLineEvaluator.point(x)

        pub def ap(mf: FlatFileLineEvaluator[a -> b & ef], ma: FlatFileLineEvaluator[a]): FlatFileLineEvaluator[b] & ef =
            FactIO/FlatFileLineEvaluator.ap(mf, ma)
    }

    instance Monad[FlatFileLineEvaluator] {
        pub def flatMap(k: a -> FlatFileLineEvaluator[b] & ef, x: FlatFileLineEvaluator[a]): FlatFileLineEvaluator[b] & ef = 
            FactIO/FlatFileLineEvaluator.flatMap(k, x)
    }
}

namespace FactIO/FlatFileLineEvaluator {


    use FactIO.FlatFileLineEvaluator;
    use FactIO.FlatFileLineEvaluator.{FlatFileLineEvaluator};

    pub def point(x: a): FlatFileLineEvaluator[a] =
        FlatFileLineEvaluator(_ -> Ok(x) as & Impure)

    def apply1(x: FlatFileLineEvaluator[a], s: String): Result[a, String] & Impure =
        let FlatFileLineEvaluator(f) = x;
        f(s)

    pub def map(f: a -> b & ef, x: FlatFileLineEvaluator[a]): FlatFileLineEvaluator[b] & ef =
        FlatFileLineEvaluator(s ->
            match apply1(x, s) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        ) as & ef

    pub def ap(mf: FlatFileLineEvaluator[a -> b & ef], ma: FlatFileLineEvaluator[a]): FlatFileLineEvaluator[b] & ef =
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
        ) as & ef

    pub def bind(x: FlatFileLineEvaluator[a], k: a -> FlatFileLineEvaluator[b] & ef): FlatFileLineEvaluator[b] & ef =
        FlatFileLineEvaluator(s ->
            match apply1(x, s) { 
                case Ok(a) => apply1(k(a) as & Impure, s)
                case Err(e) => Err(e)
            }
        ) as & ef

    pub def flatMap(k: a -> FlatFileLineEvaluator[b] & ef, x: FlatFileLineEvaluator[a]): FlatFileLineEvaluator[b] & ef = 
        bind(x, k)

    pub def optional(x: FlatFileLineEvaluator[a]): FlatFileLineEvaluator[Option[a]] =
        FlatFileLineEvaluator(s ->
            match apply1(x, s) {
                case Ok(a) => Ok(Some(a))
                case Err(_) => Ok(None)
            }
        )

    pub def liftOption(x: Option[a], errMsg: String): FlatFileLineEvaluator[a] = match x {
        case Some(x1) => point(x1)
        case None     => throwError(errMsg)
    }


    pub def liftResult(x: Result[a, String]): FlatFileLineEvaluator[a] =
        FlatFileLineEvaluator(_ -> x as & Impure)

    pub def liftOperation(f: Unit -> Result[a, String] & ef): FlatFileLineEvaluator[a] & ef =
        FlatFileLineEvaluator(_ -> f() as & Impure) as & ef

    pub def throwError(err: String): FlatFileLineEvaluator[a] =
        FlatFileLineEvaluator(_ -> Err(err) as & Impure)

    pub def choice(xs: List[FlatFileLineEvaluator[a]]): FlatFileLineEvaluator[a] =
        FlatFileLineEvaluator(r -> choiceHelper(r, xs))

    def choiceHelper(r: String, xs: List[FlatFileLineEvaluator[a]]): Result[a, String] & Impure =
        match xs {
            case Nil => Err("choice") as & Impure
            case x1 :: rs => match apply1(x1, r) {
                case Ok(a) => Ok(a)
                case Err(_) => choiceHelper(r, rs)
            }
        }

    /// Line readers

    pub def content(): FlatFileLineEvaluator[String] =
        FlatFileLineEvaluator(s -> Ok(s) as & Impure)

    pub def matches(patt: Text/Regex.Pattern): FlatFileLineEvaluator[String] =
        use Result.flatMap;
        FlatFileLineEvaluator(s ->
            let* ans = Text/Regex.matchAllContent(patt, s) |> Option.toOk("no match");
            Ok(ans) as & Impure
        )


    /// pub def matches(patt: Text/Regex.Pattern, eval: Text/RegexEval.MatchEvaluator[a]): FlatFileLineEvaluator[a] =
    ///     use Result.flatMap;
    ///     FlatFileLineEvaluator(s ->
    ///         let* ans = Text/RegexEval/Regex.matches(patt, eval, s);
    ///         Ok(ans)
    ///     )

    /// pub def matchesRegex(regex: String, eval: Text/RegexEval.MatchEvaluator[a]): FlatFileLineEvaluator[a] =
    ///     let* patt = liftResult(Text/Regex/Pattern.compile(regex) |> Result.mapErr(constant("matchesRegex('${regex}')")));
    ///     matches(patt, eval)

    /// pub def find(patt: Text/Regex.Pattern, eval: Text/RegexEval.MatchEvaluator[a]): FlatFileLineEvaluator[a] =
    ///     use Result.flatMap;
    ///     FlatFileLineEvaluator(s ->
    ///         let* ans = Text/RegexEval/Regex.contains(patt, eval, s);
    ///         Ok(ans)
    ///     )

    /// pub def findRegex(regex: String, eval: Text/RegexEval.MatchEvaluator[a]): FlatFileLineEvaluator[a] =
    ///     let* patt = liftResult(Text/Regex/Pattern.compile(regex) |> Result.mapErr(constant("findRegex('${regex}')")));
    ///     find(patt, eval)

    pub def ifThen(cond: FlatFileLineEvaluator[Bool], eval: FlatFileLineEvaluator[a]): FlatFileLineEvaluator[Option[a]] =
        bind(cond, b -> if (b) map(Some, eval) else point(None))


}
