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

    use System.FilePath.{FilePath};
    use Text.Charset.{Charset};

    use FactIO.FlatFileLineEvaluator;
    use FactIO.FlatFileLineEvaluator.{FlatFileLineEvaluator};

    pub opaque type FlatFileReadHandle[a] = (##flix.runtime.spt.factio.flatfile.LinesCursor, Iterator[Result[a, String]])

    pub def close(handle: FlatFileReadHandle[a]): Result[Unit, String] & Impure =
        import flix.runtime.spt.factio.flatfile.LinesCursor.close();
        let FlatFileReadHandle((x1, _)) = handle;
        try {
            close(x1);
            Ok()
        } catch {
            case _: ##java.lang.Exception => Err("close")
        }

    pub def getIterator(handle: FlatFileReadHandle[a]): Iterator[Result[a, String]] =
        let FlatFileReadHandle((_, i1)) = handle;
        i1


    ///
    /// Returns a new Flat File Stream.
    ///
    pub def newFlatFileReadHandle(path: System.FilePath,
                              cs: Text.Charset): Result[FlatFileReadHandle[String], String] & Impure =
        import new flix.runtime.spt.factio.flatfile.LinesCursor(##java.nio.file.Path, ##java.nio.charset.Charset) as newLinesCursor;
        import flix.runtime.spt.factio.flatfile.LinesCursor.hasNext();
        import flix.runtime.spt.factio.flatfile.LinesCursor.next();
        try {
            let FilePath(path1) = path;
            let Charset(cs1) = cs;
            let primIter = newLinesCursor(path1, cs1);
            let iterDone = () -> if (hasNext(primIter)) false else true;
            let iterNext = () -> {
                try {
                    Ok(next(primIter))
                } catch {
                    case _: ##java.lang.Exception => Err("flatFileReadIter[next]")
                }
            };
            let iter1 = Iterator(iterDone, iterNext);
            let hdl = FlatFileReadHandle((primIter, iter1));
            Ok(hdl)
        } catch {
            case _: ##java.lang.Exception => Err("newFlatFileReadHandle")
        }

    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRows(eval: FlatFileLineEvaluator[#{| reln}],
                        iter: Iterator[Result[String, String]]): Result[#{| reln}, String] & Impure =
        let FlatFileLineEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.importRows(mf, iter)

    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount!(eval: Int32 -> FlatFileLineEvaluator[#{| reln}],
                                iter: Iterator[Result[String, String]]): Result[#{| reln}, String] & Impure =
        let mf = (row, ix) -> { let FlatFileLineEvaluator(r1) = eval(ix); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCount(mf, iter)

    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum(eval: st -> FlatFileLineEvaluator[(#{| reln}, st)],
                                state: st,
                                iter: Iterator[Result[String, String]]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, st) -> { let FlatFileLineEvaluator(r1) = eval(st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithAccum(mf, state, iter)

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum(eval: (Int32, st) -> FlatFileLineEvaluator[(#{| reln}, st)],
                                        state: st,
                                        iter: Iterator[Result[String, String]]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, ix, st) -> { let FlatFileLineEvaluator(r1) = eval(ix, st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCountAndAccum(mf, state, iter)

    ///
    /// Returns a list of applying `eval` to all rows in the input stream `src`.
    ///
    pub def evaluateRows(eval: FlatFileLineEvaluator[a],
                         iter: Iterator[Result[String, String]]): Result[List[a], String] & Impure =
        let FlatFileLineEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.getRows(mf, iter)

}
