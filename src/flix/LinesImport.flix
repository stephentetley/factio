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

use FactIO.Error.{Generic};

namespace FactIO/LinesImport {

    ///
    /// Represents a line of text (a String).
    ///
    pub opaque type TextLine = String


    type alias LineResult[t] = Result[t, FactIO.Error]



    ///
    /// Returns a new string line Stream.
    ///
    pub def newLinesStream(filepath: String, cs: Text.Charset): Result[Stream[TextLine], FactIO.Error] & Impure=
        import new flix.runtime.factio.LinesIterator(String, ##java.nio.charset.Charset) as newLinesIterator;
        import flix.runtime.factio.LinesIterator.hasNext() as ffiHasNext;
        import flix.runtime.factio.LinesIterator.getLine() as ffiNext;
        import flix.runtime.factio.LinesIterator.close() as ffiClose;
        try {
            let Charset(cs1) = cs;
            let iter = newLinesIterator(filepath, cs1);
            let streamiter =  {
                  hasNext = () -> ffiHasNext(iter)
                , next = () -> { let a = ffiNext(iter); TextLine(a) }
                , finalize = () -> ffiClose(iter)
            };
            Ok(Stream.fromIterator(streamiter))
        } catch {
            case _: ##java.io.FileNotFoundException => Err(Generic("newLinesStream - file not found"))
            case _: ##java.io.IOException => Err(Generic("newLinesStream - io exception"))
        }


    ///
    /// Process all lines of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a line can generate zero, one or many facts.
    ///
    pub def importRows(rowreader: TextLine -> LineResult[reln] & Impure, src: Stream[TextLine]): Result[reln, FactIO.Error] & Impure =
        FactIO/ImportStrategies.importRows(rowreader, src)

    ///
    /// Process all lines of the input with a zero indexed line count.
    ///
    /// Note - a `relation` is naturally monoidal - a line can generate zero, one or many facts.
    ///
    pub def importRowsWithCount(rowreader: (TextLine, Int32) -> LineResult[reln] & Impure, src: Stream[TextLine]): Result[reln, FactIO.Error] & Impure =
        FactIO/ImportStrategies.importRowsWithCount(rowreader, src)

    ///
    /// Process all line of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a line can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum(rowreader: (TextLine, st) -> LineResult[(reln, st)] & Impure, state: st, src: Stream[TextLine]): Result[(reln, st), FactIO.Error] & Impure =    
        FactIO/ImportStrategies.importRowsWithAccum(rowreader, state, src)

    ///
    /// Process all line of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a line can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum(rowreader: (TextLine, st, Int32) -> LineResult[(reln, st)] & Impure, state: st, src: Stream[TextLine]): Result[(reln, st), FactIO.Error] & Impure =
        FactIO/ImportStrategies.importRowsWithCountAndAccum(rowreader, state, src)


    /// Line readers

    pub def nonempty(line: TextLine): LineResult[String] =
        let TextLine(s) = line;
        if (String.length(s) > 0) Ok(s) else Err(Generic("nonempty"))

    pub def apply(f: String -> a & e, line: TextLine): LineResult[a] & e =
        let TextLine(s) = line;
        Ok(f(s))

    pub def applyRes(f: String -> Result[a, FactIO.Error] & e, line: TextLine): LineResult[a] & e=
        let TextLine(s) = line;
        f(s)

}