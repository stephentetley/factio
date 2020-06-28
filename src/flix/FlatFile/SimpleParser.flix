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

use FactIO/FlatFile.SimpleParser;
use FactIO/FlatFile.SimpleParser.{SimpleParser};

use FactIO/FlatFile.LineEvaluator;
use FactIO/FlatFile.LineEvaluator.{LineEvaluator};
use FactIO/Internal.LinesIterator;
use FactIO/Internal.LinesIterator.{LinesIterator};

namespace FactIO/FlatFile {
    
    pub opaque type SimpleParser[a] = LinesIterator ~> Result[a, System.Error]

}

/// This is a combinator library for making custom line based text importers
/// it is not an "instance" of a text importer hence it is called Parser
/// rather than LinesImport.

/// Note - this is a very simplistic parser without the Alternative combinators - `alt` and `empty`
/// so it cannot support the nice repitition combinators like `many` and `manyTill`.
/// But it should be fast and use memory conservatively, so it is worth keeping even if a
/// we make a more expressive version.

namespace FactIO/FlatFile/SimpleParser {

    pub def runSimpleParser(x: SimpleParser[reln], path: String, cs: Text.Charset): Result[reln, System.Error] & Impure =
        use FactIO/Internal/LinesIterator.{close};
        match FactIO/Internal/LinesIterator.newLinesIterator(path, cs) {
            case Ok(iter) => { let ans = apply1(x, iter); close(iter); ans }
            case Err(e) => Err(e)
        }
        

    pub def return(x: a): SimpleParser[a] =
        SimpleParser(_ -> Ok(x) as & Impure)

    def apply1(x: SimpleParser[a], iter: LinesIterator): Result[a, System.Error] & Impure =
        let SimpleParser(f) = x;
        f(iter)

    pub def map(f: a -> b & e, x: SimpleParser[a]): SimpleParser[b] =
        SimpleParser(r ->
            match apply1(x, r) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )

    pub def ap(mf: SimpleParser[a -> b], ma: SimpleParser[a]): SimpleParser[b] =
        SimpleParser(r ->
            match apply1(mf, r) {
                case Ok(f) => {
                    match apply1(ma, r) {
                        case Ok(a) => { let x = f(a); Ok(x) }
                        case Err(e2) => Err(e2)
                    }
                }
                case Err(e1) => Err(e1)
            }
        )

    pub def bind(x: SimpleParser[a], k: a -> SimpleParser[b]): SimpleParser[b] =
        SimpleParser(r ->
            match apply1(x, r) {
                case Ok(a) => { let p1 = k(a); apply1(p1, r) }
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> SimpleParser[b], x: SimpleParser[a]): SimpleParser[b] = bind(x, k)

    pub def skipLine(): SimpleParser[Unit] =
        use FactIO/Internal/LinesIterator.{readLine, hasNext};
        SimpleParser(r ->
            if (r.hasNext()) {
                let _ = r.readLine();
                Ok()
            } else 
                Err(IllegalStateException) 
        )


    pub def skipLines(n: Int32): SimpleParser[Unit] =
        if (n <= 0)
            return()
        else {
            let* _ = skipLine();
            skipLines(n - 1)
        }

    pub def line(x: LineEvaluator[a]): SimpleParser[a] =
        use Result.flatMap;
        use FactIO/Internal/LinesIterator.{readLine, hasNext};
        SimpleParser(r ->
            if (r.hasNext()) {
                let LineEvaluator(f1) = x;
                let* str = r.readLine();
                let* ans = f1(str);
                Ok(ans)
            } else 
                Err(IllegalStateException) 
        )


    pub def countLines(n: Int32, x: LineEvaluator[a]): SimpleParser[a] =
        countLinesHelper(n, x, #{ })

    pub def countLinesHelper(n: Int32, x: LineEvaluator[a], ac: a): SimpleParser[a] =
        if (n <= 0)
            return(ac)
        else { 
            let* a1 = line(x);
            countLinesHelper(n - 1, x, ac <+> a1)
        }

    pub def skipLinesTill(x: LineEvaluator[a]): SimpleParser[a] =
        let LineEvaluator(f1) = x;
        SimpleParser(r -> skipLinesTillHelper(f1, r))


    def skipLinesTillHelper(f1: String ~> Result[a, System.Error], r: LinesIterator): Result[a, System.Error] & Impure=
        use FactIO/Internal/LinesIterator.{readLine, hasNext};
        use Result.flatMap;
        if (r.hasNext()) {
            let* str = r.readLine();
            match f1(str) {
                case Ok(a) => Ok(a)
                case Err(_) => skipLinesTillHelper(f1, r)
            }
        } else
            Err(IllegalStateException)


    pub def linesTill(x: LineEvaluator[a], end: LineEvaluator[end]): SimpleParser[a] =
        let LineEvaluator(f1) = x;
        let LineEvaluator(f2) = end;
        SimpleParser(r -> linesTillHelper(f1, f2, r, #{ }))


    def linesTillHelper(f1: String ~> Result[a, System.Error], f2: String ~> Result[b, System.Error], r: LinesIterator, ac: a): Result[a, System.Error] & Impure=
        use FactIO/Internal/LinesIterator.{readLine, hasNext};
        use Result.flatMap;
        if (r.hasNext()) {
            let* str = r.readLine();
            match f2(str) {
                case Ok(_) => Ok(ac)
                case Err(_) => match f1(str) {
                    case Ok(a) => linesTillHelper(f1, f2, r, a <+> ac)
                    case Err(e) => Err(e)
                }
            }
        } else
            Err(IllegalStateException)


    pub def linesTillEnd(x: LineEvaluator[a]): SimpleParser[a] =
        let LineEvaluator(f1) = x;
        SimpleParser(r -> linesTillEndHelper(f1, r, #{ }))


    def linesTillEndHelper(f1: String ~> Result[a, System.Error], r: LinesIterator, ac: a): Result[a, System.Error] & Impure=
        use FactIO/Internal/LinesIterator.{readLine, hasNext};
        use Result.flatMap;
        if (r.hasNext()) {
            let* str = r.readLine();
            match f1(str) {
                case Ok(a) => linesTillEndHelper(f1, r, ac <+> a)
                case Err(e) => Err(e)
            }
        } else
            Ok(ac)

}