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

use System.Error.{ArrayIndexOutOfBoundsException, IllegalArgumentException, IllegalStateException, IOException, Generic};
use Text.Charset.{Charset};

use FactIO.CsvFormat;

use FactIO.CsvRowEvaluator;
use FactIO.CsvRowEvaluator.{CsvRowEvaluator};

namespace FactIO { 

    pub opaque type CsvRowEvaluator[a] = ##flix.runtime.factio.CsvRow ~> Result[a, System.Error]
}


namespace FactIO/CsvRowEvaluator {


    pub def return(x: a): CsvRowEvaluator[a] = 
        CsvRowEvaluator(_ -> Ok(x) as & Impure)

    def apply1(x: CsvRowEvaluator[a], r: ##flix.runtime.factio.CsvRow): Result[a, System.Error] & Impure =
        let CsvRowEvaluator(f) = x;
        f(r)

    pub def map(f: a -> b & e, x: CsvRowEvaluator[a]): CsvRowEvaluator[b] =
        CsvRowEvaluator(r -> 
            match apply1(x, r) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )        

    pub def ap(mf: CsvRowEvaluator[a -> b], ma: CsvRowEvaluator[a]): CsvRowEvaluator[b] =
        CsvRowEvaluator(r -> 
            match apply1(mf, r) {
                case Ok(f) => { 
                    match apply1(ma, r) {
                        case Ok(a) => Ok(f(a))
                        case Err(e2) => Err(e2)
                    }
                }
                case Err(e1) => Err(e1)
            }
        )

    pub def bind(x: CsvRowEvaluator[a], k: a -> CsvRowEvaluator[b]): CsvRowEvaluator[b] = 
        CsvRowEvaluator(r -> 
            match apply1(x, r) { 
                case Ok(a) => { let ans = k(a); apply1(ans, r) }
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> CsvRowEvaluator[b], x: CsvRowEvaluator[a]): CsvRowEvaluator[b] = bind(x, k)

    def liftPrimRowReader(eval: ##flix.runtime.factio.CsvRow ~> Result[a, System.Error]): CsvRowEvaluator[a] = 
        CsvRowEvaluator(r -> eval(r))

    // Cell readers

    pub def getStringByIndex(ix: Int32): CsvRowEvaluator[String] =
        import flix.runtime.factio.CsvRow.getStringByIndex(Int32);
        liftPrimRowReader(row -> 
            try {
                let a = row.getStringByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.lang.ArrayIndexOutOfBoundsException => Err(ArrayIndexOutOfBoundsException)
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    ///
    /// Get a string by its column name / label.
    ///
    pub def getStringByLabel(label: String): CsvRowEvaluator[String] =
        import flix.runtime.factio.CsvRow.getStringByLabel(String);
        liftPrimRowReader(row -> 
            try {
                let a = row.getStringByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
                case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
            }
        )

    pub def getInt8ByIndex(ix: Int32): CsvRowEvaluator[Int8] =
        import flix.runtime.factio.CsvRow.getByteByIndex(Int32);
        liftPrimRowReader(row -> 
            try {
                let a = row.getByteByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.lang.ArrayIndexOutOfBoundsException => Err(ArrayIndexOutOfBoundsException)
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt8ByLabel(label: String): CsvRowEvaluator[Int8] =
        import flix.runtime.factio.CsvRow.getByteByLabel(String);
        liftPrimRowReader(row -> 
            try {
                let a = row.getByteByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
                case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
            }
        )

    pub def getInt16ByIndex(ix: Int32): CsvRowEvaluator[Int16] =
        import flix.runtime.factio.CsvRow.getShortByIndex(Int32);
        liftPrimRowReader(row -> 
            try {
                let a = row.getShortByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.lang.ArrayIndexOutOfBoundsException => Err(ArrayIndexOutOfBoundsException)
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt16ByLabel(label: String): CsvRowEvaluator[Int16] =
        import flix.runtime.factio.CsvRow.getShortByLabel(String);
        liftPrimRowReader(row -> 
            try {
                let a = row.getShortByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
                case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
            }
        )

    pub def getInt32ByIndex(ix: Int32): CsvRowEvaluator[Int32] =
        import flix.runtime.factio.CsvRow.getIntByIndex(Int32);
        liftPrimRowReader(row -> 
            try {
                let a = row.getIntByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.lang.ArrayIndexOutOfBoundsException => Err(ArrayIndexOutOfBoundsException)
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt32ByLabel(label: String): CsvRowEvaluator[Int32] =
        import flix.runtime.factio.CsvRow.getIntByLabel(String);
        liftPrimRowReader(row -> 
            try {
                let a = row.getIntByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
                case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
            }
        )

    pub def getInt64ByIndex(ix: Int32): CsvRowEvaluator[Int64] =
        import flix.runtime.factio.CsvRow.getLongByIndex(Int32);
        liftPrimRowReader(row -> 
            try {
                let a = row.getLongByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.lang.ArrayIndexOutOfBoundsException => Err(ArrayIndexOutOfBoundsException)
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt64ByLabel(label: String): CsvRowEvaluator[Int64] =
        import flix.runtime.factio.CsvRow.getLongByLabel(String);
        liftPrimRowReader(row -> 
            try {
                let a = row.getLongByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
                case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
            }
        )

    pub def getFloat32ByIndex(ix: Int32): CsvRowEvaluator[Float32] =
        import flix.runtime.factio.CsvRow.getFloatByIndex(Int32);
        liftPrimRowReader(row -> 
            try {
                let a = row.getFloatByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.lang.ArrayIndexOutOfBoundsException => Err(ArrayIndexOutOfBoundsException)
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getFloat32ByLabel(label: String): CsvRowEvaluator[Float32] =
        import flix.runtime.factio.CsvRow.getFloatByLabel(String);
        liftPrimRowReader(row -> 
            try {
                let a = row.getFloatByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
                case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
            }
        )

    pub def getFloat64ByIndex(ix: Int32): CsvRowEvaluator[Float64] =
        import flix.runtime.factio.CsvRow.getDoubleByIndex(Int32);
        liftPrimRowReader(row -> 
            try {
                let a = row.getDoubleByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.lang.ArrayIndexOutOfBoundsException => Err(ArrayIndexOutOfBoundsException)
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getFloat64ByLabel(label: String): CsvRowEvaluator[Float64] =
        import flix.runtime.factio.CsvRow.getDoubleByLabel(String);
        liftPrimRowReader(row -> 
            try {
                let a = row.getDoubleByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
                case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
            }
        )

    pub def getBigIntByIndex(ix: Int32): CsvRowEvaluator[BigInt] =
        import flix.runtime.factio.CsvRow.getBigIntegerByIndex(Int32);
        liftPrimRowReader(row -> 
            try {
                let a = row.getBigIntegerByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.lang.ArrayIndexOutOfBoundsException => Err(ArrayIndexOutOfBoundsException)
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getBigIntByLabel(label: String): CsvRowEvaluator[BigInt] =
        import flix.runtime.factio.CsvRow.getBigIntegerByLabel(String);        
        liftPrimRowReader(row -> 
            try {
                let a = row.getBigIntegerByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
                case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
            }
        )


}