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





namespace FactIO/JdbcExport {


    use Text.Charset.{Charset};

    use FactIO/Internal/Jdbc.OutputHandle;
    use FactIO.JdbcRowSetter;
    use FactIO.JdbcRowSetter.{JdbcRowSetter};

    type alias PreparedStatement = FactIO/Internal/Jdbc.PreparedStatement

    pub def exportJdbc(setupStmts: List[String],
                        insertStmt: String,
                        rowWriter: a -> JdbcRowSetter[Unit],
                        rows: Array[a],
                        url: String): Result[Unit, String] & Impure =
        use Result.flatMap;
        use FactIO/Internal/Jdbc/OutputHandle.{new => newOutput, setAutoCommit!, prepareStatement, commit!, close!, rollback!};
        let* handle = Option.toOk(newOutput(url), "exportJdbc - Could not connect to '${url}'");
        let* _ = Option.toOk(setAutoCommit!(handle, false), "exportJdbc - Could not set AutoCommit to false");
        let* _      = executeSetUpStatements!(handle, setupStmts);
        let* pstmt  = Option.toOk(prepareStatement(handle, insertStmt), "exportJdbc - prepareStmt '${insertStmt}'");
        let* _      = writeRows!(pstmt, rowWriter, rows);
        let* _      = match commit!(handle) {
            case Some() => Ok()
            case None => {rollback!(handle); Ok()}
        };
        let* _      = Option.toOk(close!(handle), "exportJdbc - close!");
        Ok()

    pub def exportSQLite(setupStmts: List[String],
                        insertStmt: String,
                        rowWriter: a -> JdbcRowSetter[Unit],
                        rows: Array[a],
                        dbpath: System.FilePath): Result[Unit, String] & Impure =
        use System/FilePath.{normalize};
        let url = "jdbc:sqlite:${normalize(dbpath)}";
        exportJdbc(setupStmts, insertStmt, rowWriter, rows, url)

    pub def exportDuckDb(setupStmts: List[String],
                        insertStmt: String,
                        rowWriter: a -> JdbcRowSetter[Unit],
                        rows: Array[a],
                        dbpath: System.FilePath): Result[Unit, String] & Impure =
        use System/FilePath.{normalize};
        let url = "jdbc:duckdb:${normalize(dbpath)}";
        exportJdbc(setupStmts, insertStmt, rowWriter, rows, url)

    def executeSetUpStatements!(handle: OutputHandle, setupStmts: List[String]): Result[Unit, String] & Impure =
        use Result.flatMap;
        use FactIO/Internal/Jdbc/OutputHandle.{execute!, commit!};
        match setupStmts {
            case stmt :: Nil => {
                let* _ = Option.toOk(execute!(handle, stmt), "setUpDb! - execute('${stmt}')");
                let* _ = Option.toOk(commit!(handle), "setUpDb! - commit!");
                Ok()
            }
            case stmt :: rs => {
                let* _ = Option.toOk(execute!(handle, stmt), "setUpDb! - execute('${stmt}')");
                executeSetUpStatements!(handle, rs)
            }
            case Nil => Ok()
        }

    def writeRows!(pstmt: PreparedStatement,
                    rowWriter: a -> JdbcRowSetter[Unit],
                    rows: Array[a]): Result[Unit, String] & Impure =
        writeRowsHelper!(pstmt, rowWriter, 0, rows)

    def writeRowsHelper!(pstmt: PreparedStatement,
                        rowWriter: a -> JdbcRowSetter[Unit],
                        ix: Int32,
                        rows: Array[a]): Result[Unit, String] & Impure =
        if (ix < Array.length(rows)) {
            let x = rows[ix];
            let setter = rowWriter(x);
            match writeRow!(pstmt, setter) {
                case Ok() => writeRowsHelper!(pstmt, rowWriter, ix + 1, rows)
                case Err(msg) => Err(msg)
            }
        } else Ok()

    def writeRow!(pstmt: PreparedStatement, mx: JdbcRowSetter[a]): Result[Unit, String] & Impure =
        use Result.{flatMap};
        use FactIO/Internal/Jdbc/PreparedStatement.{clearParameters!, executeUpdate!};
        let* _ = Option.toOk(clearParameters!(pstmt), "writeRow! - clearParameters!");
        let* _ = execJdbcRowSetter!(pstmt, mx);
        let* _ = Option.toOk(executeUpdate!(pstmt), "writeRow! - executeUpdate!");
        Ok()


    def execJdbcRowSetter!(pstmt: PreparedStatement, mx: JdbcRowSetter[a]): Result[Unit, String] & Impure =
        let JdbcRowSetter(mf) = mx;
        match mf(pstmt) {
            case Ok(_) => Ok()
            case Err(e) => Err(e)
        }
 }
