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

    use FlixSandbox/Deprecated.Cursor;
    use FlixSandbox/Deprecated.Cursor.{Cursor};

    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a `rowreader` can generate zero, one or many facts from a `row`.
    ///
    pub def importRows(rowreader: row -> Result[#{| reln}, err] & ef,
                        s: Cursor[err, row]): Result[#{| reln}, err] & ef =
        let step = (ac, r1) -> match rowreader(r1) {
            case Ok(a1) => Ok(ac <+> a1)
            case Err(e) => Err(e)
        };
        FlixSandbox/Deprecated/Cursor.foldResult!(step, #{ }, s) as & ef


    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount(rowreader: (row, Int32) -> Result[#{| reln}, err] & ef,
                                s: Cursor[err, row]): Result[#{| reln}, err] & ef =
        let step = (xy, row) -> {
            let (relns, n) = xy;
            match rowreader(row, n) {
                case Ok(reln1) => Ok((relns <+> reln1, n + 1))
                case Err(e) => Err(e)
            }
        };
        (FlixSandbox/Deprecated/Cursor.foldResult!(step, (#{ }, 0), s)
            |> Result.map(fst)) as & ef


    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum(rowreader: (row, acc) -> Result[(#{| reln}, acc), err] & ef,
                                st: acc,
                                s: Cursor[err, row]): Result[(#{| reln}, acc), err] & ef =
        let step = (xy, row) -> {
            let (relns, s1) = xy;
            match rowreader(row, s1) {
                case Ok((reln1, s2)) => Ok((relns <+> reln1, s2))
                case Err(e) => Err(e)
            }
        };
        FlixSandbox/Deprecated/Cursor.foldResult!(step, (#{ }, st), s) as & ef

    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum(rowreader: (row, Int32, acc) -> Result[(#{| reln}, acc), err] & ef,
                                        st: acc,
                                        s: Cursor[err, row]): Result[(#{| reln}, acc), err] & ef =
        let step = (xyz, row) -> {
            let (relns, n, s1) = xyz;
            match rowreader(row, n, s1) {
                case Ok((reln1, s2)) => Ok((relns <+> reln1, n + 1, s2))
                case Err(e) => Err(e)
            }
        };
        (FlixSandbox/Deprecated/Cursor.foldResult!(step, (#{ }, 0, st), s)
            |> Result.map(xyz -> let (x, _, z) = xyz; (x,z))) as & ef

    ///
    /// Process all rows of the input.
    ///
    pub def getRows(rowreader: row -> Result[a, err] & ef,
                    ss: Cursor[err, row]): Result[List[a], err] & ef =
        (ss |> FlixSandbox/Deprecated/Cursor.mapResult(rowreader)
            |> FlixSandbox/Deprecated/Cursor.toList!) as & ef

}
