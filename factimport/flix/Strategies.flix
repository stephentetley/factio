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

type alias RowResult[t] = Validation[t, String]

type alias RowIterator[src,row] = { hasNext: src -> Bool, getRow: src -> row, finalize: src -> Unit }

namespace Strategies {

    pub def collect(iterator: RowIterator[src, row], rowreader: row -> RowResult[reln], source: src): Result[reln, String] =
        let failk = (n,msgs) -> ImportBase.collectErrors(n, msgs) |> Err;
        collectHelper(iterator, rowreader, source, 0, failk, relns -> Ok(relns))

    def collectHelper(iterator: RowIterator[src, row], rowreader: row -> RowResult[reln], src: src, n: Int32, fk: (Int32, List[String]) -> Result[reln, String], sk: reln -> Result[reln, String]): Result[reln, String] =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(#{ })
        } else {
            match getRow(src) |> (Validation.validate << rowreader) {
                case Err(xs) => { finalize(src); fk(n, xs) }
                case Ok(x) => collectHelper(iterator, rowreader, src, n+1, fk, relns -> sk(x <+> relns))
            }
        }

    pub def collectWithCount(iterator: RowIterator[src, row], rowreader: (row, Int32) -> RowResult[reln], source: src): Result[reln, String] =
        let failk = (n,msgs) -> ImportBase.collectErrors(n, msgs) |> Err;
        collectWithCountHelper(iterator, rowreader, source, 0, failk, relns -> Ok(relns))

    def collectWithCountHelper(iterator: RowIterator[src, row], f: (row, Int32) -> RowResult[reln], src: src, n: Int32, fk: (Int32, List[String]) -> Result[reln, String], sk: rel -> Result[reln, String]): Result[reln, String] =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(#{ })
        } else {
            let row = getRow(src);
            match Validation.validate(f(row, n)) {
                case Err(xs) => { finalize(src); fk(n, xs) }
                case Ok(x) => collectWithCountHelper(iterator, f, src, n+1, fk, relns -> sk(x <+> relns))
            }
        }

    pub def collectAccum(iterator: RowIterator[src, row], rowreader: (row, st) -> RowResult[(reln, st)], state: st, source: src): Result[(reln, st), String] =
        let failk = (n,msgs) -> ImportBase.collectErrors(n, msgs) |> Err;
        collectAccumHelper(iterator, rowreader, state, source, 0, failk, (relns, st) -> Ok(relns, st))

    def collectAccumHelper(iterator: RowIterator[src, row], f: (row, st) -> RowResult[(reln, st)], state: st, src: src, n: Int32, fk: (Int32, List[String]) -> Result[(reln, st), String], sk: (reln, st) -> Result[(reln, st), String]): Result[(reln, st), String] =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(state, #{ })
        } else {
            let row = getRow(src);
            match Validation.validate(f(row, state)) {
                case Err(xs) => { finalize(src); fk(n, xs) }
                case Ok(x, st1) => collectAccumHelper(iterator, f, st1, src, n+1, fk, (relns, st) -> sk(x <+> relns, st))
            }
        }

    pub def choose(iterator: RowIterator[src, row], rowreader: row -> RowResult[Option[reln]], source: src): Result[reln, String] =
        let failk = (n,msgs) -> ImportBase.collectErrors(n, msgs) |> Err;
        chooseHelper(iterator, rowreader, source, 0, failk, relns -> Ok(relns))

    def chooseHelper(iterator: RowIterator[src, row], f: row -> RowResult[Option[reln]], src: src, n: Int32, fk: (Int32, List[String]) -> Result[reln, String], sk: reln -> Result[reln, String]): Result[reln, String] =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(#{ })
        } else {
            match getRow(src) |> (Validation.validate << f) {
                case Err(xs) => { finalize(src); fk(n, xs) }
                case Ok(None) => chooseHelper(iterator, f, src, n+1, fk, relns -> sk(relns))
                case Ok(Some(x)) => chooseHelper(iterator, f, src, n+1, fk, relns -> sk(x <+> relns))
            }
        }

    pub def chooseWithCount(iterator: RowIterator[src, row], rowreader: (row,Int32) -> RowResult[Option[reln]], source: src): Result[reln, String] =
        let failk = (n,msgs) -> ImportBase.collectErrors(n, msgs) |> Err;
        chooseWithCountHelper(iterator, rowreader, source, 0, 0, failk, relns -> Ok(relns))

    def chooseWithCountHelper(iterator: RowIterator[src, row], f: (row,Int32)-> RowResult[Option[reln]], src: src, rownum: Int32, count: Int32, fk: (Int32, List[String]) -> Result[reln, String], sk: reln -> Result[reln, String]): Result[reln, String] =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(#{ })
        } else {
            let row = getRow(src);
            match Validation.validate(f(row, count)) {
                case Err(xs) => {finalize(src); fk(rownum, xs) }
                case Ok(None) => chooseWithCountHelper(iterator, f, src, rownum+1, count, fk, relns -> sk(relns))
                case Ok(Some(x)) => chooseWithCountHelper(iterator, f, src, rownum+1, count+1, fk, relns -> sk(x <+> relns))
            }
        }

    pub def chooseAccum(iterator: RowIterator[src, row], rowreader: (row, st) -> RowResult[(Option[reln], st)], state: st, source: src): Result[(reln, st), String] =
        let failk = (n,msgs) -> ImportBase.collectErrors(n, msgs) |> Err;
        chooseAccumHelper(iterator, rowreader, state, source, 0, failk, (relns, st) -> Ok(relns, st))

    def chooseAccumHelper(iterator: RowIterator[src, row], f: (row, st) -> RowResult[(Option[reln], st)], state: st, src: src, n: Int32, fk: (Int32, List[String]) -> Result[(reln, st), String], sk: (reln, st) -> Result[(reln, st), String]): Result[(reln, st), String] =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(state, #{ })
        } else {
            let row = getRow(src);
            match Validation.validate(f(row, state)) {
                case Err(xs) => { finalize(src); fk(n, xs) }
                case Ok((None, st1)) => chooseAccumHelper(iterator, f, st1, src, n+1, fk, (relns, st) -> sk(relns, st))
                case Ok((Some(x), st1)) => chooseAccumHelper(iterator, f, st1, src, n+1, fk, (relns, st) -> sk(x <+> relns, st))
            }
        }

 }