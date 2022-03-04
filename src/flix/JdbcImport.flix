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
    pub def newDbCursor(sql: {sql :: String}, url: String): Cursor[String, JdbcRow] & Impure =
        import new flix.runtime.spt.factio.jdbc.JdbcCursor(String, String): ##flix.runtime.spt.factio.jdbc.JdbcCursor & Impure as newJdbcCursor;
        import flix.runtime.spt.factio.jdbc.JdbcCursor.goNext(): Bool & Impure;
        import flix.runtime.spt.factio.jdbc.JdbcCursor.getRow(): ##flix.runtime.spt.factio.jdbc.JdbcRow& Impure;
        import flix.runtime.spt.factio.jdbc.JdbcCursor.close(): Unit & Impure;
        try {
            let iter = newJdbcCursor(url, sql.sql);
            let cursorIter =  {
                  hasNext = () -> goNext(iter)
                , next = X/Cursor.guardThunk(_ -> getRow(iter), "next failed")
                , finalize = () -> close(iter)
            };
            X/Cursor.makeCursor(cursorIter)
        } catch {
            case _: ##java.lang.Exception => X/Cursor.failure("newDbStream")
        }

    ///
    /// Returns a new SQLite Cursor.
    ///
    pub def newSQLiteCursor(sql: {sql :: String}, path: System.FilePath): Cursor[String, JdbcRow] & Impure =
        newDbCursor(sql, "jdbc:sqlite:${path}")

    ///
    /// Returns a new DuckDB Cursor.
    ///
    pub def newDuckDBCursor(sql: {sql :: String}, path: System.FilePath): Cursor[String, JdbcRow] & Impure =
        newDbCursor(sql, "jdbc:duckdb:${path}")

    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRows(eval: JdbcRowEvaluator[#{| reln}],
                       iter: Cursor[String, JdbcRow]): Result[#{| reln}, String] & Impure =
        let JdbcRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.importRows(mf, iter)

    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount!(eval: Int32 -> JdbcRowEvaluator[#{| reln}],
                                iter: Cursor[String, JdbcRow]): Result[#{| reln}, String] & Impure =
        let mf = (row, ix) -> { let JdbcRowEvaluator(r1) = eval(ix); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCount(mf, iter)

    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum!(eval: st -> JdbcRowEvaluator[(#{| reln}, st)],
                                state: st,
                                iter: Cursor[String, JdbcRow]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, st) -> { let JdbcRowEvaluator(r1) = eval(st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithAccum(mf, state, iter)

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum!(eval: (Int32, st) -> JdbcRowEvaluator[(#{| reln}, st)],
                                        state: st,
                                        iter: Cursor[String, JdbcRow]): Result[(#{| reln}, st), String] & Impure =
        let mf = (row, ix, st) -> { let JdbcRowEvaluator(r1) = eval(ix, st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCountAndAccum(mf, state, iter)

    ///
    /// Returns a list of applying `eval` to all rows in the input stream `src`.
    ///
    pub def evaluateRows(eval: JdbcRowEvaluator[a],
                          iter: Cursor[String, JdbcRow]): Result[List[a], String] & Impure =
        let JdbcRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.getRows(mf, iter)

}
