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

///
/// Represents a line of text (a String).
///
opaque type TextLine = String


///
/// Represents a source of text lines (internally an iterator on a text file).
///
opaque type LinesSource = ##flix.runtime.factio.LinesIterator

type alias LineResult[t] = Validation[t, String]

namespace LinesImport {

    ///
    /// TODO - use Flix's paths...
    ///
    pub def newLinesSource(filepath: String, cs: Charset): Result[LinesSource, String] & Impure =
        try {
            import new flix.runtime.factio.LinesIterator(String, ##java.nio.charset.Charset) as newLinesIterator;
            let Charset(cs1) = cs;
            let iterator = newLinesIterator(filepath, cs1);
            LinesSource(iterator) |> Ok
        } catch {
            case _: ##java.io.FileNotFoundException => Err("newTextLineSource - file not found")
            case _: ##java.io.IOException => Err("newTextLineSource - io exception")
        }

    def hasNext(src: LinesSource): Bool & Impure =
        let LinesSource(iterator) = src;
        import flix.runtime.factio.LinesIterator.hasNext();
        iterator.hasNext()

    def getLine(src: LinesSource): TextLine & Impure =
        let LinesSource(iterator) = src;
        import flix.runtime.factio.LinesIterator.getLine();
        let line = iterator.getLine();
        TextLine(line)

    def finalize(src: LinesSource): Unit & Impure =
        let LinesSource(iterator) = src;
        import flix.runtime.factio.LinesIterator.close();
        iterator.close()


    def makeLinesIterator(): RowIterator[LinesSource, TextLine] =
        { hasNext = hasNext,  getRow = getLine, finalize = finalize }

    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def iterate(f: TextLine -> LineResult[reln] & e, src: LinesSource): Result[reln, String] & Impure =
        let iterator = makeLinesIterator();
        Strategies.iterate(iterator, f, src)

    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def iterateWithCount(f: (TextLine, Int32) -> LineResult[reln] & e, src: LinesSource): Result[reln, String] & Impure =
        let iterator = makeLinesIterator();
        Strategies.iterateWithCount(iterator, f, src)

    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def iterateAccum(f: (TextLine, st) -> LineResult[(reln, st)] & e, state: st, src: LinesSource): Result[(reln, st), String] & Impure =
        let iterator = makeLinesIterator();
        Strategies.iterateAccum(iterator, f, state, src)

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def iterateAccumWithCount(f: (TextLine, st, Int32) -> LineResult[(reln, st)] & e, state: st, src: LinesSource): Result[(reln, st), String] & Impure =
        let iterator = makeLinesIterator();
        Strategies.iterateAccumWithCount(iterator, f, state, src)


    /// Line readers

    pub def nonempty(line: TextLine): LineResult[String] =
        let TextLine(s) = line;
        if (String.length(s) > 0) Success(s) else ValidationExtras.error("nonempty")

    pub def apply(f: String -> a & e, line: TextLine): LineResult[a] & e=
        let TextLine(s) = line;
        Success(f(s))

    pub def applyRes(f: String -> Result[a, String] & e, line: TextLine): LineResult[a] & e=
        let TextLine(s) = line;
        match f(s) {
            case Ok(a) => Success(a)
            case Err(msg) => ValidationExtras.error(msg)
        }
}