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

use Text.Charset.{Charset};

use System.Error.{IOException, IllegalStateException, Generic};

use FactIO/Internal.LinesIterator;
use FactIO/Internal.LinesIterator.{LinesIterator};

namespace FactIO/Internal { 
    
    pub opaque type LinesIterator = ##flix.runtime.spt.factio.flatfile.LinesIterator

}


namespace FactIO/Internal/LinesIterator {

    
    pub def newLinesIterator(filepath: String, cs: Text.Charset): Result[LinesIterator, System.Error] & Impure=
        import new flix.runtime.spt.factio.flatfile.LinesIterator(String, ##java.nio.charset.Charset) as newLinesIterator;
        try {
            let Charset(cs1) = cs;
            let iter = newLinesIterator(filepath, cs1);
            Ok(LinesIterator(iter))
        } catch {
            case _: ##java.io.FileNotFoundException => Err(Generic("FileNotFoundException"))
            case _: ##java.io.IOException => Err(IOException)
        }

    
    pub def readLine(x: LinesIterator): Result[String, System.Error] & Impure = 
        import flix.runtime.spt.factio.flatfile.LinesIterator.next();
        try { 
            let LinesIterator(x1) = x;
            let s = x1.next();
            if (Object.isNull(s))
                Err(IllegalStateException)
            else
                Ok(s)
        } catch { 
            case _:##java.io.IOException => Err(IOException)
        }

    pub def hasNext(x: LinesIterator): Bool & Impure = 
        import flix.runtime.spt.factio.flatfile.LinesIterator.hasNext();
        let LinesIterator(x1) = x;
        x1.hasNext()
        
    ///
    /// Returns a new string line Stream.
    ///
    pub def close(x: LinesIterator): Result[Unit, System.Error] & Impure=
        import flix.runtime.spt.factio.flatfile.LinesIterator.close();
        try {
            let LinesIterator(x1) = x;
            let _ = x1.close();
            Ok()
        } catch {
            case _: ##java.io.IOException => Err(IOException)
        }

}