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

package flix.runtime.spt.factio.jdbc;

import java.sql.*;

/// Dependency:
/// https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/

public class JdbcIterator {

    private ResultSet rs = null;
    private Statement stmt = null;
    private Connection conn = null;

    public JdbcIterator(String url, String query) throws Exception {
        this.conn = DriverManager.getConnection(url);
        this.stmt = this.conn.createStatement();
        this.rs = this.stmt.executeQuery(query);
    }

    public JdbcRow getRow() {
        return new JdbcRow(this.rs);
    }

    public boolean next() throws Exception {
        return this.rs.next();
    }

    public void close() throws Exception {
        conn.close();
    }
}
