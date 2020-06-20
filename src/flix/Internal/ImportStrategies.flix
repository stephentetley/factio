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

namespace FactIO/Internal/ImportStrategies {

    type alias RowResult[t] = Result[t, System.Error]

    
    ///
    /// Process all rows of the input.
    ///
    /// Note - a `relation` is naturally monoidal - a `rowreader` can generate zero, one or many facts from a `row`.
    ///
    pub def importRows(rowreader: row -> RowResult[reln] & Impure, s: Stream[row]): Result[reln, System.Error] & Impure = 
        let step = (ac, r1) -> match rowreader(r1) { 
            case Ok(a1) => Ok(ac <+> a1)
            case Err(e) => Err(e)
        };        
        Data/Stream.foldResult(step, #{ }, s)


    ///
    /// Process all rows of the input with a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCount(rowreader: (row, Int32) -> RowResult[reln] & Impure, s: Stream[row]): Result[reln, System.Error] & Impure = 
        let step = (xy, row) -> {
            let (relns, n) = xy; 
            match rowreader(row, n) { 
                case Ok(reln1) => Ok((relns <+> reln1, n + 1))
                case Err(e) => Err(e)
            }
        };        
        Data/Stream.foldResult(step, (#{ }, 0), s)
            |> Result.map(fst)


    ///
    /// Process all rows of the input with a threaded state.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithAccum(rowreader: (row, acc) -> RowResult[(reln, acc)] & Impure, st: acc, s: Stream[row]): Result[(reln, acc), System.Error] & Impure = 
        let step = (xy, row) -> {
            let (relns, s1) = xy; 
            match rowreader(row, s1) { 
                case Ok((reln1, s2)) => Ok((relns <+> reln1, s2))
                case Err(e) => Err(e)
            }
        };        
        Data/Stream.foldResult(step, (#{ }, st), s)
    
    ///
    /// Process all rows of the input with threaded state and a zero indexed row count.
    ///
    /// Note - a `relation` is naturally monoidal - a row can generate zero, one or many facts.
    ///
    pub def importRowsWithCountAndAccum(rowreader: (row, Int32, acc) -> RowResult[(reln, acc)] & Impure, st: acc, s: Stream[row]): Result[(reln, acc), System.Error] & Impure = 
        let step = (xyz, row) -> {
            let (relns, n, s1) = xyz; 
            match rowreader(row, n, s1) { 
                case Ok((reln1, s2)) => Ok((relns <+> reln1, n + 1, s2))
                case Err(e) => Err(e)
            }
        };        
        Data/Stream.foldResult(step, (#{ }, 0, st), s)
            |> Result.map(xyz -> let (x, _, z) = xyz; (x,z))

 }