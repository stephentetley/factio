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


namespace FactIO/Internal/ImportStrategies {



    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a `rowreader` can generate zero, one or many facts from a `row`.
    ///
    pub def importRows(rowreader: row -> Result[#{| reln}, err] & Impure,
                        iter: Iterator[Result[row, err]]): Result[#{| reln}, err] & Impure =
        let step = (ac, r1) -> match rowreader(r1) {
            case Ok(a1) => Ok(ac <+> a1)
            case Err(e) => Err(e)
        };
        X/IteratorExtras.foldLeftM(step, #{}, iter)


    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount(rowreader: (row, Int32) ~> Result[#{| reln}, err],
                                iter: Iterator[Result[row, err]]): Result[#{| reln}, err] & Impure =
        let step = (xy, row) -> {
            let (relns, n) = xy;
            match rowreader(row, n) {
                case Ok(reln1) => Ok((relns <+> reln1, n + 1))
                case Err(e) => Err(e)
            }
        };
        X/IteratorExtras.foldLeftM(step, (#{ }, 0), iter)
            |> Result.map(fst)


    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum(rowreader: (row, acc) ~> Result[(#{| reln}, acc), err],
                                st: acc,
                                iter: Iterator[Result[row, err]]): Result[(#{| reln}, acc), err] & Impure =
        let step = (xy, row) -> {
            let (relns, s1) = xy;
            match rowreader(row, s1) {
                case Ok((reln1, s2)) => Ok((relns <+> reln1, s2))
                case Err(e) => Err(e)
            }
        };
        X/IteratorExtras.foldLeftM(step, (#{}, st), iter)

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum(rowreader: (row, Int32, acc) ~> Result[(#{| reln}, acc), err],
                                        st: acc,
                                        iter: Iterator[Result[row, err]]): Result[(#{| reln}, acc), err] & Impure =
        let step = (xyz, row) -> {
            let (relns, n, s1) = xyz;
            match rowreader(row, n, s1) {
                case Ok((reln1, s2)) => Ok((relns <+> reln1, n + 1, s2))
                case Err(e) => Err(e)
            }
        };
        X/IteratorExtras.foldLeftM(step, (#{}, 0, st), iter)
            |> Result.map(xyz -> let (x, _, z) = xyz; (x,z))

    ///
    /// Process all rows of the input.
    ///
    /// TODO - change to CPS to avoid reverse
    ///
    pub def getRows(rowreader: row ~> Result[a, err],
                    iter: Iterator[Result[row, err]]): Result[List[a], err] & Impure =
        let step = (ac, row) -> {
            match rowreader(row) {
                case Ok(a1) => Ok(a1 :: ac)
                case Err(e) => Err(e)
            }
        };
        X/IteratorExtras.foldLeftM(step, Nil, iter)
            |> Result.map(List.reverse)


}
