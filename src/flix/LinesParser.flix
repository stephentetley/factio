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

use Text.Charset.{Charset};

use System.Error.{IllegalStateException, IOException, Generic};

use FactIO.LinesParser;
use FactIO.LinesParser.{LinesParser};

use FactIO.LineEvaluator;
use FactIO.LineEvaluator.{LineEvaluator};
use FactIO/Internal.LinesIterator;
use FactIO/Internal.LinesIterator.{LinesIterator};

namespace FactIO { 
    
    pub opaque type LinesParser[a, st] = (LinesIterator, st) ~> Result[(a, st), System.Error]

}

/// This is a combinator library for making custom line based text importers
/// it is not an "instance" of a text importer hence it is called LinesParser
/// rather than LinesImport.

namespace FactIO/LinesParser {

    pub def runLinesParser(x: LinesParser[reln, st], stateZero: st, path: String, cs: Text.Charset): Result[reln, System.Error] & Impure =
        use Result.flatMap;
        use FactIO/Internal/LinesIterator.{close};
        let* iter = FactIO/Internal/LinesIterator.newLinesIterator(path, cs);
        match apply1(x, iter, stateZero) {
            case Ok((a, _)) => { let _ = close(iter); Ok(a) }
            case Err(e) => { let _ = close(iter); Err(e) }
        }
        

    pub def return(x: a): LinesParser[a, st] =
        LinesParser((_, s) -> Ok(x, s) as & Impure)

    def apply1(x: LinesParser[a, st], iter: LinesIterator, state: st): Result[(a, st), System.Error] & Impure =
        let LinesParser(f) = x;
        f(iter, state)

    pub def map(f: a -> b & e, x: LinesParser[a, st]): LinesParser[b, st] =
        LinesParser((r, s) ->
            match apply1(x, r, s) {
                case Ok((a, s1)) => {
                    let ans = f(a) as & Impure;
                    Ok((ans, s1))
                }
                case Err(e) => Err(e)
            }
        )

    pub def ap(mf: LinesParser[a -> b, st], ma: LinesParser[a, st]): LinesParser[b, st] =
        LinesParser((r, s) ->
            match apply1(mf, r, s) {
                case Ok((f, s1)) => {
                    match apply1(ma, r, s1) {
                        case Ok((a, s2)) => {let x = f(a); Ok(x, s2) }
                        case Err(e2) => Err(e2)
                    }
                }
                case Err(e1) => Err(e1)
            }
        )

    pub def bind(x: LinesParser[a, st], k: a -> LinesParser[b, st]): LinesParser[b, st] =
        LinesParser((r, s) ->
            match apply1(x, r, s) {
                case Ok((a, s1)) => { let p1 = k(a); apply1(p1, r, s1) }
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> LinesParser[b, st], x: LinesParser[a, st]): LinesParser[b, st] = bind(x, k)

    pub def put(state: st): LinesParser[Unit, st] =
        LinesParser((_, _) -> Ok(((), state)) as & Impure)

    pub def get(): LinesParser[st, st] =
        LinesParser((_, s) -> Ok((s, s)) as & Impure)

    pub def modify(fn: st -> st, p: LinesParser[a, st]): LinesParser[a, st] =
        LinesParser((r, s) -> apply1(p, r, fn(s)))

    pub def skipLine(): LinesParser[Unit, st] =
        use FactIO/Internal/LinesIterator.{readLine, hasNext};
        LinesParser((r, s) ->
            if (r.hasNext()) {
                let _ = r.readLine();
                Ok((), s)
            } else 
                Err(IllegalStateException) 
        )


    pub def skipLines(n: Int32): LinesParser[Unit, st] =
        if (n <= 0)
            return()
        else {
            let* _ = skipLine();
            skipLines(n - 1)
        }

    pub def line(x: LineEvaluator[a]): LinesParser[a, st] =
        use Result.flatMap;
        use FactIO/Internal/LinesIterator.{readLine, hasNext};
        LinesParser((r, s) ->
            if (r.hasNext()) {
                let LineEvaluator(f1) = x;
                let* str = r.readLine();
                let* ans = f1(str);
                Ok((ans, s))
            } else 
                Err(IllegalStateException) 
        )

    pub def atEnd(): LinesParser[Bool, st] =
        use FactIO/Internal/LinesIterator.{hasNext};
        LinesParser((r, s) ->
            let ans = r.hasNext();
            Ok((!ans, s))
        )

    pub def lines(x: LineEvaluator[a]): LinesParser[a, st] =
        linesHelper(x, #{ })

    pub def linesHelper(x: LineEvaluator[a], ac: a): LinesParser[a, st] =
        let* done = atEnd();
        if (done)
            return(ac)
        else { 
            let* a1 = line(x);
            linesHelper(x, ac <+> a1)
        }

    pub def count(n: Int32, x: LineEvaluator[a]): LinesParser[a, st] =
        countHelper(n, x, #{ })

    pub def countHelper(n: Int32, x: LineEvaluator[a], ac: a): LinesParser[a, st] =
        if (n <= 0)
            return(ac)
        else { 
            let* a1 = line(x);
            countHelper(n - 1, x, ac <+> a1)
        }

    pub def skipTill(x: LineEvaluator[a]): LinesParser[a, st] =
        let LineEvaluator(f1) = x;
        LinesParser((r, s) ->
            match skipTillHelper(f1, r) {
                case Ok(a) => Ok((a, s))
                case Err(e) => Err(e)
             }
        )


    def skipTillHelper(f1: String ~> Result[a, System.Error], s: LinesIterator): Result[a, System.Error] & Impure=
        use FactIO/Internal/LinesIterator.{readLine, hasNext};
        use Result.flatMap;
        if (s.hasNext()) {
            let* str = s.readLine();
            match f1(str) {
                case Ok(a) => Ok(a)
                case Err(_) => skipTillHelper(f1, s)
            }
        } else
            Err(IllegalStateException)


}