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


namespace FactIO/ImportStrategies {

    type alias RowResult[t] = Validation[t, String]

    type alias RowIterator[src,row] = { hasNext: src -> Bool & Impure , getRow: src -> row & Impure , finalize: src -> Unit & Impure }

    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def iterate(iterator: RowIterator[src, row], rowreader: row -> RowResult[reln] & e, source: src): Result[reln, String] & Impure =
        let failk = (n,msgs) -> FactIO/Internal/Base.collectErrors(n, msgs) |> Err;
        iterateHelper(iterator, rowreader, source, 0, failk, relns -> Ok(relns))

    ///
    /// Helper for `iterate`.
    ///
    def iterateHelper(iterator: RowIterator[src, row], rowreader: row -> RowResult[reln] & e, src: src, n: Int32, fk: (Int32, Nel[String]) -> Result[reln, String], sk: reln -> Result[reln, String]): Result[reln, String] & Impure =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(#{ })
        } else {
            let row = rowreader(getRow(src)) as & Impure;
            match Validation.toResult(row) {
                case Err(xs) => { finalize(src); fk(n, xs) }
                case Ok(x) => iterateHelper(iterator, rowreader, src, n+1, fk, relns -> sk(x <+> relns))
            }
        }

    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def iterateWithCount(iterator: RowIterator[src, row], rowreader: (row, Int32) -> RowResult[reln] & e, source: src): Result[reln, String] & Impure =
        let failk = (n,msgs) -> FactIO/Internal/Base.collectErrors(n, msgs) |> Err;
        iterateWithCountHelper(iterator, rowreader, source, 0, failk, relns -> Ok(relns))

    ///
    /// Helper for `iterateWithCount`.
    ///
    def iterateWithCountHelper(iterator: RowIterator[src, row], rowreader: (row, Int32) -> RowResult[reln] & e, src: src, n: Int32, fk: (Int32, Nel[String]) -> Result[reln, String], sk: rel -> Result[reln, String]): Result[reln, String] & Impure =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(#{ })
        } else {
            let row = rowreader(getRow(src), n) as & Impure;
            match Validation.toResult(row) {
                case Err(xs) => { finalize(src); fk(n, xs) }
                case Ok(x) => iterateWithCountHelper(iterator, rowreader, src, n+1, fk, relns -> sk(x <+> relns))
            }
        }

    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def iterateAccum(iterator: RowIterator[src, row], rowreader: (row, st) -> RowResult[(reln, st)] & e, state: st, source: src): Result[(reln, st), String] & Impure =
        let failk = (n,msgs) -> FactIO/Internal/Base.collectErrors(n, msgs) |> Err;
        iterateAccumHelper(iterator, rowreader, state, source, 0, failk, (relns, st) -> Ok(relns, st))

    ///
    /// Helper for `iterateWithCount`.
    ///
    def iterateAccumHelper(iterator: RowIterator[src, row], rowreader: (row, st) -> RowResult[(reln, st)] & e, state: st, src: src, n: Int32, fk: (Int32, Nel[String]) -> Result[(reln, st), String], sk: (reln, st) -> Result[(reln, st), String]): Result[(reln, st), String] & Impure =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(state, #{ })
        } else {
            let row = rowreader(getRow(src), state) as & Impure;
            match Validation.toResult(row) {
                case Err(xs) => { finalize(src); fk(n, xs) }
                case Ok(x, st1) => iterateAccumHelper(iterator, rowreader, st1, src, n+1, fk, (relns, st) -> sk(x <+> relns, st))
            }
        }

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def iterateAccumWithCount(iterator: RowIterator[src, row], rowreader: (row, st, Int32) -> RowResult[(reln, st)] & e, state: st, source: src): Result[(reln, st), String] & Impure =
        let failk = (n,msgs) -> FactIO/Internal/Base.collectErrors(n, msgs) |> Err;
        iterateAccumWithCountHelper(iterator, rowreader, state, source, 0, failk, (relns, st) -> Ok(relns, st))

    ///
    /// Helper for `iterateAccumWithCount`.
    ///
    def iterateAccumWithCountHelper(iterator: RowIterator[src, row], rowreader: (row, st, Int32) -> RowResult[(reln, st)] & e, state: st, src: src, n: Int32, fk: (Int32, Nel[String]) -> Result[(reln, st), String], sk: (reln, st) -> Result[(reln, st), String]): Result[(reln, st), String] & Impure =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(state, #{ })
        } else {
            let row = rowreader(getRow(src), state, n) as & Impure;
            match Validation.toResult(row) {
                case Err(xs) => { finalize(src); fk(n, xs) }
                case Ok(x, st1) => iterateAccumWithCountHelper(iterator, rowreader, st1, src, n+1, fk, (relns, st) -> sk(x <+> relns, st))
            }
        }

 }