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

use Data.Stream;
use System.Error.{IOException, Generic};

use FactIO.JdbcRowEvaluator;
use FactIO.JdbcRowEvaluator.{JdbcRowEvaluator};

namespace FactIO/JdbcImport {

    ///
    /// Represents a database row.
    ///
    type alias JdbcRow = ##flix.runtime.spt.factio.jdbc.JdbcRow

    ///
    /// Returns a new Jdbc Stream.
    ///
    pub def newDbStream(url: String, query: String): Result[Stream[JdbcRow], System.Error] & Impure =
        import new flix.runtime.spt.factio.jdbc.JdbcIterator(String, String) as newJdbcIterator;
        import flix.runtime.spt.factio.jdbc.JdbcIterator.next() as ffiHasNext;
        import flix.runtime.spt.factio.jdbc.JdbcIterator.getRow() as ffiNext;
        import flix.runtime.spt.factio.jdbc.JdbcIterator.close() as ffiClose;
        try {
            let iter = newJdbcIterator(url, query);
            let streamiter =  {
                  hasNext = () -> ffiHasNext(iter)
                , next = () -> ffiNext(iter)
                , finalize = () -> ffiClose(iter)
            };
            Ok(Data/Stream.fromIterator(streamiter))
        } catch {
            case _: ##java.io.FileNotFoundException => Err(IOException)
            case _: ##java.io.IOException => Err(IOException)
        }

    ///
    /// Returns a new SQLite Stream.
    ///
    pub def newSQLiteStream(filepath: System.FilePath,
                            query: String): Result[Stream[JdbcRow], System.Error] & Impure =
        use System/FilePath.{toString};
        let url = "jdbc:sqlite:" + filepath.toString();
        newDbStream(url, query)

    ///
    /// Returns a new DuckDB Stream.
    ///
    pub def newDuckDBStream(filepath: System.FilePath,
                            query: String): Result[Stream[JdbcRow], System.Error] & Impure =
        use System/FilePath.{toString};
        let url = "jdbc:duckdb:" + filepath.toString();
        newDbStream(url, query)

    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRows(eval: JdbcRowEvaluator[#{| reln}],
                       src: Stream[JdbcRow]): Result[#{| reln}, System.Error] & Impure =
        let JdbcRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.importRows(mf, src)

    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount(eval: Int32 -> JdbcRowEvaluator[#{| reln}],
                                src: Stream[JdbcRow]): Result[#{| reln}, System.Error] & Impure =
        let mf = (row, ix) -> { let JdbcRowEvaluator(r1) = eval(ix); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCount(mf, src)

    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum(eval: st -> JdbcRowEvaluator[(#{| reln}, st)],
                                state: st,
                                src: Stream[JdbcRow]): Result[(#{| reln}, st), System.Error] & Impure =
        let mf = (row, st) -> { let JdbcRowEvaluator(r1) = eval(st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithAccum(mf, state, src)

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum(eval: (Int32, st) -> JdbcRowEvaluator[(#{| reln}, st)],
                                        state: st,
                                        src: Stream[JdbcRow]): Result[(#{| reln}, st), System.Error] & Impure =
        let mf = (row, ix, st) -> { let JdbcRowEvaluator(r1) = eval(ix, st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCountAndAccum(mf, state, src)

    ///
    /// Returns a list of applying `eval` to all rows in the input stream `src`.
    ///
    pub def evaluateRows(eval: JdbcRowEvaluator[a],
                         src: Stream[JdbcRow]): Result[List[a], System.Error] & Impure =
        let JdbcRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.getRows(mf, src)


}