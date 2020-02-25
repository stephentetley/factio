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

import java.io.*;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class LinesIterator {

    private BufferedReader bufreader;
    private String currentLine;

    public LinesIterator(String filepath, Charset cs) throws Exception {
        try {
            Path path = Paths.get(filepath, new String[0]);
            this.bufreader = Files.newBufferedReader(path, cs);
        } catch (IOException ex) {
            ex.printStackTrace();
            throw new IOException();
        }
    }

    public boolean hasNext() throws Exception {
        this.currentLine = bufreader.readLine();
        return(this.currentLine != null);
    }

    public String getLine() {
        return this.currentLine;
    }

    public void close() throws Exception {
        this.bufreader.close();
        return;
    }
}
