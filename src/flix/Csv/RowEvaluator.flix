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

use System.Error.{ArrayIndexOutOfBoundsException,
        IllegalArgumentException,
        IllegalStateException,
        InputMismatchException,
        IOException,
        Generic};

use Text.Charset.{Charset};

use FactIO/Csv.CsvFormat;

use FactIO/Csv.CsvRowEvaluator;
use FactIO/Csv.CsvRowEvaluator.{CsvRowEvaluator};

namespace FactIO/Csv {

    pub opaque type CsvRowEvaluator[a] = ##flix.runtime.spt.factio.CsvRow ~> Result[a, System.Error]
}


namespace FactIO/Csv/RowEvaluator {


    pub def return(x: a): CsvRowEvaluator[a] = 
        CsvRowEvaluator(_ -> Ok(x) as & Impure)

    def apply1(x: CsvRowEvaluator[a], r: ##flix.runtime.spt.factio.CsvRow): Result[a, System.Error] & Impure =
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

    def liftPrimRowReader(eval: ##flix.runtime.spt.factio.CsvRow ~> Result[a, System.Error]): CsvRowEvaluator[a] =
        CsvRowEvaluator(r -> eval(r))

    pub def liftResult(x: Result[a, System.Error]): CsvRowEvaluator[a] = 
        CsvRowEvaluator(_ -> x as & Impure)

    def liftAction(fn: Unit ~> Result[a, System.Error]): CsvRowEvaluator[a] =
        CsvRowEvaluator(_ -> fn())

    pub def throwError(err: System.Error): CsvRowEvaluator[a] =
        CsvRowEvaluator(_ -> Err(err) as & Impure)

    pub def choice(xs: List[CsvRowEvaluator[a]]): CsvRowEvaluator[a] =
        CsvRowEvaluator(r -> choiceHelper(r, xs))

    def choiceHelper(r: ##flix.runtime.spt.factio.CsvRow, xs: List[CsvRowEvaluator[a]]): Result[a, System.Error] & Impure =
        match xs {
            case Nil => Err(InputMismatchException) as & Impure
            case x1 :: rs => match apply1(x1, r) {
                case Ok(a) => Ok(a)
                case Err(_) => choiceHelper(r, rs)
            }
        }

    // Cell readers

    pub def getStringByIndex(ix: Int32): CsvRowEvaluator[String] =
        import flix.runtime.spt.factio.CsvRow.getStringByIndex(Int32);
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
        import flix.runtime.spt.factio.CsvRow.getStringByLabel(String);
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
        import flix.runtime.spt.factio.CsvRow.getByteByIndex(Int32);
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
        import flix.runtime.spt.factio.CsvRow.getByteByLabel(String);
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
        import flix.runtime.spt.factio.CsvRow.getShortByIndex(Int32);
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
        import flix.runtime.spt.factio.CsvRow.getShortByLabel(String);
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
        import flix.runtime.spt.factio.CsvRow.getIntByIndex(Int32);
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
        import flix.runtime.spt.factio.CsvRow.getIntByLabel(String);
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
        import flix.runtime.spt.factio.CsvRow.getLongByIndex(Int32);
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
        import flix.runtime.spt.factio.CsvRow.getLongByLabel(String);
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
        import flix.runtime.spt.factio.CsvRow.getFloatByIndex(Int32);
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
        import flix.runtime.spt.factio.CsvRow.getFloatByLabel(String);
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
        import flix.runtime.spt.factio.CsvRow.getDoubleByIndex(Int32);
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
        import flix.runtime.spt.factio.CsvRow.getDoubleByLabel(String);
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
        import flix.runtime.spt.factio.CsvRow.getBigIntegerByIndex(Int32);
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
        import flix.runtime.spt.factio.CsvRow.getBigIntegerByLabel(String);
        liftPrimRowReader(row -> 
            try {
                let a = row.getBigIntegerByLabel(label);
                Ok(a)
            } catch {
                case _: ##java.lang.IllegalStateException => Err(IllegalStateException)
                case _: ##java.lang.IllegalArgumentException => Err(IllegalArgumentException)
            }
        )

    pub def evalMatchesByIndex(ix: Int32, patt: Text/Regex.Pattern, eval: Text/Regex.MatchEvaluator[a]): CsvRowEvaluator[a] =
        let* input = getStringByIndex(ix);
        let* ans = liftAction(_ -> Text/Regex.evalMatches(input, patt, eval));
        return(ans)

    pub def evalMatchesByLabel(label: String, patt: Text/Regex.Pattern, eval: Text/Regex.MatchEvaluator[a]): CsvRowEvaluator[a] =
        let* input = getStringByLabel(label);
        let* ans = liftAction(_ -> Text/Regex.evalMatches(input, patt, eval));
        return(ans)

    pub def evalContainsByIndex(ix: Int32, patt: Text/Regex.Pattern, eval: Text/Regex.MatchEvaluator[a]): CsvRowEvaluator[a] =
        let* input = getStringByIndex(ix);
        let* ans = liftAction(_ -> Text/Regex.evalContains(input, patt, eval));
        return(ans)

    pub def evalContainsByLabel(label: String, patt: Text/Regex.Pattern, eval: Text/Regex.MatchEvaluator[a]): CsvRowEvaluator[a] =
        let* input = getStringByLabel(label);
        let* ans = liftAction(_ -> Text/Regex.evalContains(input, patt, eval));
        return(ans)

    pub def getLocalDateByIndex(ix: Int32, formatter: Time/Format.DateFormatter): CsvRowEvaluator[Time.LocalDate] =
        let* input = getStringByIndex(ix);
        let* ans = liftResult(Time/LocalDate.parse(input, formatter));
        return(ans)

    pub def getLocalDateByLabel(label: String, formatter: Time/Format.DateFormatter): CsvRowEvaluator[Time.LocalDate] =
        let* input = getStringByLabel(label);
        let* ans = liftResult(Time/LocalDate.parse(input, formatter));
        return(ans)

    pub def getLocalDateTimeByIndex(ix: Int32, formatter: Time/Format.DateTimeFormatter): CsvRowEvaluator[Time.LocalDateTime] =
        let* input = getStringByIndex(ix);
        let* ans = liftResult(Time/LocalDateTime.parse(input, formatter));
        return(ans)

    pub def getLocalDateTimeByLabel(label: String, formatter: Time/Format.DateTimeFormatter): CsvRowEvaluator[Time.LocalDateTime] =
        let* input = getStringByLabel(label);
        let* ans = liftResult(Time/LocalDateTime.parse(input, formatter));
        return(ans)

    pub def getLocalTimeByIndex(ix: Int32, formatter: Time/Format.TimeFormatter): CsvRowEvaluator[Time.LocalTime] =
        let* input = getStringByIndex(ix);
        let* ans = liftResult(Time/LocalTime.parse(input, formatter));
        return(ans)

    pub def getLocalTimeByLabel(label: String, formatter: Time/Format.TimeFormatter): CsvRowEvaluator[Time.LocalTime] =
        let* input = getStringByLabel(label);
        let* ans = liftResult(Time/LocalTime.parse(input, formatter));
        return(ans)

    ///
    /// Applies the binary function `f` to the values in `o1` and `o2`.
    ///
    /// Returns an error if either `o1` or `o2` are errors.
    ///
    pub def lift2(f: (t1, t2) -> u & f, o1: CsvRowEvaluator[t1], o2: CsvRowEvaluator[t2]): CsvRowEvaluator[u] =
        ap(map(f, o1), o2)

    ///
    /// Applies the ternary function `f` to the values in `o1`, `o2` and `o3`.
    ///
    /// Returns an error if any of `o1`, `o2` and `o3` are errors.
    ///
    pub def lift3(f: (t1, t2, t3) -> u & f, o1: CsvRowEvaluator[t1], o2: CsvRowEvaluator[t2], o3: CsvRowEvaluator[t3]): CsvRowEvaluator[u] & f =
        ap(lift2(f, o1, o2), o3)

    ///
    /// Applies the 4-ary function `f` to the values in `o1`, `o2`, `o3` and `o4`.
    ///
    /// Returns an error if any of `o1`, `o2`, `o3` and `o4` are errors.
    ///
    pub def lift4(f: (t1, t2, t3, t4) -> u & f, o1: CsvRowEvaluator[t1], o2: CsvRowEvaluator[t2], o3: CsvRowEvaluator[t3], o4: CsvRowEvaluator[t4]): CsvRowEvaluator[u] & f =
        ap(lift3(f, o1, o2, o3), o4)

    ///
    /// Applies the 5-ary function `f` to the values in `o1`, `o2`, ... `o5`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o5` are errors.
    ///
    pub def lift5(f: (t1, t2, t3, t4, t5) -> u & f, o1: CsvRowEvaluator[t1], o2: CsvRowEvaluator[t2], o3: CsvRowEvaluator[t3], o4: CsvRowEvaluator[t4], o5: CsvRowEvaluator[t5]): CsvRowEvaluator[u] & f =
        ap(lift4(f, o1, o2, o3, o4), o5)

    ///
    /// Applies the 6-ary function `f` to the values in `o1`, `o2`, ... `o6`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o6` are errors.
    ///
    pub def lift6(f: (t1, t2, t3, t4, t5, t6) -> u & f, o1: CsvRowEvaluator[t1], o2: CsvRowEvaluator[t2], o3: CsvRowEvaluator[t3], o4: CsvRowEvaluator[t4], o5: CsvRowEvaluator[t5], o6: CsvRowEvaluator[t6]): CsvRowEvaluator[u] & f =
        ap(lift5(f, o1, o2, o3, o4, o5), o6)

    ///
    /// Applies the 7-ary function `f` to the values in `o1`, `o2`, ... `o7`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o7` are errors.
    ///
    pub def lift7(f: (t1, t2, t3, t4, t5, t6, t7) -> u & f, o1: CsvRowEvaluator[t1], o2: CsvRowEvaluator[t2], o3: CsvRowEvaluator[t3], o4: CsvRowEvaluator[t4], o5: CsvRowEvaluator[t5], o6: CsvRowEvaluator[t6], o7: CsvRowEvaluator[t7]): CsvRowEvaluator[u] & f=
        ap(lift6(f, o1, o2, o3, o4, o5, o6), o7)

    ///
    /// Applies the 8-ary function `f` to the values in `o1`, `o2`, ... `o8`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o8` are errors.
    ///
    pub def lift8(f: (t1, t2, t3, t4, t5, t6, t7, t8) -> u & f, o1: CsvRowEvaluator[t1], o2: CsvRowEvaluator[t2], o3: CsvRowEvaluator[t3], o4: CsvRowEvaluator[t4], o5: CsvRowEvaluator[t5], o6: CsvRowEvaluator[t6], o7: CsvRowEvaluator[t7], o8: CsvRowEvaluator[t8]): CsvRowEvaluator[u] & f =
        ap(lift7(f, o1, o2, o3, o4, o5, o6, o7), o8)

    ///
    /// Applies the 9-ary function `f` to the values in `o1`, `o2`, ... `o9`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o9` are errors.
    ///
    pub def lift9(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> u & f, o1: CsvRowEvaluator[t1], o2: CsvRowEvaluator[t2], o3: CsvRowEvaluator[t3], o4: CsvRowEvaluator[t4], o5: CsvRowEvaluator[t5], o6: CsvRowEvaluator[t6], o7: CsvRowEvaluator[t7], o8: CsvRowEvaluator[t8], o9: CsvRowEvaluator[t9]): CsvRowEvaluator[u] & f =
        ap(lift8(f, o1, o2, o3, o4, o5, o6, o7, o8), o9)

    ///
    /// Applies the 10-ary function `f` to the values in `o1`, `o2`, ... `o10`.
    ///
    /// Returns an error if any of `o1`, `o2`, ... `o10` are errors.
    ///
    pub def lift10(f: (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> u & f, o1: CsvRowEvaluator[t1], o2: CsvRowEvaluator[t2], o3: CsvRowEvaluator[t3], o4: CsvRowEvaluator[t4], o5: CsvRowEvaluator[t5], o6: CsvRowEvaluator[t6], o7: CsvRowEvaluator[t7], o8: CsvRowEvaluator[t8], o9: CsvRowEvaluator[t9], o10: CsvRowEvaluator[t10]): CsvRowEvaluator[u] & f =
        ap(lift9(f, o1, o2, o3, o4, o5, o6, o7, o8, o9), o10)


}