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

use FactIO/Internal/Jdbc.Output;
use FactIO/Internal/Jdbc.Output.{Output};
use FactIO/Internal/Jdbc.PreparedStatement;
use FactIO/Internal/Jdbc.PreparedStatement.{PreparedStatement};

namespace FactIO/Internal/Jdbc {

    pub opaque type Output = ##flix.runtime.spt.factio.jdbc.JdbcOutput
}

namespace FactIO/Internal/Jdbc/Output {

    ///
    /// Returns a new Output handle.
    ///
    pub def new(url: String): Result[Output, System.Error] & Impure =
        import new flix.runtime.spt.factio.jdbc.JdbcOutput(String) as newOutput;
        try {
            let ans = Output(newOutput(url));
            Ok(ans)
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("Output.new"))
        }

    ///
    /// Close the internal connection to the DB.
    ///
    pub def close(x: Output): Result[Unit, System.Error] & Impure =
        import flix.runtime.spt.factio.jdbc.JdbcOutput.close();
        try {
            let Output(x1) = x;
            x1.close();
            Ok()
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("Output.close"))
        }

    pub def setAutoCommit(x: Output, autoCommit: Bool): Result[Unit, System.Error] & Impure =
        import flix.runtime.spt.factio.jdbc.JdbcOutput.setAutoCommit(Bool);
        try {
            let Output(x1) = x;
            x1.setAutoCommit(autoCommit);
            Ok()
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("Output.setAutoCommit"))
        }

    pub def commit(x: Output): Result[Unit, System.Error] & Impure =
        import flix.runtime.spt.factio.jdbc.JdbcOutput.commit();
        try {
            let Output(x1) = x;
            x1.commit();
            Ok()
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("Output.commit"))
        }

    pub def rollback(x: Output): Result[Unit, System.Error] & Impure =
        import flix.runtime.spt.factio.jdbc.JdbcOutput.rollback();
        try {
            let Output(x1) = x;
            x1.rollback();
            Ok()
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("Output.rollback"))
        }

    pub def prepareStatement(x: Output, sql: String): Result[PreparedStatement, System.Error] & Impure =
        import flix.runtime.spt.factio.jdbc.JdbcOutput.prepareStatement(String);
        try {
            let Output(x1) = x;
            let ans = x1.prepareStatement(sql);
            Ok(PreparedStatement(ans))
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("Output.prepareStatement"))
        }

    pub def execute(x: Output, sql: String): Result[Bool, System.Error] & Impure =
        import flix.runtime.spt.factio.jdbc.JdbcOutput.execute(String);
        try {
            let Output(x1) = x;
            let ans = x1.execute(sql);
            Ok(ans)
        } catch {
            case _: ##java.sql.SQLException => Err(Generic("Output.execute"))
        }

}