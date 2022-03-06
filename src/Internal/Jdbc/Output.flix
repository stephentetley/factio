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

    pub opaque type Output = ##flixspt.factio.jdbc.JdbcOutput
}

namespace FactIO/Internal/Jdbc/Output {

    use FactIO/Internal/Jdbc.Output;
    use FactIO/Internal/Jdbc.Output.{Output};
    use FactIO/Internal/Jdbc.PreparedStatement;
    use FactIO/Internal/Jdbc.PreparedStatement.{PreparedStatement};

    ///
    /// Returns a new Output handle.
    ///
    pub def new(url: String): Option[Output] & Impure =
        import new flixspt.factio.jdbc.JdbcOutput(String): ##flixspt.factio.jdbc.JdbcOutput & Impure as newOutput;
        try {
            let ans = Output(newOutput(url));
            Some(ans)
        } catch {
            case _: ##java.lang.Exception => None
        }

    ///
    /// Close the internal connection to the DB.
    ///
    pub def close(x: Output): Option[Unit] & Impure =
        import flixspt.factio.jdbc.JdbcOutput.close(): Unit & Impure;
        try {
            let Output(x1) = x;
            close(x1);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def setAutoCommit(x: Output, autoCommit: Bool): Option[Unit] & Impure =
        import flixspt.factio.jdbc.JdbcOutput.setAutoCommit(Bool): Unit & Impure;
        try {
            let Output(x1) = x;
            setAutoCommit(x1, autoCommit);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def getAutoCommit(x: Output): Option[Bool] & Impure =
        import flixspt.factio.jdbc.JdbcOutput.getAutoCommit(): Bool & Impure;
        try {
            let Output(x1) = x;
            let ans = getAutoCommit(x1);
            Some(ans)
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def commit(x: Output): Option[Unit] & Impure =
        import flixspt.factio.jdbc.JdbcOutput.commit(): Unit & Impure;
        try {
            let Output(x1) = x;
            commit(x1);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def rollback(x: Output): Option[Unit] & Impure =
        import flixspt.factio.jdbc.JdbcOutput.rollback(): Unit & Impure;
        try {
            let Output(x1) = x;
            rollback(x1);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def prepareStatement(x: Output, sql: String): Option[PreparedStatement] & Impure =
        import flixspt.factio.jdbc.JdbcOutput.prepareStatement(String): ##java.sql.PreparedStatement & Impure;
        try {
            let Output(x1) = x;
            let ans = prepareStatement(x1, sql);
            Some(PreparedStatement(ans))
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def execute(x: Output, sql: String): Option[Bool] & Impure =
        import flixspt.factio.jdbc.JdbcOutput.execute(String): Bool & Impure;
        try {
            let Output(x1) = x;
            let ans = execute(x1, sql);
            Some(ans)
        } catch {
            case _: ##java.lang.Exception => None
        }

}