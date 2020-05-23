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

use System.Error.{IOException, Generic};

use FactIO.SQLiteRowEvaluator;
use FactIO.SQLiteRowEvaluator.{SQLiteRowEvaluator};

namespace FactIO { 

    pub opaque type SQLiteRowEvaluator[a] = ##flix.runtime.factio.SQLiteRow ~> Result[a, System.Error]
}


namespace FactIO/SQLiteRowEvaluator {

    pub def return(x: a): SQLiteRowEvaluator[a] = 
        SQLiteRowEvaluator(_ -> Ok(x) as & Impure)

    def apply1(x: SQLiteRowEvaluator[a], r: ##flix.runtime.factio.SQLiteRow): Result[a, System.Error] & Impure =
        let SQLiteRowEvaluator(f) = x;
        f(r)

    pub def map(f: a -> b & e, x: SQLiteRowEvaluator[a]): SQLiteRowEvaluator[b] =
        SQLiteRowEvaluator(r -> 
            match apply1(x, r) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        )        

    pub def ap(mf: SQLiteRowEvaluator[a -> b], ma: SQLiteRowEvaluator[a]): SQLiteRowEvaluator[b] =
        SQLiteRowEvaluator(r -> 
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

    pub def bind(x: SQLiteRowEvaluator[a], k: a -> SQLiteRowEvaluator[b]): SQLiteRowEvaluator[b] = 
        SQLiteRowEvaluator(r -> 
            match apply1(x, r) { 
                case Ok(a) => { let ans = k(a); apply1(ans, r) }
                case Err(e) => Err(e)
            }
        )

    pub def flatMap(k: a -> SQLiteRowEvaluator[b], x: SQLiteRowEvaluator[a]): SQLiteRowEvaluator[b] = bind(x, k)

    def liftPrimRowReader(eval: ##flix.runtime.factio.SQLiteRow ~> Result[a, System.Error]): SQLiteRowEvaluator[a] = 
        SQLiteRowEvaluator(r -> eval(r))
    
    // Cell readers

    pub def getStringByIndex(ix: Int32): SQLiteRowEvaluator[String] =
        import flix.runtime.factio.SQLiteRow.getStringByIndex(Int32);
        liftPrimRowReader(row ->
            try {
                let a = row.getStringByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        ) 

    pub def getStringByLabel(label: String): SQLiteRowEvaluator[String] =
        import flix.runtime.factio.SQLiteRow.getStringByLabel(String);
        liftPrimRowReader(row ->
            try {
                let a = row.getStringByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt8ByIndex(ix: Int32): SQLiteRowEvaluator[Int8] =
        import flix.runtime.factio.SQLiteRow.getByteByIndex(Int32);
        liftPrimRowReader(row ->
            try {
                let a = row.getByteByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt8ByLabel(label: String): SQLiteRowEvaluator[Int8] =
        import flix.runtime.factio.SQLiteRow.getByteByLabel(String);
        liftPrimRowReader(row ->
            try {
                let a = row.getByteByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt16ByIndex(ix: Int32): SQLiteRowEvaluator[Int16] =
        import flix.runtime.factio.SQLiteRow.getShortByIndex(Int32);
        liftPrimRowReader(row ->
            try {
                let a = row.getShortByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt16ByLabel(label: String): SQLiteRowEvaluator[Int16] =
        import flix.runtime.factio.SQLiteRow.getShortByLabel(String);
        liftPrimRowReader(row ->
            try {
                let a = row.getShortByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt32ByIndex(ix: Int32): SQLiteRowEvaluator[Int32] =
        import flix.runtime.factio.SQLiteRow.getIntByIndex(Int32);
        liftPrimRowReader(row ->
            try {
                let a = row.getIntByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt32ByLabel(label: String): SQLiteRowEvaluator[Int32] =
        import flix.runtime.factio.SQLiteRow.getIntByLabel(String);
        liftPrimRowReader(row ->
            try {
                let a = row.getIntByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt64ByIndex(ix: Int32): SQLiteRowEvaluator[Int64] =
        import flix.runtime.factio.SQLiteRow.getLongByIndex(Int32);
        liftPrimRowReader(row ->
            try {
                let a = row.getLongByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getInt64ByLabel(label: String): SQLiteRowEvaluator[Int64] =
        import flix.runtime.factio.SQLiteRow.getLongByLabel(String);
        liftPrimRowReader(row ->
            try {
                let a = row.getLongByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getFloat32ByIndex(ix: Int32): SQLiteRowEvaluator[Float32] =
        import flix.runtime.factio.SQLiteRow.getFloatByIndex(Int32);
        liftPrimRowReader(row ->
            try {
                let a = row.getFloatByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getFloat32ByLabel(label: String): SQLiteRowEvaluator[Float32] =
        import flix.runtime.factio.SQLiteRow.getFloatByLabel(String);
        liftPrimRowReader(row ->
            try {
                let a = row.getFloatByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getFloat64ByIndex(ix: Int32): SQLiteRowEvaluator[Float64] =
        import flix.runtime.factio.SQLiteRow.getDoubleByIndex(Int32);
        liftPrimRowReader(row ->
            try {
                let a = row.getDoubleByIndex(ix);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

    pub def getFloat64ByLabel(label: String): SQLiteRowEvaluator[Float64] =
        import flix.runtime.factio.SQLiteRow.getDoubleByLabel(String);
        liftPrimRowReader(row ->       
            try {
                let a = row.getDoubleByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.sql.SQLException => Err(Generic("SQLException"))
                case _: ##java.lang.Exception => Err(Generic("Exception"))
            }
        )

}