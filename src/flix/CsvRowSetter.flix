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



namespace FactIO {

    use FactIO/Internal/Csv.Output;

    pub opaque type CsvRowSetter[a] = (Map[String, Int32], Output) ~> Result[a, String]

}

namespace FactIO/CsvRowSetter {

    use FactIO.CsvRowSetter;
    use FactIO.CsvRowSetter.{CsvRowSetter};

    use FactIO/Internal/Csv.Output;
    use FactIO/Internal/Csv.Output.{Output};

    pub def return(x: a): CsvRowSetter[a] =
        CsvRowSetter((_,_) -> Ok(x) as & Impure)

    def apply1(x: CsvRowSetter[a], headers: Map[String, Int32], r: Output): Result[a, String] & Impure =
        let CsvRowSetter(f) = x;
        f(headers, r)

    pub def map(f: a -> b & ef, x: CsvRowSetter[a]): CsvRowSetter[b] =
        CsvRowSetter((hdrs,r) ->
            match apply1(x, hdrs, r) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )

    pub def ap(mf: CsvRowSetter[a -> b & ef], ma: CsvRowSetter[a]): CsvRowSetter[b] =
        CsvRowSetter((hdrs,r) ->
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

    pub def bind(x: CsvRowSetter[a], k: a -> CsvRowSetter[b]): CsvRowSetter[b] =
        CsvRowSetter((hdrs,r) ->
            match apply1(x, hdrs, r) {
                case Ok(a) => { let ans = k(a); apply1(ans, hdrs, r) }
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> CsvRowSetter[b], x: CsvRowSetter[a]): CsvRowSetter[b] = bind(x, k)

    def primWriteCell(ix: Int32, value: String): CsvRowSetter[Unit] =
        use FactIO/Internal/Csv/Output.{setCell!};
        CsvRowSetter((_, r) -> Option.toOk(setCell!(r, ix, value), "primWriteCell"))

    def primWriteNamedCell(label: String, value: String): CsvRowSetter[Unit] =
        use FactIO/Internal/Csv/Output.{setCell!};
        CsvRowSetter((hdrs, r) ->
            match Map.get(label, hdrs) {
                case Some(ix) => Option.toOk(setCell!(r, ix, value), "primWriteNamedCell")
                case None => Err("Unknown label: '${label}'")
             }
        )

    pub def putNull!(ix: Int32): CsvRowSetter[Unit] =
        primWriteCell(ix, "")

    pub def putNullByLabel!(label: String): CsvRowSetter[Unit] =
        primWriteNamedCell(label, "")

    pub def putString!(ix: Int32, str: String): CsvRowSetter[Unit] =
        primWriteCell(ix, str)

    pub def putStringByLabel!(label: String, str: String): CsvRowSetter[Unit] =
        primWriteNamedCell(label, str)

    pub def putBool!(ix: Int32, b: Bool): CsvRowSetter[Unit] =
        primWriteCell(ix, if (b) "true" else "false")

    pub def putBoolByLabel!(label: String, b: Bool): CsvRowSetter[Unit] =
        primWriteNamedCell(label, if (b) "true" else "false")

    pub def putInt8!(ix: Int32, n: Int8): CsvRowSetter[Unit] =
        primWriteCell(ix, Int8.toString(n))

    pub def putInt8ByLabel!(label: String, n: Int8): CsvRowSetter[Unit] =
        primWriteNamedCell(label, Int8.toString(n))

    pub def putInt16!(ix: Int32, n: Int16): CsvRowSetter[Unit] =
        primWriteCell(ix, Int16.toString(n))

    pub def putInt16ByLabel!(label: String, n: Int16): CsvRowSetter[Unit] =
        primWriteNamedCell(label, Int16.toString(n))

    pub def putInt32!(ix: Int32, n: Int32): CsvRowSetter[Unit] =
        primWriteCell(ix, Int32.toString(n))

    pub def putInt32ByLabel!(label: String, n: Int32): CsvRowSetter[Unit] =
        primWriteNamedCell(label, Int32.toString(n))

    pub def putInt64!(ix: Int32, n: Int64): CsvRowSetter[Unit] =
        primWriteCell(ix, Int64.toString(n))

    pub def putInt64ByLabel!(label: String, n: Int64): CsvRowSetter[Unit] =
        primWriteNamedCell(label, Int64.toString(n))

    pub def putBigInt!(ix: Int32, n: BigInt): CsvRowSetter[Unit] =
        primWriteCell(ix, BigInt.toString(n))

    pub def putBigIntByLabel!(label: String, n: BigInt): CsvRowSetter[Unit] =
        primWriteNamedCell(label, BigInt.toString(n))

    pub def putFloat32!(ix: Int32, n: Float32): CsvRowSetter[Unit] =
        primWriteCell(ix, Float32.toString(n))

    pub def putFloat32ByLabel!(label: String, n: Float32): CsvRowSetter[Unit] =
        primWriteNamedCell(label, Float32.toString(n))

    pub def putFloat64!(ix: Int32, n: Float64): CsvRowSetter[Unit] =
        primWriteCell(ix, Float64.toString(n))

    pub def putFloat64ByLabel!(label: String, n: Float64): CsvRowSetter[Unit] =
        primWriteNamedCell(label, Float64.toString(n))


    pub def putOptionString!(ix: Int32, x: Option[String]): CsvRowSetter[Unit] = match x {
        case Some(s) => putString!(ix, s)
        case None => putNull!(ix)
    }

    pub def putOptionStringByLabel!(label: String, x: Option[String]): CsvRowSetter[Unit] = match x {
        case Some(s) => putStringByLabel!(label, s)
        case None => putNullByLabel!(label)
    }

    pub def putOptionBool!(ix: Int32, x: Option[Bool]): CsvRowSetter[Unit] = match x {
        case Some(b) => putBool!(ix, b)
        case None => putNull!(ix)
    }

    pub def putOptionBoolByLabel!(label: String, x: Option[Bool]): CsvRowSetter[Unit] = match x {
        case Some(b) => putBoolByLabel!(label, b)
        case None => putNullByLabel!(label)
    }

    pub def putOptionInt8!(ix: Int32, x: Option[Int8]): CsvRowSetter[Unit] = match x {
        case Some(n) => putInt8!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionInt8ByLabel!(label: String, x: Option[Int8]): CsvRowSetter[Unit] = match x {
        case Some(n) => putInt8ByLabel!(label, n)
        case None => putNullByLabel!(label)
    }

    pub def putOptionInt16!(ix: Int32, x: Option[Int16]): CsvRowSetter[Unit] = match x {
        case Some(n) => putInt16!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionInt16ByLabel!(label: String, x: Option[Int16]): CsvRowSetter[Unit] = match x {
        case Some(n) => putInt16ByLabel!(label, n)
        case None => putNullByLabel!(label)
    }

    pub def putOptionInt32!(ix: Int32, x: Option[Int32]): CsvRowSetter[Unit] = match x {
        case Some(n) => putInt32!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionInt32ByLabel!(label: String, x: Option[Int32]): CsvRowSetter[Unit] = match x {
        case Some(n) => putInt32ByLabel!(label, n)
        case None => putNullByLabel!(label)
    }

    pub def putOptionInt64!(ix: Int32, x: Option[Int64]): CsvRowSetter[Unit] = match x {
        case Some(n) => putInt64!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionInt64ByLabel!(label: String, x: Option[Int64]): CsvRowSetter[Unit] = match x {
        case Some(n) => putInt64ByLabel!(label, n)
        case None => putNullByLabel!(label)
    }

    pub def putOptionBigInt!(ix: Int32, x: Option[BigInt]): CsvRowSetter[Unit] = match x {
        case Some(n) => putBigInt!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionBigIntByLabel!(label: String, x: Option[BigInt]): CsvRowSetter[Unit] = match x {
        case Some(n) => putBigIntByLabel!(label, n)
        case None => putNullByLabel!(label)
    }

    pub def putOptionFloat32!(ix: Int32, x: Option[Float32]): CsvRowSetter[Unit] = match x {
        case Some(n) => putFloat32!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionFloat32ByLabel!(label: String, x: Option[Float32]): CsvRowSetter[Unit] = match x {
        case Some(n) => putFloat32ByLabel!(label, n)
        case None => putNullByLabel!(label)
    }

    pub def putOptionFloat64!(ix: Int32, x: Option[Float64]): CsvRowSetter[Unit] = match x {
        case Some(n) => putFloat64!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionFloat64ByLabel!(label: String, x: Option[Float64]): CsvRowSetter[Unit] = match x {
        case Some(n) => putFloat64ByLabel!(label, n)
        case None => putNullByLabel!(label)
    }

    ///
    /// Applies the binary function `f` to the values in `o1` and `o2`.
    ///
    /// Returns an error if either `o1` or `o2` are errors.
    ///
    pub def lift2(f: (t1, t2) -> u & ef, o1: CsvRowSetter[t1], o2: CsvRowSetter[t2]): CsvRowSetter[u] =
        ap(map(f, o1), o2)

    ///
    /// Applies the ternary function `f` to the values in `o1`, `o2` and `o3`.
    ///
    /// Returns an error if any of `o1`, `o2` and `o3` are errors.
    ///
    pub def lift3(f: (t1, t2, t3) -> u & ef,
                  o1: CsvRowSetter[t1],
                  o2: CsvRowSetter[t2],
                  o3: CsvRowSetter[t3]): CsvRowSetter[u] =
        ap(lift2(f, o1, o2), o3)

    ///
    /// Applies the 4-ary function `f` to the values in `o1`, `o2`, `o3` and `o4`.
    ///
    /// Returns an error if any of `o1`, `o2`, `o3` and `o4` are errors.
    ///
    pub def lift4(f: (t1, t2, t3, t4) -> u & ef,
                  o1: CsvRowSetter[t1],
                  o2: CsvRowSetter[t2],
                  o3: CsvRowSetter[t3],
                  o4: CsvRowSetter[t4]): CsvRowSetter[u] =
        ap(lift3(f, o1, o2, o3), o4)

    ///
    /// Applies the 5-ary function `f` to the values in `o1`, `o2`, ... `o5`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o5` are errors.
    ///
    pub def lift5(f: (t1, t2, t3, t4, t5) -> u & ef,
                  o1: CsvRowSetter[t1],
                  o2: CsvRowSetter[t2],
                  o3: CsvRowSetter[t3],
                  o4: CsvRowSetter[t4],
                  o5: CsvRowSetter[t5]): CsvRowSetter[u] =
        ap(lift4(f, o1, o2, o3, o4), o5)

    ///
    /// Applies the 6-ary function `f` to the values in `o1`, `o2`, ... `o6`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o6` are errors.
    ///
    pub def lift6(f: (t1, t2, t3, t4, t5, t6) -> u & ef,
                  o1: CsvRowSetter[t1],
                  o2: CsvRowSetter[t2],
                  o3: CsvRowSetter[t3],
                  o4: CsvRowSetter[t4],
                  o5: CsvRowSetter[t5],
                  o6: CsvRowSetter[t6]): CsvRowSetter[u] =
        ap(lift5(f, o1, o2, o3, o4, o5), o6)

    ///
    /// Applies the 7-ary function `f` to the values in `o1`, `o2`, ... `o7`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o7` are errors.
    ///
    pub def lift7(f: (t1, t2, t3, t4, t5, t6, t7) -> u & ef,
                  o1: CsvRowSetter[t1],
                  o2: CsvRowSetter[t2],
                  o3: CsvRowSetter[t3],
                  o4: CsvRowSetter[t4],
                  o5: CsvRowSetter[t5],
                  o6: CsvRowSetter[t6],
                  o7: CsvRowSetter[t7]): CsvRowSetter[u] =
        ap(lift6(f, o1, o2, o3, o4, o5, o6), o7)

    ///
    /// Applies the 8-ary function `f` to the values in `o1`, `o2`, ... `o8`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o8` are errors.
    ///
    pub def lift8(f: (t1, t2, t3, t4, t5, t6, t7, t8) -> u & ef,
                  o1: CsvRowSetter[t1],
                  o2: CsvRowSetter[t2],
                  o3: CsvRowSetter[t3],
                  o4: CsvRowSetter[t4],
                  o5: CsvRowSetter[t5],
                  o6: CsvRowSetter[t6],
                  o7: CsvRowSetter[t7],
                  o8: CsvRowSetter[t8]): CsvRowSetter[u] =
        ap(lift7(f, o1, o2, o3, o4, o5, o6, o7), o8)

    ///
    /// Applies the 9-ary function `f` to the values in `o1`, `o2`, ... `o9`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o9` are errors.
    ///
    pub def lift9(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> u & ef,
                  o1: CsvRowSetter[t1],
                  o2: CsvRowSetter[t2],
                  o3: CsvRowSetter[t3],
                  o4: CsvRowSetter[t4],
                  o5: CsvRowSetter[t5],
                  o6: CsvRowSetter[t6],
                  o7: CsvRowSetter[t7],
                  o8: CsvRowSetter[t8],
                  o9: CsvRowSetter[t9]): CsvRowSetter[u] =
        ap(lift8(f, o1, o2, o3, o4, o5, o6, o7, o8), o9)

    ///
    /// Applies the 10-ary function `f` to the values in `o1`, `o2`, ... `o10`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o10` are errors.
    ///
    pub def lift10(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> u & ef,
                   o1: CsvRowSetter[t1],
                   o2: CsvRowSetter[t2],
                   o3: CsvRowSetter[t3],
                   o4: CsvRowSetter[t4],
                   o5: CsvRowSetter[t5],
                   o6: CsvRowSetter[t6],
                   o7: CsvRowSetter[t7],
                   o8: CsvRowSetter[t8],
                   o9: CsvRowSetter[t9],
                   o10: CsvRowSetter[t10]): CsvRowSetter[u] =
        ap(lift9(f, o1, o2, o3, o4, o5, o6, o7, o8, o9), o10)


}

