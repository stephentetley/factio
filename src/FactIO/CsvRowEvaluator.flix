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


namespace FactIO {

    pub opaque type CsvRowEvaluator[a] = ##flixspt.factio.csv.CsvRow -> Result[a, String] & Impure

    instance Functor[CsvRowEvaluator] {
        pub def map(f: a -> b & ef, x: CsvRowEvaluator[a]): CsvRowEvaluator[b] & ef =
            FactIO/CsvRowEvaluator.map(f, x)
    }

    instance Applicative[CsvRowEvaluator] {
        pub def point(x: a): CsvRowEvaluator[a] =
            FactIO/CsvRowEvaluator.point(x)

        pub def ap(mf: CsvRowEvaluator[a -> b & ef], ma: CsvRowEvaluator[a]): CsvRowEvaluator[b] & ef =
            FactIO/CsvRowEvaluator.ap(mf, ma)
    }

    instance Monad[CsvRowEvaluator] {
        pub def flatMap(k: a -> CsvRowEvaluator[b] & ef, x: CsvRowEvaluator[a]): CsvRowEvaluator[b] & ef = 
            FactIO/CsvRowEvaluator.flatMap(k, x)
    }

}


namespace FactIO/CsvRowEvaluator {


    use FlixSandbox/Text.Charset.{Charset};
    use Time/Format.DateTimeFormatter;

    use FactIO.CsvFormat;
    use FactIO.CsvRowEvaluator;
    use FactIO.CsvRowEvaluator.{CsvRowEvaluator};

    pub def point(x: a): CsvRowEvaluator[a] = 
        CsvRowEvaluator(_ -> Ok(x) as & Impure)

