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

package flix.runtime.factimport;

import java.sql.ResultSet;

public class SQLiteRow {
    private ResultSet rs = null;

    protected SQLiteRow(ResultSet resultSet) {
        this.rs = resultSet;
    }

    // Zero indexed
    public String getStringByIndex(int ix) throws Exception {
        return this.rs.getString(ix+1);
    }

    public String getStringByLabel(String columnLabel) throws Exception {
        return this.rs.getString(columnLabel);
    }

    // Zero indexed
    public byte getByteByIndex(int ix) throws Exception {
        return this.rs.getByte(ix+1);
    }

    public byte getByteByLabel(String columnLabel) throws Exception {
        return this.rs.getByte(columnLabel);
    }

    // Zero indexed
    public short getShortByIndex(int ix) throws Exception {
        return this.rs.getShort(ix+1);
    }

    public short getShortByLabel(String columnLabel) throws Exception {
        return this.rs.getShort(columnLabel);
    }

    // Zero indexed
    public int getIntByIndex(int ix) throws Exception {
        return this.rs.getInt(ix+1);
    }

    public int getIntByLabel(String columnLabel) throws Exception {
        return this.rs.getInt(columnLabel);
    }

    // Zero indexed
    public long getLongByIndex(int ix) throws Exception {
        return this.rs.getLong(ix+1);
    }

    public long getLongByLabel(String columnLabel) throws Exception {
        return this.rs.getLong(columnLabel);
    }

    // Zero indexed
    public float getFloatByIndex(int ix) throws Exception {
        return this.rs.getFloat(ix+1);
    }

    public float getFloatByLabel(String columnLabel) throws Exception {
        return this.rs.getFloat(columnLabel);
    }

    // Zero indexed
    public double getDoubleByIndex(int ix) throws Exception {
        return this.rs.getDouble(ix+1);
    }

    public double getDoubleByLabel(String columnLabel) throws Exception {
        return this.rs.getDouble(columnLabel);
    }

}
