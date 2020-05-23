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

use FactIO.LinesImporter;
use FactIO.LinesImporter.{LinesImporter};

use FactIO.LineEvaluator;
use FactIO.LineEvaluator.{LineEvaluator};
use FactIO/Internal.LinesIterator;
use FactIO/Internal.LinesIterator.{LinesIterator};

namespace FactIO { 
    
    pub opaque type LinesImporter[a] = LinesIterator ~> Result[a, System.Error]

}


namespace FactIO/LinesImporter {

    pub def runLinesImporter(x: LinesImporter[reln], path: String, cs: Text.Charset): Result[reln, System.Error] & Impure = 
        use Result.flatMap;
        use FactIO/Internal/LinesIterator.{close};
        let* src = FactIO/Internal/LinesIterator.newLinesIterator(path, cs);
        match apply1(x, src) { 
            case Ok(a) => { let _ = close(src); Ok(a) }
            case Err(e) => { let _ = close(src); Err(e) }
        }
        

    pub def return(x: a): LinesImporter[a] = 
        LinesImporter(_ -> Ok(x) as & Impure)

    def apply1(x: LinesImporter[a], r: LinesIterator): Result[a, System.Error] & Impure =
        let LinesImporter(f) = x;
        f(r)

    pub def map(f: a -> b & e, x: LinesImporter[a]): LinesImporter[b] =
        LinesImporter(s -> 
            match apply1(x, s) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )

    pub def ap(mf: LinesImporter[a -> b], ma: LinesImporter[a]): LinesImporter[b] =
        LinesImporter(s -> 
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

    pub def bind(x: LinesImporter[a], k: a -> LinesImporter[b]): LinesImporter[b] = 
        LinesImporter(s -> 
            match apply1(x, s) { 
                case Ok(a) => apply1(k(a), s)
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> LinesImporter[b], x: LinesImporter[a]): LinesImporter[b] = bind(x, k)

    pub def skipLine(): LinesImporter[Unit] = 
        use FactIO/Internal/LinesIterator.{readLine, hasNext};
        LinesImporter(s ->
            if (s.hasNext()) {
                let _ = s.readLine();
                Ok()
            } else 
                Err(IllegalStateException) 
        )


    pub def skipLines(n: Int32): LinesImporter[Unit] = 
        if (n <= 0)
            return()
        else {
            let _ = skipLine();
            skipLines(n - 1)
        }

    pub def line(x: LineEvaluator[a]): LinesImporter[a] = 
        use Result.flatMap;
        use FactIO/Internal/LinesIterator.{readLine, hasNext};
        LinesImporter(s ->
            if (s.hasNext()) {
                let LineEvaluator(f1) = x;
                let* str = s.readLine();
                f1(str)
            } else 
                Err(IllegalStateException) 
        )

    pub def atEnd(): LinesImporter[Bool] = 
        use FactIO/Internal/LinesIterator.{hasNext};
        LinesImporter(s ->
            let ans = s.hasNext();
            Ok(!ans)
        )

    pub def lines(x: LineEvaluator[a]): LinesImporter[a] = 
        linesHelper(x, #{ })

    pub def linesHelper(x: LineEvaluator[a], ac: a): LinesImporter[a] = 
        let* done = atEnd();
        if (done)
            return(ac)
        else { 
            let* a1 = line(x);
            linesHelper(x, ac <+> a1)
        }

    pub def count(n: Int32, x: LineEvaluator[a]): LinesImporter[a] = 
        countHelper(n, x, #{ })

    pub def countHelper(n: Int32, x: LineEvaluator[a], ac: a): LinesImporter[a] =         
        if (n <= 0)
            return(ac)
        else { 
            let* a1 = line(x);
            countHelper(n - 1, x, ac <+> a1)
        }



}