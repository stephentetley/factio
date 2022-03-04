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


namespace FactIO/FlatFileImport {

    use X.Cursor;
    use X.Cursor.{Cursor};
    use System.FilePath.{FilePath};
    use Text.Charset.{Charset};

    use FactIO.FlatFileLineEvaluator;
    use FactIO.FlatFileLineEvaluator.{FlatFileLineEvaluator};

    ///
    /// Returns a new Flat File Stream.
    ///
    pub def newFlatFileCursor(cs: Text.Charset, path: System.FilePath): Cursor[String, String] & Impure =
        import new flix.runtime.spt.factio.flatfile.LinesCursor(##java.nio.file.Path, ##java.nio.charset.Charset): ##flix.runtime.spt.factio.flatfile.LinesCursor & Impure as newLinesCursor;
        import flix.runtime.spt.factio.flatfile.LinesCursor.hasNext(): Bool & Impure;
        import flix.runtime.spt.factio.flatfile.LinesCursor.next(): String & Impure;
        import flix.runtime.spt.factio.flatfile.LinesCursor.close(): Unit & Impure;
        try {
            let FilePath(path1) = path;
            let Charset(cs1) = cs;
            let iter = newLinesCursor(path1, cs1);
            let cursorIter =  {
                  hasNext = () -> hasNext(iter)
                , next = X/Cursor.guardThunk(_ -> next(iter), "next failed")
                , finalize = () -> close(iter)
            };
            X/Cursor.makeCursor(cursorIter)
        } catch {
            case _: ##java.lang.Exception => X/Cursor.failure("newFlatFileCursor")
        }

    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRows(eval: FlatFileLineEvaluator[#{| reln}],
                        iter: Cursor[String, String]): Result[#{| reln}, String] & Impure =
        let FlatFileLineEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.importRows(mf, iter)

    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount!(eval: Int32 -> FlatFileLineEvaluator[#{| reln}],
                                iter: Cursor[String, String]): Result[#{| reln}, String] & Impure =
        let mf = (row, ix) -> { let FlatFileLineEvaluator(r1) = eval(ix); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCount(mf, iter)

    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum(eval: st -> FlatFileLineEvaluator[(#{| reln}, st)],
                                state: st,
                                iter: Cursor[String, String]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, st) -> { let FlatFileLineEvaluator(r1) = eval(st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithAccum(mf, state, iter)

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum(eval: (Int32, st) -> FlatFileLineEvaluator[(#{| reln}, st)],
                                        state: st,
                                        iter: Cursor[String, String]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, ix, st) -> { let FlatFileLineEvaluator(r1) = eval(ix, st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCountAndAccum(mf, state, iter)

    ///
    /// Returns a list of applying `eval` to all rows in the input stream `src`.
    ///
    pub def evaluateRows(eval: FlatFileLineEvaluator[a],
                         iter: Cursor[String, String]): Result[List[a], String] & Impure =
        let FlatFileLineEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.getRows(mf, iter)

}
