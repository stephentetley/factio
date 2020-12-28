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
    
    use FactIO/Internal/Jdbc.PreparedStatement;

    pub opaque type JdbcRowSetter[a] = PreparedStatement ~> Result[a, String]

}

namespace FactIO/JdbcRowSetter {

    use FactIO.JdbcRowSetter;
    use FactIO.JdbcRowSetter.{JdbcRowSetter};

    use FactIO/Internal/Jdbc.PreparedStatement;
    use FactIO/Internal/Jdbc.PreparedStatement.{PreparedStatement};

    pub def return(x: a): JdbcRowSetter[a] =
        JdbcRowSetter(_ -> Ok(x) as & Impure)

    def apply1(x: JdbcRowSetter[a], r: PreparedStatement): Result[a, String] & Impure =
        let JdbcRowSetter(f) = x;
        f(r)

    pub def map(f: a -> b & ef, x: JdbcRowSetter[a]): JdbcRowSetter[b] =
        JdbcRowSetter(r ->
            match apply1(x, r) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )

    pub def ap(mf: JdbcRowSetter[a -> b & ef], ma: JdbcRowSetter[a]): JdbcRowSetter[b] =
        JdbcRowSetter(r ->
            match apply1(mf, r) {
                case Ok(f) => {
                    match apply1(ma, r) {
                        case Ok(a) => Ok(f(a) as & Impure)
                        case Err(e2) => Err(e2)
                    }
                }
                case Err(e1) => Err(e1)
            }
        )

    pub def bind(x: JdbcRowSetter[a], k: a -> JdbcRowSetter[b]): JdbcRowSetter[b] =
        JdbcRowSetter(r ->
            match apply1(x, r) {
                case Ok(a) => { let ans = k(a); apply1(ans, r) }
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> JdbcRowSetter[b], x: JdbcRowSetter[a]): JdbcRowSetter[b] = bind(x, k)

    def liftPrim(update: PreparedStatement ~> Result[a, String]): JdbcRowSetter[a] =
        JdbcRowSetter(r -> update(r))

    // Note - the primitive setX! functions index from 1, we add 1 to calls
    // so FactIO's API indexes from 0.

    pub def putNull!(ix: Int32): JdbcRowSetter[Unit] =
        use FactIO/Internal/Jdbc/PreparedStatement.{sql_type_null};
        liftPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setNull!(x, ix + 1, sql_type_null()))

