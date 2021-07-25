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


namespace FactIO/JdbcImport {

    use X.Cursor;
    use X.Cursor.{Cursor};
    use FactIO.JdbcRowEvaluator;
    use FactIO.JdbcRowEvaluator.{JdbcRowEvaluator};

    ///
    /// Represents a database row.
    ///
    type alias JdbcRow = ##flix.runtime.spt.factio.jdbc.JdbcRow

    pub opaque type JdbcReadHandle[a] = (##flix.runtime.spt.factio.jdbc.JdbcCursor, Iterator[Result[a, String]])

    pub def close(handle: JdbcReadHandle[a]): Result[Unit, String] & Impure =
        import flix.runtime.spt.factio.jdbc.JdbcCursor.close();
        let JdbcReadHandle((x1, _)) = handle;
        try {
            close(x1);
            Ok()
        } catch {
            case _: ##java.lang.Exception => Err("close")
        }

    pub def getIterator(handle: JdbcReadHandle[a]): Iterator[Result[a, String]] =
        let JdbcReadHandle((_, i1)) = handle;
        i1


    ///
    /// Returns a new JdbcReadHandle.
    ///
    /// Warning: Currently this does not return a proper iterator (Next is flawed).
    /// Use with caution.
    ///
    pub def newJdbcReadHandle(url: String, query: String): Result[JdbcReadHandle[JdbcRow], String] & Impure =
        import new flix.runtime.spt.factio.jdbc.JdbcCursor(String, String) as newJdbcCursor;
        import flix.runtime.spt.factio.jdbc.JdbcCursor.goNext();
        import flix.runtime.spt.factio.jdbc.JdbcCursor.getRow();
        try {
            let primIter = newJdbcCursor(url, query);
            let iterDone = () -> if (goNext(primIter)) false else true;
            let iterNext = () -> {
                try {
                    Ok(getRow(primIter))
                } catch {
                    case _: ##java.lang.Exception => Err("jdbcReadIter[next]")
                }
            };
            let iter1 = Iterator(iterDone, iterNext);
            let hdl = JdbcReadHandle((primIter, iter1));
            Ok(hdl)
        } catch {
            case _: ##java.lang.Exception => Err("newJdbcReadHandle")
        }

    ///
    /// Returns a new SQLite JdbcReadHandle.
    ///
    pub def newSQLiteReadHandle(filepath: System.FilePath,
                                query: String): Result[JdbcReadHandle[JdbcRow], String] & Impure =
        newJdbcReadHandle("jdbc:sqlite:${filepath}", query)

    ///
    /// Returns a new DuckDB JdbcReadHandle.
    ///
    pub def newDuckDBReadHandle(filepath: System.FilePath,
                                query: String): Result[JdbcReadHandle[JdbcRow], String] & Impure =
        newJdbcReadHandle("jdbc:duckdb:${filepath}", query)

    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRows(eval: JdbcRowEvaluator[#{| reln}],
                       iter: Iterator[Result[JdbcRow, String]]): Result[#{| reln}, String] & Impure =
        let JdbcRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.importRows(mf, iter)

    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount!(eval: Int32 -> JdbcRowEvaluator[#{| reln}],
                                iter: Iterator[Result[JdbcRow, String]]): Result[#{| reln}, String] & Impure =
        let mf = (row, ix) -> { let JdbcRowEvaluator(r1) = eval(ix); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCount(mf, iter)

    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum!(eval: st -> JdbcRowEvaluator[(#{| reln}, st)],
                                state: st,
                                iter: Iterator[Result[JdbcRow, String]]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, st) -> { let JdbcRowEvaluator(r1) = eval(st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithAccum(mf, state, iter)

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum!(eval: (Int32, st) -> JdbcRowEvaluator[(#{| reln}, st)],
                                        state: st,
                                        iter: Iterator[Result[JdbcRow, String]]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, ix, st) -> { let JdbcRowEvaluator(r1) = eval(ix, st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCountAndAccum(mf, state, iter)

    ///
    /// Returns a list of applying `eval` to all rows in the input stream `src`.
    ///
    pub def evaluateRows(eval: JdbcRowEvaluator[a],
                          iter: Iterator[Result[JdbcRow, String]]): Result[List[a], String] & Impure =
        let JdbcRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.getRows(mf, iter)

}
