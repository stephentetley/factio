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

use System.Error.{InputMismatchException, IOException, Generic};

use FactIO/SQLite.SQLiteRowEvaluator;
use FactIO/SQLite.SQLiteRowEvaluator.{SQLiteRowEvaluator};

namespace FactIO/SQLite {

    pub opaque type SQLiteRowEvaluator[a] = ##flix.runtime.spt.factio.SQLiteRow ~> Result[a, System.Error]
}


namespace FactIO/SQLite/RowEvaluator {

    pub def return(x: a): SQLiteRowEvaluator[a] = 
        SQLiteRowEvaluator(_ -> Ok(x) as & Impure)

    def apply1(x: SQLiteRowEvaluator[a], r: ##flix.runtime.spt.factio.SQLiteRow): Result[a, System.Error] & Impure =
        let SQLiteRowEvaluator(f) = x;
        f(r)

    pub def map(f: a -> b & e, x: SQLiteRowEvaluator[a]): SQLiteRowEvaluator[b] =
        SQLiteRowEvaluator(r -> 
            match apply1(x, r) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )        

    pub def ap(mf: SQLiteRowEvaluator[a -> b], ma: SQLiteRowEvaluator[a]): SQLiteRowEvaluator[b] =
        SQLiteRowEvaluator(r -> 
            match apply1(mf, r) {
                case Ok(f) => { 
                    match apply1(ma, r) {
                        case Ok(a) => Ok(f(a))
                        case Err(e2) => Err(e2)
                    }
                }
                case Err(e1) => Err(e1)
            }
        )

    pub def bind(x: SQLiteRowEvaluator[a], k: a -> SQLiteRowEvaluator[b]): SQLiteRowEvaluator[b] = 
        SQLiteRowEvaluator(r -> 
            match apply1(x, r) { 
                case Ok(a) => { let ans = k(a); apply1(ans, r) }
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> SQLiteRowEvaluator[b], x: SQLiteRowEvaluator[a]): SQLiteRowEvaluator[b] = bind(x, k)

    def liftPrimRowReader(eval: ##flix.runtime.spt.factio.SQLiteRow ~> Result[a, System.Error]): SQLiteRowEvaluator[a] =
        SQLiteRowEvaluator(r -> eval(r))
    
    pub def liftResult(x: Result[a, System.Error]): SQLiteRowEvaluator[a] = 
        SQLiteRowEvaluator(_ -> x as & Impure)

    pub def throwError(err: System.Error): SQLiteRowEvaluator[a] =
        SQLiteRowEvaluator(_ -> Err(err) as & Impure)

    pub def choice(xs: List[SQLiteRowEvaluator[a]]): SQLiteRowEvaluator[a] =
        SQLiteRowEvaluator(r -> choiceHelper(r, xs))

    def choiceHelper(r: ##flix.runtime.spt.factio.SQLiteRow, xs: List[SQLiteRowEvaluator[a]]): Result[a, System.Error] & Impure =
        match xs {
            case Nil => Err(InputMismatchException) as & Impure
            case x1 :: rs => match apply1(x1, r) {
                case Ok(a) => Ok(a)
                case Err(_) => choiceHelper(r, rs)
            }
        }

    // Cell readers

    pub def getStringByIndex(ix: Int32): SQLiteRowEvaluator[String] =
        import flix.runtime.spt.factio.SQLiteRow.getStringByIndex(Int32);
        liftPrimRowReader(row ->
            try {
                let a = row.getStringByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        ) 

    pub def getStringByLabel(label: String): SQLiteRowEvaluator[String] =
        import flix.runtime.spt.factio.SQLiteRow.getStringByLabel(String);
        liftPrimRowReader(row ->
            try {
                let a = row.getStringByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt8ByIndex(ix: Int32): SQLiteRowEvaluator[Int8] =
        import flix.runtime.spt.factio.SQLiteRow.getByteByIndex(Int32);
        liftPrimRowReader(row ->
            try {
                let a = row.getByteByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt8ByLabel(label: String): SQLiteRowEvaluator[Int8] =
        import flix.runtime.spt.factio.SQLiteRow.getByteByLabel(String);
        liftPrimRowReader(row ->
            try {
                let a = row.getByteByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt16ByIndex(ix: Int32): SQLiteRowEvaluator[Int16] =
        import flix.runtime.spt.factio.SQLiteRow.getShortByIndex(Int32);
        liftPrimRowReader(row ->
            try {
                let a = row.getShortByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt16ByLabel(label: String): SQLiteRowEvaluator[Int16] =
        import flix.runtime.spt.factio.SQLiteRow.getShortByLabel(String);
        liftPrimRowReader(row ->
            try {
                let a = row.getShortByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt32ByIndex(ix: Int32): SQLiteRowEvaluator[Int32] =
        import flix.runtime.spt.factio.SQLiteRow.getIntByIndex(Int32);
        liftPrimRowReader(row ->
            try {
                let a = row.getIntByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt32ByLabel(label: String): SQLiteRowEvaluator[Int32] =
        import flix.runtime.spt.factio.SQLiteRow.getIntByLabel(String);
        liftPrimRowReader(row ->
            try {
                let a = row.getIntByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt64ByIndex(ix: Int32): SQLiteRowEvaluator[Int64] =
        import flix.runtime.spt.factio.SQLiteRow.getLongByIndex(Int32);
        liftPrimRowReader(row ->
            try {
                let a = row.getLongByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt64ByLabel(label: String): SQLiteRowEvaluator[Int64] =
        import flix.runtime.spt.factio.SQLiteRow.getLongByLabel(String);
        liftPrimRowReader(row ->
            try {
                let a = row.getLongByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getFloat32ByIndex(ix: Int32): SQLiteRowEvaluator[Float32] =
        import flix.runtime.spt.factio.SQLiteRow.getFloatByIndex(Int32);
        liftPrimRowReader(row ->
            try {
                let a = row.getFloatByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getFloat32ByLabel(label: String): SQLiteRowEvaluator[Float32] =
        import flix.runtime.spt.factio.SQLiteRow.getFloatByLabel(String);
        liftPrimRowReader(row ->
            try {
                let a = row.getFloatByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getFloat64ByIndex(ix: Int32): SQLiteRowEvaluator[Float64] =
        import flix.runtime.spt.factio.SQLiteRow.getDoubleByIndex(Int32);
        liftPrimRowReader(row ->
            try {
                let a = row.getDoubleByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getFloat64ByLabel(label: String): SQLiteRowEvaluator[Float64] =
        import flix.runtime.spt.factio.SQLiteRow.getDoubleByLabel(String);
        liftPrimRowReader(row ->       
            try {
                let a = row.getDoubleByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    ///
    /// Applies the binary function `f` to the values in `o1` and `o2`.
    ///
    /// Returns an error if either `o1` or `o2` are errors.
    ///
    pub def lift2(f: (t1, t2) -> u & f, o1: SQLiteRowEvaluator[t1], o2: SQLiteRowEvaluator[t2]): SQLiteRowEvaluator[u] =
        ap(map(f, o1), o2)

    ///
    /// Applies the ternary function `f` to the values in `o1`, `o2` and `o3`.
    ///
    /// Returns an error if any of `o1`, `o2` and `o3` are errors.
    ///
    pub def lift3(f: (t1, t2, t3) -> u & f, o1: SQLiteRowEvaluator[t1], o2: SQLiteRowEvaluator[t2], o3: SQLiteRowEvaluator[t3]): SQLiteRowEvaluator[u] & f =
        ap(lift2(f, o1, o2), o3)

    ///
    /// Applies the 4-ary function `f` to the values in `o1`, `o2`, `o3` and `o4`.
    ///
    /// Returns an error if any of `o1`, `o2`, `o3` and `o4` are errors.
    ///
    pub def lift4(f: (t1, t2, t3, t4) -> u & f, o1: SQLiteRowEvaluator[t1], o2: SQLiteRowEvaluator[t2], o3: SQLiteRowEvaluator[t3], o4: SQLiteRowEvaluator[t4]): SQLiteRowEvaluator[u] & f =
        ap(lift3(f, o1, o2, o3), o4)

    ///
    /// Applies the 5-ary function `f` to the values in `o1`, `o2`, ... `o5`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o5` are errors.
    ///
    pub def lift5(f: (t1, t2, t3, t4, t5) -> u & f, o1: SQLiteRowEvaluator[t1], o2: SQLiteRowEvaluator[t2], o3: SQLiteRowEvaluator[t3], o4: SQLiteRowEvaluator[t4], o5: SQLiteRowEvaluator[t5]): SQLiteRowEvaluator[u] & f =
        ap(lift4(f, o1, o2, o3, o4), o5)

    ///
    /// Applies the 6-ary function `f` to the values in `o1`, `o2`, ... `o6`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o6` are errors.
    ///
    pub def lift6(f: (t1, t2, t3, t4, t5, t6) -> u & f, o1: SQLiteRowEvaluator[t1], o2: SQLiteRowEvaluator[t2], o3: SQLiteRowEvaluator[t3], o4: SQLiteRowEvaluator[t4], o5: SQLiteRowEvaluator[t5], o6: SQLiteRowEvaluator[t6]): SQLiteRowEvaluator[u] & f =
        ap(lift5(f, o1, o2, o3, o4, o5), o6)

    ///
    /// Applies the 7-ary function `f` to the values in `o1`, `o2`, ... `o7`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o7` are errors.
    ///
    pub def lift7(f: (t1, t2, t3, t4, t5, t6, t7) -> u & f, o1: SQLiteRowEvaluator[t1], o2: SQLiteRowEvaluator[t2], o3: SQLiteRowEvaluator[t3], o4: SQLiteRowEvaluator[t4], o5: SQLiteRowEvaluator[t5], o6: SQLiteRowEvaluator[t6], o7: SQLiteRowEvaluator[t7]): SQLiteRowEvaluator[u] & f=
        ap(lift6(f, o1, o2, o3, o4, o5, o6), o7)

    ///
    /// Applies the 8-ary function `f` to the values in `o1`, `o2`, ... `o8`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o8` are errors.
    ///
    pub def lift8(f: (t1, t2, t3, t4, t5, t6, t7, t8) -> u & f, o1: SQLiteRowEvaluator[t1], o2: SQLiteRowEvaluator[t2], o3: SQLiteRowEvaluator[t3], o4: SQLiteRowEvaluator[t4], o5: SQLiteRowEvaluator[t5], o6: SQLiteRowEvaluator[t6], o7: SQLiteRowEvaluator[t7], o8: SQLiteRowEvaluator[t8]): SQLiteRowEvaluator[u] & f =
        ap(lift7(f, o1, o2, o3, o4, o5, o6, o7), o8)

    ///
    /// Applies the 9-ary function `f` to the values in `o1`, `o2`, ... `o9`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o9` are errors.
    ///
    pub def lift9(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> u & f, o1: SQLiteRowEvaluator[t1], o2: SQLiteRowEvaluator[t2], o3: SQLiteRowEvaluator[t3], o4: SQLiteRowEvaluator[t4], o5: SQLiteRowEvaluator[t5], o6: SQLiteRowEvaluator[t6], o7: SQLiteRowEvaluator[t7], o8: SQLiteRowEvaluator[t8], o9: SQLiteRowEvaluator[t9]): SQLiteRowEvaluator[u] & f =
        ap(lift8(f, o1, o2, o3, o4, o5, o6, o7, o8), o9)

    ///
    /// Applies the 10-ary function `f` to the values in `o1`, `o2`, ... `o10`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o10` are errors.
    ///
    pub def lift10(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> u & f, o1: SQLiteRowEvaluator[t1], o2: SQLiteRowEvaluator[t2], o3: SQLiteRowEvaluator[t3], o4: SQLiteRowEvaluator[t4], o5: SQLiteRowEvaluator[t5], o6: SQLiteRowEvaluator[t6], o7: SQLiteRowEvaluator[t7], o8: SQLiteRowEvaluator[t8], o9: SQLiteRowEvaluator[t9], o10: SQLiteRowEvaluator[t10]): SQLiteRowEvaluator[u] & f =
        ap(lift9(f, o1, o2, o3, o4, o5, o6, o7, o8, o9), o10)


}