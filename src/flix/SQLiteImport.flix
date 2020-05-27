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

use System.Error.{IOException, Generic};

use FactIO.SQLiteRowEvaluator;
use FactIO.SQLiteRowEvaluator.{SQLiteRowEvaluator};

namespace FactIO/SQLiteImport {

    ///
    /// Represents a SQLite row.
    ///
    type alias SQLiteRow = ##flix.runtime.spt.factio.SQLiteRow

    ///
    /// Returns a new SQLite Stream.
    ///
    pub def newSQLiteStream(filepath: String, query: String): Result[Stream[SQLiteRow], System.Error] & Impure=
        import new flix.runtime.spt.factio.SQLiteIterator(String, String) as newSQLiteIterator;
        import flix.runtime.spt.factio.SQLiteIterator.next() as ffiHasNext;
        import flix.runtime.spt.factio.SQLiteIterator.getRow() as ffiNext;
        import flix.runtime.spt.factio.SQLiteIterator.close() as ffiClose;
        try {
            let iter = newSQLiteIterator(filepath, query);
            let streamiter =  {
                  hasNext = () -> ffiHasNext(iter)
                , next = () -> ffiNext(iter)
                , finalize = () -> ffiClose(iter)
            };
            Ok(Stream.fromIterator(streamiter))
        } catch {
            case _: ##java.io.FileNotFoundException => Err(IOException)
            case _: ##java.io.IOException => Err(IOException)
        }

    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRows(eval: SQLiteRowEvaluator[reln], src: Stream[SQLiteRow]): Result[reln, System.Error] & Impure =
        let SQLiteRowEvaluator(mf) = eval;
        FactIO/Internal/ImportStrategies.importRows(mf, src)

    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount(eval: Int32 -> SQLiteRowEvaluator[reln], src: Stream[SQLiteRow]): Result[reln, System.Error] & Impure =
        let mf = (row, ix) -> { let SQLiteRowEvaluator(r1) = eval(ix); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCount(mf, src)

    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum(eval: st -> SQLiteRowEvaluator[(reln, st)], state: st, src: Stream[SQLiteRow]): Result[(reln, st), System.Error] & Impure =
        let mf = (row, st) -> { let SQLiteRowEvaluator(r1) = eval(st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithAccum(mf, state, src)

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum(eval: (Int32, st) -> SQLiteRowEvaluator[(reln, st)], state: st, src: Stream[SQLiteRow]): Result[(reln, st), System.Error] & Impure =
        let mf = (row, ix, st) -> { let SQLiteRowEvaluator(r1) = eval(ix, st); r1(row) };
        FactIO/Internal/ImportStrategies.importRowsWithCountAndAccum(mf, state, src)


}