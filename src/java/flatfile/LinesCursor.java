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

package flix.runtime.spt.factio.flatfile;

import java.io.*;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Iterator;
import java.util.stream.Stream;

public class LinesCursor {

    private BufferedReader bufreader;
    private Iterator<String> iter;

    public LinesCursor(Path path, Charset cs) throws Exception {
        bufreader = Files.newBufferedReader(path, cs);
        Stream<String> stream = bufreader.lines();
        this.iter = stream.iterator();

    }

    public boolean hasNext() {
        return this.iter.hasNext();
    }

    public String next() throws Exception { return this.iter.next(); }

    public void close() throws Exception { bufreader.close(); }

}
