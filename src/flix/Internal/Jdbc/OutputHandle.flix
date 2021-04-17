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

    pub opaque type OutputHandle = ##flix.runtime.spt.factio.jdbc.JdbcOutput
}

namespace FactIO/Internal/Jdbc/OutputHandle {

    use FactIO/Internal/Jdbc.OutputHandle;
    use FactIO/Internal/Jdbc.OutputHandle.{OutputHandle};
    use FactIO/Internal/Jdbc.PreparedStatement;
    use FactIO/Internal/Jdbc.PreparedStatement.{PreparedStatement};

    ///
    /// Returns a new Output handle.
    ///
    pub def new(url: String): Option[OutputHandle] & Impure =
        import new flix.runtime.spt.factio.jdbc.JdbcOutput(String) as newOutput;
        try {
            let ans = OutputHandle(newOutput(url));
            Some(ans)
        } catch {
            case _: ##java.lang.Exception => None
        }

    ///
    /// Close the internal connection to the DB.
    ///
    pub def close!(x: OutputHandle): Option[Unit] & Impure =
        import flix.runtime.spt.factio.jdbc.JdbcOutput.close();
        try {
            let OutputHandle(x1) = x;
            close(x1);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def setAutoCommit!(x: OutputHandle, autoCommit: Bool): Option[Unit] & Impure =
        import flix.runtime.spt.factio.jdbc.JdbcOutput.setAutoCommit(Bool);
        try {
            let OutputHandle(x1) = x;
            setAutoCommit(x1, autoCommit);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def getAutoCommit(x: OutputHandle): Option[Bool] & Impure =
        import flix.runtime.spt.factio.jdbc.JdbcOutput.getAutoCommit();
        try {
            let OutputHandle(x1) = x;
            let ans = getAutoCommit(x1);
            Some(ans)
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def commit!(x: OutputHandle): Option[Unit] & Impure =
        import flix.runtime.spt.factio.jdbc.JdbcOutput.commit();
        try {
            let OutputHandle(x1) = x;
            commit(x1);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def rollback!(x: OutputHandle): Option[Unit] & Impure =
        import flix.runtime.spt.factio.jdbc.JdbcOutput.rollback();
        try {
            let OutputHandle(x1) = x;
            rollback(x1);
            Some()
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def prepareStatement(x: OutputHandle, sql: String): Option[PreparedStatement] & Impure =
        import flix.runtime.spt.factio.jdbc.JdbcOutput.prepareStatement(String);
        try {
            let OutputHandle(x1) = x;
            let ans = prepareStatement(x1, sql);
            Some(PreparedStatement(ans))
        } catch {
            case _: ##java.lang.Exception => None
        }

    pub def execute!(x: OutputHandle, sql: String): Option[Bool] & Impure =
        import flix.runtime.spt.factio.jdbc.JdbcOutput.execute(String);
        try {
            let OutputHandle(x1) = x;
            let ans = execute(x1, sql);
            Some(ans)
        } catch {
            case _: ##java.lang.Exception => None
        }

}
