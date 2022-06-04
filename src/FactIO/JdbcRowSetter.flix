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

    pub enum JdbcRowSetter[a](PreparedStatement -> Result[a, String] & Impure)

    instance Functor[JdbcRowSetter] {
        pub def map(f: a -> b & ef, x: JdbcRowSetter[a]): JdbcRowSetter[b] & ef =
            FactIO/JdbcRowSetter.map(f, x)
    }

    instance Applicative[JdbcRowSetter] {
        pub def point(x: a): JdbcRowSetter[a] =
            FactIO/JdbcRowSetter.point(x)

        pub def ap(mf: JdbcRowSetter[a -> b & ef], ma: JdbcRowSetter[a]): JdbcRowSetter[b] & ef =
            FactIO/JdbcRowSetter.ap(mf, ma)
    }

    instance Monad[JdbcRowSetter] {
        pub def flatMap(k: a -> JdbcRowSetter[b] & ef, x: JdbcRowSetter[a]): JdbcRowSetter[b] & ef = 
            FactIO/JdbcRowSetter.flatMap(k, x)
    }

}

namespace FactIO/JdbcRowSetter {

    use FactIO.JdbcRowSetter;
    use FactIO.JdbcRowSetter.{JdbcRowSetter};

    use FactIO/Internal/Jdbc.PreparedStatement;
    use FactIO/Internal/Jdbc.PreparedStatement.{PreparedStatement};

    pub def point(x: a): JdbcRowSetter[a] =
        JdbcRowSetter(_ -> Ok(x) as & Impure)

    def apply1(x: JdbcRowSetter[a], r: PreparedStatement): Result[a, String] & Impure =
        let JdbcRowSetter(f) = x;
        f(r)

    pub def map(f: a -> b & ef, x: JdbcRowSetter[a]): JdbcRowSetter[b] & ef =
        JdbcRowSetter(r ->
            match apply1(x, r) {
                case Ok(a) => {
                    let ans = f(a) as & Pure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        ) as & ef

    pub def ap(mf: JdbcRowSetter[a -> b & ef], ma: JdbcRowSetter[a]): JdbcRowSetter[b] & ef =
        JdbcRowSetter(r ->
            match apply1(mf, r) {
                case Ok(f) => {
                    match apply1(ma, r) {
                        case Ok(a) => Ok(f(a) as & Pure)
                        case Err(e2) => Err(e2)
                    }
                }
                case Err(e1) => Err(e1)
            }
        ) as & ef

    pub def bind(x: JdbcRowSetter[a], k: a -> JdbcRowSetter[b] & ef): JdbcRowSetter[b] & ef=
        JdbcRowSetter(r ->
            match apply1(x, r) {
                case Ok(a) => { let ans = k(a) as & Impure; apply1(ans, r) }
                case Err(e) => Err(e)
            }
        ) as & ef

    pub def flatMap(k: a -> JdbcRowSetter[b] & ef, x: JdbcRowSetter[a]): JdbcRowSetter[b] & ef = bind(x, k)

    def liftOptionPrim(update: PreparedStatement -> Option[a] & Impure, errMsg: String): JdbcRowSetter[a] =
        JdbcRowSetter(r -> Option.toOk(errMsg, update(r)))

    // Note - the primitive setX! functions index from 1, we add 1 to calls
    // so FactIO's API indexes from 0.

    pub def putNull!(ix: Int32): JdbcRowSetter[Unit] =
        use FactIO/Internal/Jdbc/PreparedStatement.{sql_type_null};
        liftOptionPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setNull!(x, ix + 1, sql_type_null()), "putNull!(${ix})")

    pub def putString!(ix: Int32, str: String): JdbcRowSetter[Unit] =
        liftOptionPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setString!(x, ix + 1, str), "putString!(${ix})")

    pub def putBool!(ix: Int32, b: Bool): JdbcRowSetter[Unit] =
        liftOptionPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setBool!(x, ix + 1, b), "putBool!(${ix})")

    pub def putInt8!(ix: Int32, n: Int8): JdbcRowSetter[Unit] =
        liftOptionPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setInt8!(x, ix + 1, n), "putInt8!(${ix})")

    pub def putInt16!(ix: Int32, n: Int16): JdbcRowSetter[Unit] =
        liftOptionPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setInt16!(x, ix + 1, n), "putInt16!(${ix})")

    pub def putInt32!(ix: Int32, n: Int32): JdbcRowSetter[Unit] =
        liftOptionPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setInt32!(x, ix + 1, n), "putInt32!(${ix})")

    pub def putInt64!(ix: Int32, n: Int64): JdbcRowSetter[Unit] =
        liftOptionPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setInt64!(x, ix + 1, n), "putInt64!(${ix})")

    pub def putFloat32!(ix: Int32, n: Float32): JdbcRowSetter[Unit] =
        liftOptionPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setFloat32!(x, ix + 1, n), "putFloat32!(${ix})")

    pub def putFloat64!(ix: Int32, n: Float64): JdbcRowSetter[Unit] =
        liftOptionPrim(x -> FactIO/Internal/Jdbc/PreparedStatement.setFloat64!(x, ix + 1, n), "putFloat64!(${ix})")



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


}
