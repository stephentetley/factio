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



namespace FactIO/Internal/Jdbc {

     pub opaque type PreparedStatement = ##java.sql.PreparedStatement
}

namespace FactIO/Internal/Jdbc/PreparedStatement {

    use FactIO/Internal/Jdbc.PreparedStatement;
    use FactIO/Internal/Jdbc.PreparedStatement.{PreparedStatement};

    pub def sql_type_null(): Int32 =
        import get java.sql.Types:NULL as get_NULL;
        get_NULL() as & Pure

    pub def clearParameters!(x: PreparedStatement): Option[Unit] & Impure =
        import java.sql.PreparedStatement.clearParameters();
        try {
            let PreparedStatement(x1) = x;
            clearParameters(x1);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def setNull!(x: PreparedStatement, ix: Int32, sqlType: Int32): Option[Unit] & Impure =
        import java.sql.PreparedStatement.setNull(Int32, Int32);
        try {
            let PreparedStatement(x1) = x;
            setNull(x1, ix, sqlType);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def setString!(x: PreparedStatement, ix: Int32, str: String): Option[Unit] & Impure =
        import java.sql.PreparedStatement.setString(Int32, String);
        try {
            let PreparedStatement(x1) = x;
            setString(x1, ix, str);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def setBool!(x: PreparedStatement, ix: Int32, b: Bool): Option[Unit] & Impure =
        import java.sql.PreparedStatement.setBoolean(Int32, Bool);
        try {
            let PreparedStatement(x1) = x;
            setBoolean(x1, ix, b);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def setInt8!(x: PreparedStatement, ix: Int32, n: Int8): Option[Unit] & Impure =
        import java.sql.PreparedStatement.setByte(Int32, Int8);
        try {
            let PreparedStatement(x1) = x;
            setByte(x1, ix, n);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def setInt16!(x: PreparedStatement, ix: Int32, n: Int16): Option[Unit] & Impure =
        import java.sql.PreparedStatement.setShort(Int32, Int16);
        try {
            let PreparedStatement(x1) = x;
            setShort(x1, ix, n);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def setInt32!(x: PreparedStatement, ix: Int32, n: Int32): Option[Unit] & Impure =
        import java.sql.PreparedStatement.setInt(Int32, Int32);
        try {
            let PreparedStatement(x1) = x;
            setInt(x1, ix, n);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def setInt64!(x: PreparedStatement, ix: Int32, n: Int64): Option[Unit] & Impure =
        import java.sql.PreparedStatement.setLong(Int32, Int64);
        try {
            let PreparedStatement(x1) = x;
            setLong(x1, ix, n);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def setFloat32!(x: PreparedStatement, ix: Int32, d: Float32): Option[Unit] & Impure =
        import java.sql.PreparedStatement.setFloat(Int32, Float32);
        try {
            let PreparedStatement(x1) = x;
            setFloat(x1, ix, d);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def setFloat64!(x: PreparedStatement, ix: Int32, d: Float64): Option[Unit] & Impure =
        import java.sql.PreparedStatement.setDouble(Int32, Float64);
        try {
            let PreparedStatement(x1) = x;
            setDouble(x1, ix, d);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }


    pub def executeUpdate!(x: PreparedStatement): Option[Int32] & Impure =
        import java.sql.PreparedStatement.executeUpdate();
        try {
            let PreparedStatement(x1) = x;
            let ans = executeUpdate(x1);
            Some(ans)
        } catch {
            case _: ##java.lang.Exception => None
        }


}