    def apply1(x: CsvRowEvaluator[a], r: ##flixspt.factio.csv.CsvRow): Result[a, String] & Impure =
        let CsvRowEvaluator(f) = x;
        f(r)

    pub def map(f: a -> b & ef, x: CsvRowEvaluator[a]): CsvRowEvaluator[b] & ef =
        CsvRowEvaluator(r -> 
            match apply1(x, r) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        ) as & ef

    pub def ap(mf: CsvRowEvaluator[a -> b & ef], ma: CsvRowEvaluator[a]): CsvRowEvaluator[b] & ef =
        CsvRowEvaluator(r -> 
            match apply1(mf, r) {
                case Ok(f) => { 
                    match apply1(ma, r) {
                        case Ok(a) => Ok(f(a) as & Impure)
                        case Err(e2) => Err(e2)
                    }
                }
                case Err(e1) => Err(e1)
            }
        ) as & ef

    pub def bind(x: CsvRowEvaluator[a], k: a -> CsvRowEvaluator[b] & ef): CsvRowEvaluator[b] & ef =
        CsvRowEvaluator(r -> 
            match apply1(x, r) { 
                case Ok(a) => { let ans = k(a) as & Impure; apply1(ans, r) }
                case Err(e) => Err(e)
            }
        ) as & ef

    pub def flatMap(k: a -> CsvRowEvaluator[b] & ef, x: CsvRowEvaluator[a]): CsvRowEvaluator[b] & ef = bind(x, k)

    pub def optional(x: CsvRowEvaluator[a]): CsvRowEvaluator[Option[a]] =
        CsvRowEvaluator(r ->
            match apply1(x, r) {
                case Ok(a) => Ok(Some(a))
                case Err(_) => Ok(None)
            }
        )


    def liftPrimRowReader(eval: ##flixspt.factio.csv.CsvRow -> Result[a, String] & Impure): CsvRowEvaluator[a] =
        CsvRowEvaluator(r -> eval(r))

    pub def liftOption(x: Option[a], errMsg: String): CsvRowEvaluator[a] = match x {
        case Some(a) => point(a)
        case None => throwError(errMsg)
    }

    pub def liftResult(x: Result[a, String]): CsvRowEvaluator[a] = 
        CsvRowEvaluator(_ -> x as & Impure)

    pub def liftOperation(fn: Unit -> Result[a, String] & ef): CsvRowEvaluator[a] & ef =
        CsvRowEvaluator(_ -> fn() as & Impure) as & ef

    pub def throwError(err: String): CsvRowEvaluator[a] =
        CsvRowEvaluator(_ -> Err(err) as & Impure)

    pub def choice(xs: List[CsvRowEvaluator[a]]): CsvRowEvaluator[a] =
        CsvRowEvaluator(r -> choiceHelper(r, xs))

    def choiceHelper(r: ##flixspt.factio.csv.CsvRow, xs: List[CsvRowEvaluator[a]]): Result[a, String] & Impure =
        match xs {
            case Nil => Err("choice") as & Impure
            case x1 :: rs => match apply1(x1, r) {
                case Ok(a) => Ok(a)
                case Err(_) => choiceHelper(r, rs)
            }
        }

    // Cell readers

    pub def getStringAt(ix: Int32): CsvRowEvaluator[String] =
        import flixspt.factio.csv.CsvRow.getStringAt(Int32): String & Impure;
        liftPrimRowReader(row -> 
            try {
                let a = getStringAt(row, ix);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getStringAt('${ix}')")
            }
        )

    ///
    /// Get a string by its column name / label.
    ///
    pub def getStringNamed(label: String): CsvRowEvaluator[String] =
        import flixspt.factio.csv.CsvRow.getStringNamed(String): String & Impure;
        liftPrimRowReader(row -> 
            try {
                let a = getStringNamed(row, label);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getStringNamed('${label}')")
            }
        )

    pub def getInt8At(ix: Int32): CsvRowEvaluator[Int8] =
        import flixspt.factio.csv.CsvRow.getByteAt(Int32): Int8 & Impure;
        liftPrimRowReader(row -> 
            try {
                let a = getByteAt(row, ix);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getInt8At(${ix})")
            }
        )

    pub def getInt8Named(label: String): CsvRowEvaluator[Int8] =
        import flixspt.factio.csv.CsvRow.getByteNamed(String): Int8 & Impure;
        liftPrimRowReader(row -> 
            try {
                let a = getByteNamed(row, label);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getInt8Named('${label}')")
            }
        )

    pub def getInt16At(ix: Int32): CsvRowEvaluator[Int16] =
        import flixspt.factio.csv.CsvRow.getShortAt(Int32): Int16 & Impure;
        liftPrimRowReader(row -> 
            try {
                let a = getShortAt(row, ix);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getInt16At(${ix})")
            }
        )

    pub def getInt16Named(label: String): CsvRowEvaluator[Int16] =
        import flixspt.factio.csv.CsvRow.getShortNamed(String): Int16 & Impure;
        liftPrimRowReader(row -> 
            try {
                let a = getShortNamed(row, label);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getInt16Named('${label}')")
            }
        )

    pub def getInt32At(ix: Int32): CsvRowEvaluator[Int32] =
        import flixspt.factio.csv.CsvRow.getIntAt(Int32): Int32 & Impure;
        liftPrimRowReader(row -> 
            try {
                let a = getIntAt(row, ix);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getInt32At(${ix})")
            }
        )

    pub def getInt32Named(label: String): CsvRowEvaluator[Int32] =
        import flixspt.factio.csv.CsvRow.getIntNamed(String): Int32 & Impure;
        liftPrimRowReader(row -> 
            try {
                let a = getIntNamed(row, label);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getInt32Named('${label}')")
            }
        )

    pub def getInt64At(ix: Int32): CsvRowEvaluator[Int64] =
        import flixspt.factio.csv.CsvRow.getLongAt(Int32): Int64 & Impure;
        liftPrimRowReader(row -> 
            try {
                let a = getLongAt(row, ix);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getInt64At(${ix})")
            }
        )

    pub def getInt64Named(label: String): CsvRowEvaluator[Int64] =
        import flixspt.factio.csv.CsvRow.getLongNamed(String): Int64 & Impure;
        liftPrimRowReader(row -> 
            try {
                let a = getLongNamed(row, label);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getInt64Named('${label}')")
            }
        )

    pub def getFloat32At(ix: Int32): CsvRowEvaluator[Float32] =
        import flixspt.factio.csv.CsvRow.getFloatAt(Int32): Float32 & Impure;
        liftPrimRowReader(row -> 
            try {
                let a = getFloatAt(row, ix);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getFloat32At(${ix})")
            }
        )

    pub def getFloat32Named(label: String): CsvRowEvaluator[Float32] =
        import flixspt.factio.csv.CsvRow.getFloatNamed(String): Float32 & Impure;
        liftPrimRowReader(row -> 
            try {
                let a = getFloatNamed(row, label);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getFloat32Named('${label}')")
            }
        )

    pub def getFloat64At(ix: Int32): CsvRowEvaluator[Float64] =
        import flixspt.factio.csv.CsvRow.getDoubleAt(Int32): Float64 & Impure;
        liftPrimRowReader(row -> 
            try {
                let a = getDoubleAt(row, ix);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getFloat64At(${ix})")
            }
        )

    pub def getFloat64Named(label: String): CsvRowEvaluator[Float64] =
        import flixspt.factio.csv.CsvRow.getDoubleNamed(String): Float64 & Impure;
        liftPrimRowReader(row -> 
            try {
                let a = getDoubleNamed(row, label);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getFloat64Named('${label}')")
            }
        )

    pub def getBigIntAt(ix: Int32): CsvRowEvaluator[BigInt] =
        import flixspt.factio.csv.CsvRow.getBigIntegerAt(Int32): BigInt & Impure;
        liftPrimRowReader(row -> 
            try {
                let a = getBigIntegerAt(row, ix);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getBigIntAt(${ix})")
            }
        )

    pub def getBigIntNamed(label: String): CsvRowEvaluator[BigInt] =
        import flixspt.factio.csv.CsvRow.getBigIntegerNamed(String): BigInt & Impure;
        liftPrimRowReader(row -> 
            try {
                let a = getBigIntegerNamed(row, label);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getBigIntNamed('${label}')")
            }
        )

    /// pub def evalMatchesAt(ix: Int32, patt: Text/Regex.Pattern, eval: Text/RegexEval.MatchEvaluator[a]): CsvRowEvaluator[a] & Impure =
    ///     let* input = getStringAt(ix);
    ///     let* ans = liftOperation(_ -> Text/RegexEval/Regex.matches(patt, eval, input));
    ///     point(ans)

    /// pub def evalMatchesNamed(label: String, patt: Text/Regex.Pattern, eval: Text/RegexEval.MatchEvaluator[a]): CsvRowEvaluator[a] & Impure =
    ///     let* input = getStringNamed(label);
    ///     let* ans = liftOperation(_ -> Text/RegexEval/Regex.matches(patt, eval, input));
    ///     point(ans)

    /// pub def evalContainsAt(ix: Int32, patt: Text/Regex.Pattern, eval: Text/RegexEval.MatchEvaluator[a]): CsvRowEvaluator[a] & Impure =
    ///     let* input = getStringAt(ix);
    ///     let* ans = liftOperation(_ -> Text/RegexEval/Regex.contains(patt, eval, input));
    ///     point(ans)

    /// pub def evalContainsNamed(label: String, patt: Text/Regex.Pattern, eval: Text/RegexEval.MatchEvaluator[a]): CsvRowEvaluator[a] & Impure =
    ///     let* input = getStringNamed(label);
    ///     let* ans = liftOperation(_ -> Text/RegexEval/Regex.contains(patt, eval, input));
    ///     point(ans)

    pub def getLocalDateAt(ix: Int32, formatter: DateTimeFormatter[Time/Format.DateFormat]): CsvRowEvaluator[Time.LocalDate] =
        let* input = getStringAt(ix);
        let* ans = liftResult(Time/LocalDate.parse(formatter, input));
        point(ans)

    pub def getLocalDateNamed(label: String, formatter: DateTimeFormatter[Time/Format.DateFormat]): CsvRowEvaluator[Time.LocalDate] =
        let* input = getStringNamed(label);
        let* ans = liftResult(Time/LocalDate.parse(formatter, input));
        point(ans)

    pub def getLocalDateTimeAt(ix: Int32, formatter: DateTimeFormatter[Time/Format.DateTimeFormat]): CsvRowEvaluator[Time.LocalDateTime] =
        let* input = getStringAt(ix);
        let* ans = liftResult(Time/LocalDateTime.parse(formatter, input));
        point(ans)

    pub def getLocalDateTimeNamed(label: String, formatter: DateTimeFormatter[Time/Format.DateTimeFormat]): CsvRowEvaluator[Time.LocalDateTime] =
        let* input = getStringNamed(label);
        let* ans = liftResult(Time/LocalDateTime.parse(formatter, input));
        point(ans)

    pub def getLocalTimeAt(ix: Int32, formatter: DateTimeFormatter[Time/Format.TimeFormat]): CsvRowEvaluator[Time.LocalTime] =
        let* input = getStringAt(ix);
        let* ans = liftResult(Time/LocalTime.parse(formatter, input));
        point(ans)

    pub def getLocalTimeNamed(label: String, formatter: DateTimeFormatter[Time/Format.TimeFormat]): CsvRowEvaluator[Time.LocalTime] =
        let* input = getStringNamed(label);
        let* ans = liftResult(Time/LocalTime.parse(formatter, input));
        point(ans)


}
