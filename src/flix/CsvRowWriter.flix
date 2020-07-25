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

use System.Error.{Generic};

use FactIO.CsvRowWriter;
use FactIO.CsvRowWriter.{CsvRowWriter};

use FactIO/Internal/Csv.Output;
use FactIO/Internal/Csv.Output.{Output};


namespace FactIO {

    pub opaque type CsvRowWriter[a] = (Map[String, Int32], Output) ~> Result[a, System.Error]

}

namespace FactIO/CsvRowWriter {

    pub def return(x: a): CsvRowWriter[a] =
        CsvRowWriter((_,_) -> Ok(x) as & Impure)

    def apply1(x: CsvRowWriter[a], headers: Map[String, Int32], r: Output): Result[a, System.Error] & Impure =
        let CsvRowWriter(f) = x;
        f(headers, r)

    pub def map(f: a -> b & ef, x: CsvRowWriter[a]): CsvRowWriter[b] =
        CsvRowWriter((hdrs,r) ->
            match apply1(x, hdrs, r) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )

    pub def ap(mf: CsvRowWriter[a -> b & ef], ma: CsvRowWriter[a]): CsvRowWriter[b] =
        CsvRowWriter((hdrs,r) ->
            match apply1(mf, hdrs, r) {
                case Ok(f) => {
                    match apply1(ma, hdrs, r) {
                        case Ok(a) => Ok(f(a) as & Impure)
                        case Err(e2) => Err(e2)
                    }
                }
                case Err(e1) => Err(e1)
            }
        )

