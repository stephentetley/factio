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

package flixspt.factio.csv;

import java.math.BigInteger;
import org.apache.commons.csv.CSVRecord;


public class CsvRow {

    private CSVRecord wrappedRow;

    public CsvRow(CSVRecord row) {
        this.wrappedRow = row;
    }

    public boolean isEmptyRow() {
        int sz = this.wrappedRow.size();
        boolean empty = true;
        String s = null;
        for(int i = 0; i < sz; i++){
            s = this.wrappedRow.get(i);
            if (!s.isEmpty()) {
                empty = false;
                break;
            }
        }
        return empty;
    }

    public String getStringAt(int ix) {
        return this.wrappedRow.get(ix);
    }

    public String getStringNamed(String columnLabel) {
        return this.wrappedRow.get(columnLabel);
    }

    public byte getByteAt(int ix) throws Exception {
        String input = this.wrappedRow.get(ix);
        return Byte.parseByte(input.trim());
    }

    public byte getByteNamed(String columnLabel) throws Exception {
        String input = this.wrappedRow.get(columnLabel);
        return Byte.parseByte(input.trim());
    }

    public short getShortAt(int ix) throws Exception {
        String input = this.wrappedRow.get(ix);
        return Short.parseShort(input.trim());
    }

    public short getShortNamed(String columnLabel) throws Exception {
        String input = this.wrappedRow.get(columnLabel);
        return Short.parseShort(input.trim());
    }

    public int getIntAt(int ix) throws Exception {
        String input = this.wrappedRow.get(ix);
        return Integer.parseInt(input.trim());
    }

    public int getIntNamed(String columnLabel) throws Exception {
        String input = this.wrappedRow.get(columnLabel);
        return Integer.parseInt(input.trim());
    }

    public long getLongAt(int ix) throws Exception {
        String input = this.wrappedRow.get(ix);
        return Long.parseLong(input.trim());
    }

    public long getLongNamed(String columnLabel) throws Exception {
        String input = this.wrappedRow.get(columnLabel);
        return Long.parseLong(input.trim());
    }

    public float getFloatAt(int ix) throws Exception {
        String input = this.wrappedRow.get(ix);
        return Float.parseFloat(input.trim());
    }

    public float getFloatNamed(String columnLabel) throws Exception {
        String input = this.wrappedRow.get(columnLabel);
        return Float.parseFloat(input.trim());
    }

    public double getDoubleAt(int ix) throws Exception {
        String input = this.wrappedRow.get(ix);
        return Double.parseDouble(input.trim());
    }

    public double getDoubleNamed(String columnLabel) throws Exception {
        String input = this.wrappedRow.get(columnLabel);
        return Double.parseDouble(input.trim());
    }

    public BigInteger getBigIntegerAt(int ix) throws Exception {
        String input = this.wrappedRow.get(ix);
        return new BigInteger(input.trim());
    }

    public BigInteger getBigIntegerNamed(String columnLabel) throws Exception {
        String input = this.wrappedRow.get(columnLabel);
        return new BigInteger(input.trim());
    }

}
