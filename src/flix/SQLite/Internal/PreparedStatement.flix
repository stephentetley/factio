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

use FactIO/SQLite/Internal.PreparedStatement;
use FactIO/SQLite/Internal.PreparedStatement.{PreparedStatement};

namespace FactIO/SQLite/Internal {

     pub opaque type PreparedStatement = ##java.sql.PreparedStatement
}

namespace FactIO/SQLite/Internal/PreparedStatement {

    pub def clearParameters!(x: PreparedStatement): Result[Unit, System.Error] & Impure =
        import java.sql.PreparedStatement.clearParameters();
        try {
            let PreparedStatement(x1) = x;
            x1.clearParameters();
            Ok()
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("SQLException.clearParameters"))
        }

    pub def setString!(x: PreparedStatement, ix: Int32, str: String): Result[Unit, System.Error] & Impure =
        import java.sql.PreparedStatement.setString(Int32, String);
        try {
            let PreparedStatement(x1) = x;
            x1.setString(ix, str);
            Ok()
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("SQLException"))
        }

    pub def setBool!(x: PreparedStatement, ix: Int32, b: Bool): Result[Unit, System.Error] & Impure =
        import java.sql.PreparedStatement.setBoolean(Int32, Bool);
        try {
            let PreparedStatement(x1) = x;
            x1.setBoolean(ix, b);
            Ok()
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("SQLException"))
        }

    pub def setInt8!(x: PreparedStatement, ix: Int32, n: Int8): Result[Unit, System.Error] & Impure =
        import java.sql.PreparedStatement.setByte(Int32, Int8);
        try {
            let PreparedStatement(x1) = x;
            x1.setByte(ix, n);
            Ok()
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("SQLException"))
        }

    pub def setInt16!(x: PreparedStatement, ix: Int32, n: Int16): Result[Unit, System.Error] & Impure =
        import java.sql.PreparedStatement.setShort(Int32, Int16);
        try {
            let PreparedStatement(x1) = x;
            x1.setShort(ix, n);
            Ok()
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("SQLException"))
        }

    pub def setInt32!(x: PreparedStatement, ix: Int32, n: Int32): Result[Unit, System.Error] & Impure =
        import java.sql.PreparedStatement.setInt(Int32, Int32);
        try {
            let PreparedStatement(x1) = x;
            x1.setInt(ix, n);
            Ok()
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("SQLException"))
        }

    pub def setInt64!(x: PreparedStatement, ix: Int32, n: Int64): Result[Unit, System.Error] & Impure =
        import java.sql.PreparedStatement.setLong(Int32, Int64);
        try {
            let PreparedStatement(x1) = x;
            x1.setLong(ix, n);
            Ok()
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("SQLException"))
        }

    pub def setFloat32!(x: PreparedStatement, ix: Int32, d: Float32): Result[Unit, System.Error] & Impure =
        import java.sql.PreparedStatement.setFloat(Int32, Float32);
        try {
            let PreparedStatement(x1) = x;
            x1.setFloat(ix, d);
            Ok()
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("SQLException"))
        }

    pub def setFloat64!(x: PreparedStatement, ix: Int32, d: Float64): Result[Unit, System.Error] & Impure =
        import java.sql.PreparedStatement.setDouble(Int32, Float64);
        try {
            let PreparedStatement(x1) = x;
            x1.setDouble(ix, d);
            Ok()
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("SQLException"))
        }


    pub def executeUpdate(x: PreparedStatement): Result[Int32, System.Error] & Impure =
        import java.sql.PreparedStatement.executeUpdate();
        try {
            let PreparedStatement(x1) = x;
            let ans = x1.executeUpdate();
            Ok(ans)
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("PreparedStatement.executeUpdate"))
        }


}

