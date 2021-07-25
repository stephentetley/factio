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

    ///
    /// Returns a new Jdbc Cursor.
    ///
    pub def newDbCursor(url: String, query: String): Cursor[String, JdbcRow] & Impure =
        import new flix.runtime.spt.factio.jdbc.JdbcCursor(String, String) as newJdbcCursor;
        import flix.runtime.spt.factio.jdbc.JdbcCursor.next() as ffiHasNext;
        import flix.runtime.spt.factio.jdbc.JdbcCursor.getRow() as ffiNext;
        import flix.runtime.spt.factio.jdbc.JdbcCursor.close() as ffiClose;
        try {
            let iter = newJdbcCursor(url, query);
            let cursorIter =  {
                  hasNext = () -> ffiHasNext(iter)
                , next = X/Cursor.guardThunk(_ -> ffiNext(iter), "next failed")
                , finalize = () -> ffiClose(iter)
            };
            X/Cursor.makeCursor(cursorIter)
        } catch {
            case _: ##java.lang.Exception => X/Cursor.failure("newDbStream")
        }

    ///
    /// Returns a new SQLite Cursor.
    ///
    pub def newSQLiteCursor(filepath: System.FilePath,
                            query: String): Cursor[String, JdbcRow] & Impure =
        newDbCursor("jdbc:sqlite:${filepath}", query)

    ///
    /// Returns a new DuckDB Cursor.
    ///
    pub def newDuckDBCursor(filepath: System.FilePath,
                            query: String): Cursor[String, JdbcRow] & Impure =
        newDbCursor("jdbc:duckdb:${filepath}", query)

    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRows!(eval: JdbcRowEvaluator[#{| reln}],
                       src: Cursor[String, JdbcRow]): Result[#{| reln}, String] & Impure =
        let JdbcRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.importRows!(mf, src)

    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount!(eval: Int32 -> JdbcRowEvaluator[#{| reln}],
                                src: Cursor[String, JdbcRow]): Result[#{| reln}, String] & Impure =
        let mf = (row, ix) -> { let JdbcRowEvaluator(r1) = eval(ix); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCount!(mf, src)

    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum!(eval: st -> JdbcRowEvaluator[(#{| reln}, st)],
                                state: st,
                                src: Cursor[String, JdbcRow]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, st) -> { let JdbcRowEvaluator(r1) = eval(st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithAccum!(mf, state, src)

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum!(eval: (Int32, st) -> JdbcRowEvaluator[(#{| reln}, st)],
                                        state: st,
                                        src: Cursor[String, JdbcRow]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, ix, st) -> { let JdbcRowEvaluator(r1) = eval(ix, st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCountAndAccum!(mf, state, src)

    ///
    /// Returns a list of applying `eval` to all rows in the input stream `src`.
    ///
    pub def evaluateRows!(eval: JdbcRowEvaluator[a],
                          src: Cursor[String, JdbcRow]): Result[List[a], String] & Impure =
        let JdbcRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.getRows!(mf, src)

}
