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

type alias RowIterator[src,row] = { hasNext: src -> Bool & Impure , getRow: src -> row & Impure , finalize: src -> Unit & Impure }

namespace Strategies {

    ///
    /// `eachrow` generates one fact for each row in the input.
    ///
    pub def eachrow(iterator: RowIterator[src, row], rowreader: row -> RowResult[reln] & e, source: src): Result[reln, String] & Impure =
        let failk = (n,msgs) -> FactIOBase.collectErrors(n, msgs) |> Err;
        eachrowHelper(iterator, rowreader, source, 0, failk, relns -> Ok(relns))

    def eachrowHelper(iterator: RowIterator[src, row], rowreader: row -> RowResult[reln] & e, src: src, n: Int32, fk: (Int32, List[String]) -> Result[reln, String], sk: reln -> Result[reln, String]): Result[reln, String] & Impure =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(#{ })
        } else {
            let row = rowreader(getRow(src)) as & Impure;
            match Validation.validate(row) {
                case Err(xs) => { finalize(src); fk(n, xs) }
                case Ok(x) => eachrowHelper(iterator, rowreader, src, n+1, fk, relns -> sk(x <+> relns))
            }
        }

    pub def eachrowWithCount(iterator: RowIterator[src, row], rowreader: (row, Int32) -> RowResult[reln] & e, source: src): Result[reln, String] & Impure =
        let failk = (n,msgs) -> FactIOBase.collectErrors(n, msgs) |> Err;
        eachrowWithCountHelper(iterator, rowreader, source, 0, failk, relns -> Ok(relns))

    def eachrowWithCountHelper(iterator: RowIterator[src, row], rowreader: (row, Int32) -> RowResult[reln] & e, src: src, n: Int32, fk: (Int32, List[String]) -> Result[reln, String], sk: rel -> Result[reln, String]): Result[reln, String] & Impure =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(#{ })
        } else {
            let row = rowreader(getRow(src), n) as & Impure;
            match Validation.validate(row) {
                case Err(xs) => { finalize(src); fk(n, xs) }
                case Ok(x) => eachrowWithCountHelper(iterator, rowreader, src, n+1, fk, relns -> sk(x <+> relns))
            }
        }

    pub def eachrowAccum(iterator: RowIterator[src, row], rowreader: (row, st) -> RowResult[(reln, st)] & e, state: st, source: src): Result[(reln, st), String] & Impure =
        let failk = (n,msgs) -> FactIOBase.collectErrors(n, msgs) |> Err;
        eachrowAccumHelper(iterator, rowreader, state, source, 0, failk, (relns, st) -> Ok(relns, st))

    def eachrowAccumHelper(iterator: RowIterator[src, row], rowreader: (row, st) -> RowResult[(reln, st)] & e, state: st, src: src, n: Int32, fk: (Int32, List[String]) -> Result[(reln, st), String], sk: (reln, st) -> Result[(reln, st), String]): Result[(reln, st), String] & Impure =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(state, #{ })
        } else {
            let row = rowreader(getRow(src), state) as & Impure;
            match Validation.validate(row) {
                case Err(xs) => { finalize(src); fk(n, xs) }
                case Ok(x, st1) => eachrowAccumHelper(iterator, rowreader, st1, src, n+1, fk, (relns, st) -> sk(x <+> relns, st))
            }
        }

    ///
    /// `choose` generates either one fact or nothing for each row in the input.
    ///
    pub def choose(iterator: RowIterator[src, row], rowreader: row -> RowResult[Option[reln]] & e, source: src): Result[reln, String] & Impure =
        let failk = (n,msgs) -> FactIOBase.collectErrors(n, msgs) |> Err;
        chooseHelper(iterator, rowreader, source, 0, failk, relns -> Ok(relns))

    def chooseHelper(iterator: RowIterator[src, row], rowreader: row -> RowResult[Option[reln]] & e, src: src, n: Int32, fk: (Int32, List[String]) -> Result[reln, String], sk: reln -> Result[reln, String]): Result[reln, String] & Impure =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(#{ })
        } else {
            let row = rowreader(getRow(src)) as & Impure;
            match Validation.validate(row) {
                case Err(xs) => { finalize(src); fk(n, xs) }
                case Ok(None) => chooseHelper(iterator, rowreader, src, n+1, fk, relns -> sk(relns))
                case Ok(Some(x)) => chooseHelper(iterator, rowreader, src, n+1, fk, relns -> sk(x <+> relns))
            }
        }

    pub def chooseWithCount(iterator: RowIterator[src, row], rowreader: (row,Int32) -> RowResult[Option[reln]] & e, source: src): Result[reln, String] & Impure =
        let failk = (n,msgs) -> FactIOBase.collectErrors(n, msgs) |> Err;
        chooseWithCountHelper(iterator, rowreader, source, 0, 0, failk, relns -> Ok(relns))

    def chooseWithCountHelper(iterator: RowIterator[src, row], rowreader: (row,Int32)-> RowResult[Option[reln]] & e, src: src, rownum: Int32, count: Int32, fk: (Int32, List[String]) -> Result[reln, String], sk: reln -> Result[reln, String]): Result[reln, String] & Impure =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(#{ })
        } else {
            let row = rowreader(getRow(src), count) as & Impure;
            match Validation.validate(row) {
                case Err(xs) => {finalize(src); fk(rownum, xs) }
                case Ok(None) => chooseWithCountHelper(iterator, rowreader, src, rownum+1, count, fk, relns -> sk(relns))
                case Ok(Some(x)) => chooseWithCountHelper(iterator, rowreader, src, rownum+1, count+1, fk, relns -> sk(x <+> relns))
            }
        }