    pub def putString!(ix: Int32, str: String): JdbcRowSetter[Unit] =
        liftPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setString!(x, ix + 1, str))

    pub def putBool!(ix: Int32, b: Bool): JdbcRowSetter[Unit] =
        liftPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setBool!(x, ix + 1, b))

    pub def putInt8!(ix: Int32, n: Int8): JdbcRowSetter[Unit] =
        liftPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setInt8!(x, ix + 1, n))

    pub def putInt16!(ix: Int32, n: Int16): JdbcRowSetter[Unit] =
        liftPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setInt16!(x, ix + 1, n))

    pub def putInt32!(ix: Int32, n: Int32): JdbcRowSetter[Unit] =
        liftPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setInt32!(x, ix + 1, n))

    pub def putInt64!(ix: Int32, n: Int64): JdbcRowSetter[Unit] =
        liftPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setInt64!(x, ix + 1, n))

    pub def putFloat32!(ix: Int32, n: Float32): JdbcRowSetter[Unit] =
        liftPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setFloat32!(x, ix + 1, n))

    pub def putFloat64!(ix: Int32, n: Float64): JdbcRowSetter[Unit] =
        liftPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setFloat64!(x, ix + 1, n))



    pub def putOptionString!(ix: Int32, x: Option[String]): JdbcRowSetter[Unit] = match x {
        case Some(s) => putString!(ix, s)
        case None => putNull!(ix)
    }

    pub def putOptionBool!(ix: Int32, x: Option[Bool]): JdbcRowSetter[Unit] = match x {
        case Some(b) => putBool!(ix, b)
        case None => putNull!(ix)
    }

    pub def putOptionInt8!(ix: Int32, x: Option[Int8]): JdbcRowSetter[Unit] = match x {
        case Some(n) => putInt8!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionInt16!(ix: Int32, x: Option[Int16]): JdbcRowSetter[Unit] = match x {
        case Some(n) => putInt16!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionInt32!(ix: Int32, x: Option[Int32]): JdbcRowSetter[Unit] = match x {
        case Some(n) => putInt32!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionInt64!(ix: Int32, x: Option[Int64]): JdbcRowSetter[Unit] = match x {
        case Some(n) => putInt64!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionFloat32!(ix: Int32, x: Option[Float32]): JdbcRowSetter[Unit] = match x {
        case Some(n) => putFloat32!(ix, n)
        case None => putNull!(ix)
    }

    pub def putOptionFloat64!(ix: Int32, x: Option[Float64]): JdbcRowSetter[Unit] = match x {
        case Some(n) => putFloat64!(ix, n)
        case None => putNull!(ix)
    }


    ///
    /// Applies the binary function `f` to the values in `o1` and `o2`.
    ///
    /// Returns an error if either `o1` or `o2` are errors.
    ///
    pub def lift2(f: (t1, t2) -> u & ef, o1: JdbcRowSetter[t1], o2: JdbcRowSetter[t2]): JdbcRowSetter[u] =
        ap(map(f, o1), o2)

    ///
    /// Applies the ternary function `f` to the values in `o1`, `o2` and `o3`.
    ///
    /// Returns an error if any of `o1`, `o2` and `o3` are errors.
    ///
    pub def lift3(f: (t1, t2, t3) -> u & ef,
                  o1: JdbcRowSetter[t1],
                  o2: JdbcRowSetter[t2],
                  o3: JdbcRowSetter[t3]): JdbcRowSetter[u] =
        ap(lift2(f, o1, o2), o3)

    ///
    /// Applies the 4-ary function `f` to the values in `o1`, `o2`, `o3` and `o4`.
    ///
    /// Returns an error if any of `o1`, `o2`, `o3` and `o4` are errors.
    ///
    pub def lift4(f: (t1, t2, t3, t4) -> u & ef,
                  o1: JdbcRowSetter[t1],
                  o2: JdbcRowSetter[t2],
                  o3: JdbcRowSetter[t3],
                  o4: JdbcRowSetter[t4]): JdbcRowSetter[u] =
        ap(lift3(f, o1, o2, o3), o4)

    ///
    /// Applies the 5-ary function `f` to the values in `o1`, `o2`, ... `o5`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o5` are errors.
    ///
    pub def lift5(f: (t1, t2, t3, t4, t5) -> u & ef,
                  o1: JdbcRowSetter[t1],
                  o2: JdbcRowSetter[t2],
                  o3: JdbcRowSetter[t3],
                  o4: JdbcRowSetter[t4],
                  o5: JdbcRowSetter[t5]): JdbcRowSetter[u] =
        ap(lift4(f, o1, o2, o3, o4), o5)

    ///
    /// Applies the 6-ary function `f` to the values in `o1`, `o2`, ... `o6`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o6` are errors.
    ///
    pub def lift6(f: (t1, t2, t3, t4, t5, t6) -> u & ef,
                  o1: JdbcRowSetter[t1],
                  o2: JdbcRowSetter[t2],
                  o3: JdbcRowSetter[t3],
                  o4: JdbcRowSetter[t4],
                  o5: JdbcRowSetter[t5],
                  o6: JdbcRowSetter[t6]): JdbcRowSetter[u] =
        ap(lift5(f, o1, o2, o3, o4, o5), o6)

    ///
    /// Applies the 7-ary function `f` to the values in `o1`, `o2`, ... `o7`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o7` are errors.
    ///
    pub def lift7(f: (t1, t2, t3, t4, t5, t6, t7) -> u & ef,
                  o1: JdbcRowSetter[t1],
                  o2: JdbcRowSetter[t2],
                  o3: JdbcRowSetter[t3],
                  o4: JdbcRowSetter[t4],
                  o5: JdbcRowSetter[t5],
                  o6: JdbcRowSetter[t6],
                  o7: JdbcRowSetter[t7]): JdbcRowSetter[u] =
        ap(lift6(f, o1, o2, o3, o4, o5, o6), o7)

    ///
    /// Applies the 8-ary function `f` to the values in `o1`, `o2`, ... `o8`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o8` are errors.
    ///
    pub def lift8(f: (t1, t2, t3, t4, t5, t6, t7, t8) -> u & ef,
                      o1: JdbcRowSetter[t1],
                      o2: JdbcRowSetter[t2],
                      o3: JdbcRowSetter[t3],
                      o4: JdbcRowSetter[t4],
                      o5: JdbcRowSetter[t5],
                      o6: JdbcRowSetter[t6],
                      o7: JdbcRowSetter[t7],
                      o8: JdbcRowSetter[t8]): JdbcRowSetter[u] =
        ap(lift7(f, o1, o2, o3, o4, o5, o6, o7), o8)

    ///
    /// Applies the 9-ary function `f` to the values in `o1`, `o2`, ... `o9`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o9` are errors.
    ///
    pub def lift9(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> u & ef,
                  o1: JdbcRowSetter[t1],
                  o2: JdbcRowSetter[t2],
                  o3: JdbcRowSetter[t3],
                  o4: JdbcRowSetter[t4],
                  o5: JdbcRowSetter[t5],
                  o6: JdbcRowSetter[t6],
                  o7: JdbcRowSetter[t7],
                  o8: JdbcRowSetter[t8],
                  o9: JdbcRowSetter[t9]): JdbcRowSetter[u] =
        ap(lift8(f, o1, o2, o3, o4, o5, o6, o7, o8), o9)

    ///
    /// Applies the 10-ary function `f` to the values in `o1`, `o2`, ... `o10`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o10` are errors.
    ///
    pub def lift10(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> u & ef,
                   o1: JdbcRowSetter[t1],
                   o2: JdbcRowSetter[t2],
                   o3: JdbcRowSetter[t3],
                   o4: JdbcRowSetter[t4],
                   o5: JdbcRowSetter[t5],
                   o6: JdbcRowSetter[t6],
                   o7: JdbcRowSetter[t7],
                   o8: JdbcRowSetter[t8],
                   o9: JdbcRowSetter[t9],
                   o10: JdbcRowSetter[t10]): JdbcRowSetter[u] =
        ap(lift9(f, o1, o2, o3, o4, o5, o6, o7, o8, o9), o10)


}

