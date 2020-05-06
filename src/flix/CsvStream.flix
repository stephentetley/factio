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

use System.Charset;
use System.Charset.{Charset};

use FactIO.CsvFormat;
use FactIO/CsvImport.CsvRow;
use FactIO/CsvImport.CsvRow.{CsvRow};

/// General streaming reader for Csv.

namespace FactIO/CsvStream {


    ///
    /// Returns a new Csv Stream.
    ///
    pub def newCsvStream(filepath: String, format: CsvFormat, hasHeaders: Bool): Result[Stream[CsvRow], String] & Impure=
        import new flix.runtime.factio.CsvIterator(String, Int32, Bool) as newCsvIterator;
        import flix.runtime.factio.CsvIterator.hasNext() as ffiHasNext;
        import flix.runtime.factio.CsvIterator.next() as ffiNext;
        import flix.runtime.factio.CsvIterator.close() as ffiClose;
        try {
            let fmt = FactIO/CsvFormat.toInt32(format);
            let iter = newCsvIterator(filepath, fmt, hasHeaders);
            let streamiter =  {
                  hasNext = () -> ffiHasNext(iter)
                , next = () -> { let a = ffiNext(iter); CsvRow(a) }
                , finalize = () -> ffiClose(iter)
            };
            Ok(Stream.fromIterator(streamiter))
        } catch {
            case _: ##java.io.FileNotFoundException => Err("newCsvStream - file not found")
            case _: ##java.io.IOException => Err("newCsvStream - io exception")
        }

    ///
    /// Returns a new Csv Stream from a file with a BOM.
    ///
    pub def newCsvStreamWithBOM(filepath: String, cs: Charset, hasHeaders: Bool): Result[Stream[CsvRow], String] & Impure =
        import new flix.runtime.factio.CsvIterator(String, ##java.nio.charset.Charset, Bool) as newCsvIterator;
        import flix.runtime.factio.CsvIterator.hasNext() as ffiHasNext;
        import flix.runtime.factio.CsvIterator.next() as ffiNext;
        import flix.runtime.factio.CsvIterator.close() as ffiClose;
        try {
            let Charset(cs1) = cs;
            let iter = newCsvIterator(filepath, cs1, hasHeaders);
            let streamiter =  {
                  hasNext = () -> ffiHasNext(iter)
                , next = () -> { let a = ffiNext(iter); CsvRow(a) }
                , finalize = () -> ffiClose(iter)
            };
            Ok(Stream.fromIterator(streamiter))
        } catch {
            case _: ##java.io.FileNotFoundException => Err("newCsvStream - file not found")
            case _: ##java.io.IOException => Err("newCsvStream - io exception")
        }


}