    pub def chooseAccum(iterator: RowIterator[src, row], rowreader: (row, st) -> RowResult[(Option[reln], st)] & e, state: st, source: src): Result[(reln, st), String] & Impure =
        let failk = (n,msgs) -> FactIOBase.collectErrors(n, msgs) |> Err;
        chooseAccumHelper(iterator, rowreader, state, source, 0, failk, (relns, st) -> Ok(relns, st))

    def chooseAccumHelper(iterator: RowIterator[src, row], rowreader: (row, st) -> RowResult[(Option[reln], st)] & e, state: st, src: src, n: Int32, fk: (Int32, List[String]) -> Result[(reln, st), String], sk: (reln, st) -> Result[(reln, st), String]): Result[(reln, st), String] & Impure =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(state, #{ })
        } else {
            let row = rowreader(getRow(src), state) as & Impure;
            match Validation.validate(row) {
                case Err(xs) => { finalize(src); fk(n, xs) }
                case Ok((None, st1)) => chooseAccumHelper(iterator, rowreader, st1, src, n+1, fk, (relns, st) -> sk(relns, st))
                case Ok((Some(x), st1)) => chooseAccumHelper(iterator, rowreader, st1, src, n+1, fk, (relns, st) -> sk(x <+> relns, st))
            }
        }


    ///
    /// Helper for the `collect` family of strategies.
    ///
    def appendFacts(xs: List[reln], db: reln): reln & Pure =
        List.foldLeft((a,x) -> x <+> a, db, xs)


    ///
    /// `collect` generates a list of facts (i.e - zero, one, many) for each row in the input.
    ///
    pub def collect(iterator: RowIterator[src, row], rowreader: row -> RowResult[List[reln]] & e, source: src): Result[reln, String] & Impure =
        let failk = (n,msgs) -> FactIOBase.collectErrors(n, msgs) |> Err;
        collectHelper(iterator, rowreader, source, 0, failk, relns -> Ok(relns))

    def collectHelper(iterator: RowIterator[src, row], rowreader: row -> RowResult[List[reln]] & e, src: src, n: Int32, fk: (Int32, List[String]) -> Result[reln, String], sk: reln -> Result[reln, String]): Result[reln, String] & Impure =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(#{ })
        } else {
            let row = rowreader(getRow(src)) as & Impure;
            match Validation.validate(row) {
                case Err(errs) => { finalize(src); fk(n, errs) }
                case Ok(xs) => collectHelper(iterator, rowreader, src, n+1, fk, relns -> { let relns2 = appendFacts(xs, relns); sk(relns2) })
            }
        }


    pub def collectWithCount(iterator: RowIterator[src, row], rowreader: (row,Int32) -> RowResult[List[reln]] & e, source: src): Result[reln, String] & Impure =
        let failk = (n,msgs) -> FactIOBase.collectErrors(n, msgs) |> Err;
        collectWithCountHelper(iterator, rowreader, source, 0, 0, failk, relns -> Ok(relns))

    def collectWithCountHelper(iterator: RowIterator[src, row], rowreader: (row,Int32)-> RowResult[List[reln]] & e, src: src, rownum: Int32, count: Int32, fk: (Int32, List[String]) -> Result[reln, String], sk: reln -> Result[reln, String]): Result[reln, String] & Impure =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(#{ })
        } else {
            let row = rowreader(getRow(src), count) as & Impure;
            match Validation.validate(row) {
                case Err(errs) => {finalize(src); fk(rownum, errs) }
                case Ok(xs) => collectWithCountHelper(iterator, rowreader, src, rownum+1, count+1, fk, relns -> { let relns2 = appendFacts(xs, relns); sk(relns2) })
            }
        }

    pub def collectAccum(iterator: RowIterator[src, row], rowreader: (row, st) -> RowResult[(List[reln], st)] & e, state: st, source: src): Result[(reln, st), String] & Impure =
        let failk = (n,msgs) -> FactIOBase.collectErrors(n, msgs) |> Err;
        collectAccumHelper(iterator, rowreader, state, source, 0, failk, (relns, st) -> Ok(relns, st))

    def collectAccumHelper(iterator: RowIterator[src, row], rowreader: (row, st) -> RowResult[(List[reln], st)] & e, state: st, src: src, n: Int32, fk: (Int32, List[String]) -> Result[(reln, st), String], sk: (reln, st) -> Result[(reln, st), String]): Result[(reln, st), String] & Impure =
        let hasNext = iterator.hasNext;
        let getRow = iterator.getRow;
        let finalize = iterator.finalize;
        if (!hasNext(src)) {
            finalize(src);
            sk(state, #{ })
        } else {
            let row = rowreader(getRow(src), state) as & Impure;
            match Validation.validate(row) {
                case Err(errs) => { finalize(src); fk(n, errs) }
                case Ok((xs, st1)) => collectAccumHelper(iterator, rowreader, st1, src, n+1, fk, (relns, st) -> { let relns2 = appendFacts(xs, relns); sk(relns2, st)})
            }
        }

 }