    pub def bind(x: CsvRowWriter[a], k: a -> CsvRowWriter[b]): CsvRowWriter[b] =
        CsvRowWriter((hdrs,r) ->
            match apply1(x, hdrs, r) {
                case Ok(a) => { let ans = k(a); apply1(ans, hdrs, r) }
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> CsvRowWriter[b], x: CsvRowWriter[a]): CsvRowWriter[b] = bind(x, k)

    def primWriteCell(ix: Int32, value: String): CsvRowWriter[Unit] =
        use FactIO/Internal/Csv/Output.{setCell!};
        CsvRowWriter((_, r) -> setCell!(r, ix, value))

    def primWriteNamedCell(label: String, value: String): CsvRowWriter[Unit] =
        use FactIO/Internal/Csv/Output.{setCell!};
        CsvRowWriter((hdrs, r) ->
            match Map.get(label, hdrs) {
                case Some(ix) => setCell!(r, ix, value)
                case None => Err(Generic("Unknown label:" + label))
             }
        )

    pub def putNull!(ix: Int32): CsvRowWriter[Unit] =
        primWriteCell(ix, "")

    pub def putNullByLabel!(label: String): CsvRowWriter[Unit] =
        primWriteNamedCell(label, "")

    pub def putString!(ix: Int32, str: String): CsvRowWriter[Unit] =
        primWriteCell(ix, str)

    pub def putBool!(ix: Int32, b: Bool): CsvRowWriter[Unit] =
        primWriteCell(ix, if (b) "true" else "false")

    pub def putInt8!(ix: Int32, n: Int8): CsvRowWriter[Unit] =
        primWriteCell(ix, Int8.toString(n))

    pub def putInt16!(ix: Int32, n: Int16): CsvRowWriter[Unit] =
        primWriteCell(ix, Int16.toString(n))

    pub def putInt32!(ix: Int32, n: Int32): CsvRowWriter[Unit] =
        primWriteCell(ix, Int32.toString(n))

    pub def putInt64!(ix: Int32, n: Int64): CsvRowWriter[Unit] =
        primWriteCell(ix, Int64.toString(n))

    pub def putFloat32!(ix: Int32, n: Float32): CsvRowWriter[Unit] =
        primWriteCell(ix, Float32.toString(n))

    pub def putFloat64!(ix: Int32, n: Float64): CsvRowWriter[Unit] =
        primWriteCell(ix, Float64.toString(n))



    pub def putOptionString!(ix: Int32, x: Option[String]): CsvRowWriter[Unit] = match x {
        case Some(s) => putString!(ix, s)
        case None => putNull!(ix)
    }

    pub def putOptionBool!(ix: Int32, x: Option[Bool]): CsvRowWriter[Unit] = match x {
        case Some(b) => putBool!(ix, b)
        case None => putNull!(ix)
    }

    pub def putOptionInt8!(ix: Int32, x: Option[Int8]): CsvRowWriter[Unit] = match x {
        case Some(n) => putInt8!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionInt16!(ix: Int32, x: Option[Int16]): CsvRowWriter[Unit] = match x {
        case Some(n) => putInt16!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionInt32!(ix: Int32, x: Option[Int32]): CsvRowWriter[Unit] = match x {
        case Some(n) => putInt32!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionInt64!(ix: Int32, x: Option[Int64]): CsvRowWriter[Unit] = match x {
        case Some(n) => putInt64!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionFloat32!(ix: Int32, x: Option[Float32]): CsvRowWriter[Unit] = match x {
        case Some(n) => putFloat32!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionFloat64!(ix: Int32, x: Option[Float64]): CsvRowWriter[Unit] = match x {
        case Some(n) => putFloat64!(ix, n)
        case None => putNull!(ix)
    }


    ///
    /// Applies the binary function `f` to the values in `o1` and `o2`.
    ///
    /// Returns an error if either `o1` or `o2` are errors.
    ///
    pub def lift2(f: (t1, t2) -> u & ef, o1: CsvRowWriter[t1], o2: CsvRowWriter[t2]): CsvRowWriter[u] =
        ap(map(f, o1), o2)

    ///
    /// Applies the ternary function `f` to the values in `o1`, `o2` and `o3`.
    ///
    /// Returns an error if any of `o1`, `o2` and `o3` are errors.
    ///
    pub def lift3(f: (t1, t2, t3) -> u & ef, o1: CsvRowWriter[t1], o2: CsvRowWriter[t2], o3: CsvRowWriter[t3]): CsvRowWriter[u] =
        ap(lift2(f, o1, o2), o3)

    ///
    /// Applies the 4-ary function `f` to the values in `o1`, `o2`, `o3` and `o4`.
    ///
    /// Returns an error if any of `o1`, `o2`, `o3` and `o4` are errors.
    ///
    pub def lift4(f: (t1, t2, t3, t4) -> u & ef, o1: CsvRowWriter[t1], o2: CsvRowWriter[t2], o3: CsvRowWriter[t3], o4: CsvRowWriter[t4]): CsvRowWriter[u] =
        ap(lift3(f, o1, o2, o3), o4)

    ///
    /// Applies the 5-ary function `f` to the values in `o1`, `o2`, ... `o5`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o5` are errors.
    ///
    pub def lift5(f: (t1, t2, t3, t4, t5) -> u & ef, o1: CsvRowWriter[t1], o2: CsvRowWriter[t2], o3: CsvRowWriter[t3], o4: CsvRowWriter[t4], o5: CsvRowWriter[t5]): CsvRowWriter[u] =
        ap(lift4(f, o1, o2, o3, o4), o5)

    ///
    /// Applies the 6-ary function `f` to the values in `o1`, `o2`, ... `o6`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o6` are errors.
    ///
    pub def lift6(f: (t1, t2, t3, t4, t5, t6) -> u & ef, o1: CsvRowWriter[t1], o2: CsvRowWriter[t2], o3: CsvRowWriter[t3], o4: CsvRowWriter[t4], o5: CsvRowWriter[t5], o6: CsvRowWriter[t6]): CsvRowWriter[u] =
        ap(lift5(f, o1, o2, o3, o4, o5), o6)

    ///
    /// Applies the 7-ary function `f` to the values in `o1`, `o2`, ... `o7`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o7` are errors.
    ///
    pub def lift7(f: (t1, t2, t3, t4, t5, t6, t7) -> u & ef, o1: CsvRowWriter[t1], o2: CsvRowWriter[t2], o3: CsvRowWriter[t3], o4: CsvRowWriter[t4], o5: CsvRowWriter[t5], o6: CsvRowWriter[t6], o7: CsvRowWriter[t7]): CsvRowWriter[u] =
        ap(lift6(f, o1, o2, o3, o4, o5, o6), o7)

    ///
    /// Applies the 8-ary function `f` to the values in `o1`, `o2`, ... `o8`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o8` are errors.
    ///
    pub def lift8(f: (t1, t2, t3, t4, t5, t6, t7, t8) -> u & ef, o1: CsvRowWriter[t1], o2: CsvRowWriter[t2], o3: CsvRowWriter[t3], o4: CsvRowWriter[t4], o5: CsvRowWriter[t5], o6: CsvRowWriter[t6], o7: CsvRowWriter[t7], o8: CsvRowWriter[t8]): CsvRowWriter[u] =
        ap(lift7(f, o1, o2, o3, o4, o5, o6, o7), o8)

    ///
    /// Applies the 9-ary function `f` to the values in `o1`, `o2`, ... `o9`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o9` are errors.
    ///
    pub def lift9(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> u & ef, o1: CsvRowWriter[t1], o2: CsvRowWriter[t2], o3: CsvRowWriter[t3], o4: CsvRowWriter[t4], o5: CsvRowWriter[t5], o6: CsvRowWriter[t6], o7: CsvRowWriter[t7], o8: CsvRowWriter[t8], o9: CsvRowWriter[t9]): CsvRowWriter[u] =
        ap(lift8(f, o1, o2, o3, o4, o5, o6, o7, o8), o9)

    ///
    /// Applies the 10-ary function `f` to the values in `o1`, `o2`, ... `o10`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o10` are errors.
    ///
    pub def lift10(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> u & ef, o1: CsvRowWriter[t1], o2: CsvRowWriter[t2], o3: CsvRowWriter[t3], o4: CsvRowWriter[t4], o5: CsvRowWriter[t5], o6: CsvRowWriter[t6], o7: CsvRowWriter[t7], o8: CsvRowWriter[t8], o9: CsvRowWriter[t9], o10: CsvRowWriter[t10]): CsvRowWriter[u] =
        ap(lift9(f, o1, o2, o3, o4, o5, o6, o7, o8, o9), o10)


}

