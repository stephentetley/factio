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

    pub opaque type JdbcRowEvaluator[a] = ##flixspt.factio.jdbc.JdbcRow -> Result[a, String] & Impure


    instance Functor[JdbcRowEvaluator] {
        pub def map(f: a -> b & ef, x: JdbcRowEvaluator[a]): JdbcRowEvaluator[b] & ef =
            FactIO/JdbcRowEvaluator.map(f, x)
    }

    instance Applicative[JdbcRowEvaluator] {
        pub def point(x: a): JdbcRowEvaluator[a] =
            FactIO/JdbcRowEvaluator.point(x)

        pub def ap(mf: JdbcRowEvaluator[a -> b & ef], ma: JdbcRowEvaluator[a]): JdbcRowEvaluator[b] & ef =
            FactIO/JdbcRowEvaluator.ap(mf, ma)
    }

    instance Monad[JdbcRowEvaluator] {
        pub def flatMap(k: a -> JdbcRowEvaluator[b] & ef, x: JdbcRowEvaluator[a]): JdbcRowEvaluator[b] & ef = 
            FactIO/JdbcRowEvaluator.flatMap(k, x)
    }

}


namespace FactIO/JdbcRowEvaluator {

    use Time/Format.DateTimeFormatter;

    use FactIO.JdbcRowEvaluator;
    use FactIO.JdbcRowEvaluator.{JdbcRowEvaluator};

    pub def point(x: a): JdbcRowEvaluator[a] =
        JdbcRowEvaluator(_ -> Ok(x) as & Impure)

    def apply1(x: JdbcRowEvaluator[a], r: ##flixspt.factio.jdbc.JdbcRow): Result[a, String] & Impure =
        let JdbcRowEvaluator(f) = x;
        f(r)

    pub def map(f: a -> b & ef, x: JdbcRowEvaluator[a]): JdbcRowEvaluator[b] & ef =
        JdbcRowEvaluator(r ->
            match apply1(x, r) {
                case Ok(a) => {
                    let ans = f(a) as & Impure;
                    Ok(ans)
                }
                case Err(e) => Err(e)
            }
        ) as & ef

    pub def ap(mf: JdbcRowEvaluator[a -> b & ef], ma: JdbcRowEvaluator[a]): JdbcRowEvaluator[b] & ef =
        JdbcRowEvaluator(r ->
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

    pub def bind(x: JdbcRowEvaluator[a], k: a -> JdbcRowEvaluator[b] & ef): JdbcRowEvaluator[b] & ef=
        JdbcRowEvaluator(r ->
            match apply1(x, r) { 
                case Ok(a) => { let ans = k(a) as & Impure; apply1(ans, r) }
                case Err(e) => Err(e)
            }
        ) as & ef

    pub def flatMap(k: a -> JdbcRowEvaluator[b] & ef, x: JdbcRowEvaluator[a]): JdbcRowEvaluator[b] & ef = bind(x, k)

    pub def optional(x: JdbcRowEvaluator[a]): JdbcRowEvaluator[Option[a]] =
        JdbcRowEvaluator(r ->
            match apply1(x, r) {
                case Ok(a) => Ok(Some(a))
                case Err(_) => Ok(None)
            }
        )

    def liftPrimRowReader(eval: ##flixspt.factio.jdbc.JdbcRow -> Result[a, String] & Impure): JdbcRowEvaluator[a]=
        JdbcRowEvaluator(r -> eval(r))

    pub def liftOption(x: Option[a], errMsg: String): JdbcRowEvaluator[a] = match x {
        case Some(a) => point(a)
        case None => throwError(errMsg)
    }

    pub def liftResult(x: Result[a, String]): JdbcRowEvaluator[a] =
        JdbcRowEvaluator(_ -> x as & Impure)

    pub def liftOperation(fn: Unit -> Result[a, String] & ef): JdbcRowEvaluator[a] & ef =
        JdbcRowEvaluator(_ -> fn() as & Impure) as & ef

    pub def throwError(err: String): JdbcRowEvaluator[a] =
        JdbcRowEvaluator(_ -> Err(err) as & Impure)

    pub def choice(xs: List[JdbcRowEvaluator[a]]): JdbcRowEvaluator[a] =
        JdbcRowEvaluator(r -> choiceHelper(r, xs))

    def choiceHelper(r: ##flixspt.factio.jdbc.JdbcRow, xs: List[JdbcRowEvaluator[a]]): Result[a, String] & Impure =
        match xs {
            case Nil => Err("choice") as & Impure
            case x1 :: rs => match apply1(x1, r) {
                case Ok(a) => Ok(a)
                case Err(_) => choiceHelper(r, rs)
            }
        }

    // Cell readers

    pub def getStringAt(ix: Int32): JdbcRowEvaluator[String] =
        import flixspt.factio.jdbc.JdbcRow.getStringAt(Int32): String & Impure;
        liftPrimRowReader(row ->
            try {
                let a = getStringAt(row, ix);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getStringAt(${ix})")
            }
        ) 

    pub def getStringNamed(label: String): JdbcRowEvaluator[String] =
        import flixspt.factio.jdbc.JdbcRow.getStringNamed(String): String & Impure;
        liftPrimRowReader(row ->
            try {
                let a = getStringNamed(row, label);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getStringNamed('${label}')")
            }
        )

    pub def getInt8At(ix: Int32): JdbcRowEvaluator[Int8] =
        import flixspt.factio.jdbc.JdbcRow.getByteAt(Int32): Int8 & Impure;
        liftPrimRowReader(row ->
            try {
                let a = getByteAt(row, ix);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getInt8At(${ix})")
            }
        )

    pub def getInt8Named(label: String): JdbcRowEvaluator[Int8] =
        import flixspt.factio.jdbc.JdbcRow.getByteNamed(String): Int8 & Impure;
        liftPrimRowReader(row ->
            try {
                let a = getByteNamed(row, label);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getInt8Named('${label}')")
            }
        )

    pub def getInt16At(ix: Int32): JdbcRowEvaluator[Int16] =
        import flixspt.factio.jdbc.JdbcRow.getShortAt(Int32): Int16 & Impure;
        liftPrimRowReader(row ->
            try {
                let a = getShortAt(row, ix);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getInt16At(${ix})")
            }
        )

    pub def getInt16Named(label: String): JdbcRowEvaluator[Int16] =
        import flixspt.factio.jdbc.JdbcRow.getShortNamed(String): Int16 & Impure;
        liftPrimRowReader(row ->
            try {
                let a = getShortNamed(row, label);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getInt16Named('${label}')")
            }
        )

    pub def getInt32At(ix: Int32): JdbcRowEvaluator[Int32] =
        import flixspt.factio.jdbc.JdbcRow.getIntAt(Int32): Int32 & Impure;
        liftPrimRowReader(row ->
            try {
                let a = getIntAt(row, ix);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getInt32At(${ix})")
            }
        )

    pub def getInt32Named(label: String): JdbcRowEvaluator[Int32] =
        import flixspt.factio.jdbc.JdbcRow.getIntNamed(String): Int32 & Impure;
        liftPrimRowReader(row ->
            try {
                let a = getIntNamed(row, label);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getInt32Named('${label}')")
            }
        )

    pub def getInt64At(ix: Int32): JdbcRowEvaluator[Int64] =
        import flixspt.factio.jdbc.JdbcRow.getLongAt(Int32): Int64 & Impure;
        liftPrimRowReader(row ->
            try {
                let a = getLongAt(row, ix);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getInt64At(${ix})")
            }
        )

    pub def getInt64Named(label: String): JdbcRowEvaluator[Int64] =
        import flixspt.factio.jdbc.JdbcRow.getLongNamed(String): Int64 & Impure;
        liftPrimRowReader(row ->
            try {
                let a = getLongNamed(row, label);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getInt64Named('${label}')")
            }
        )

    pub def getFloat32At(ix: Int32): JdbcRowEvaluator[Float32] =
        import flixspt.factio.jdbc.JdbcRow.getFloatAt(Int32): Float32 & Impure;
        liftPrimRowReader(row ->
            try {
                let a = getFloatAt(row, ix);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getFloat32At(${ix})")
            }
        )

    pub def getFloat32Named(label: String): JdbcRowEvaluator[Float32] =
        import flixspt.factio.jdbc.JdbcRow.getFloatNamed(String): Float32 & Impure;
        liftPrimRowReader(row ->
            try {
                let a = getFloatNamed(row, label);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getFloat32Named('${label}')")
            }
        )

    pub def getFloat64At(ix: Int32): JdbcRowEvaluator[Float64] =
        import flixspt.factio.jdbc.JdbcRow.getDoubleAt(Int32): Float64 & Impure;
        liftPrimRowReader(row ->
            try {
                let a = getDoubleAt(row, ix);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getFloat64At(${ix})")
            }
        )

    pub def getFloat64Named(label: String): JdbcRowEvaluator[Float64] =
        import flixspt.factio.jdbc.JdbcRow.getDoubleNamed(String): Float64 & Impure;
        liftPrimRowReader(row ->       
            try {
                let a = getDoubleNamed(row, label);
                Ok(a)
            } catch {
                case _: ##java.lang.Exception => Err("getFloat64Named('${label}')")
            }
        )

    pub def evalMatchesAt(ix: Int32, patt: Text/Regex.Pattern, eval: Text/RegexEval.MatchEvaluator[a]): JdbcRowEvaluator[a] & Impure =
        let* input = getStringAt(ix);
        let* ans = liftOperation(_ -> Text/RegexEval/Regex.matches(patt, eval, input));
        point(ans)

    pub def evalMatchesNamed(label: String, patt: Text/Regex.Pattern, eval: Text/RegexEval.MatchEvaluator[a]): JdbcRowEvaluator[a] & Impure =
        let* input = getStringNamed(label);
        let* ans = liftOperation(_ -> Text/RegexEval/Regex.matches(patt, eval, input));
        point(ans)

    pub def evalContainsAt(ix: Int32, patt: Text/Regex.Pattern, eval: Text/RegexEval.MatchEvaluator[a]): JdbcRowEvaluator[a] & Impure =
        let* input = getStringAt(ix);
        let* ans = liftOperation(_ -> Text/RegexEval/Regex.contains(patt, eval, input));
        point(ans)

    pub def evalContainsNamed(label: String, patt: Text/Regex.Pattern, eval: Text/RegexEval.MatchEvaluator[a]): JdbcRowEvaluator[a] & Impure =
        let* input = getStringNamed(label);
        let* ans = liftOperation(_ -> Text/RegexEval/Regex.contains(patt, eval, input));
        point(ans)

    pub def getLocalDateAt(ix: Int32, formatter: DateTimeFormatter[Time/Format.DateFormat]): JdbcRowEvaluator[Time.LocalDate] =
        let* input = getStringAt(ix);
        let* ans = liftResult(Time/LocalDate.parse(formatter, input));
        point(ans)

    pub def getLocalDateNamed(label: String, formatter: DateTimeFormatter[Time/Format.DateFormat]): JdbcRowEvaluator[Time.LocalDate] =
        let* input = getStringNamed(label);
        let* ans = liftResult(Time/LocalDate.parse(formatter, input));
        point(ans)

    pub def getLocalDateTimeAt(ix: Int32, formatter: DateTimeFormatter[Time/Format.DateTimeFormat]): JdbcRowEvaluator[Time.LocalDateTime] =
        let* input = getStringAt(ix);
        let* ans = liftResult(Time/LocalDateTime.parse(formatter, input));
        point(ans)

    pub def getLocalDateTimeNamed(label: String, formatter: DateTimeFormatter[Time/Format.DateTimeFormat]): JdbcRowEvaluator[Time.LocalDateTime] =
        let* input = getStringNamed(label);
        let* ans = liftResult(Time/LocalDateTime.parse(formatter, input));
        point(ans)

    pub def getLocalTimeAt(ix: Int32, formatter: DateTimeFormatter[Time/Format.TimeFormat]): JdbcRowEvaluator[Time.LocalTime] =
        let* input = getStringAt(ix);
        let* ans = liftResult(Time/LocalTime.parse(formatter, input));
        point(ans)

    pub def getLocalTimeNamed(label: String, formatter: DateTimeFormatter[Time/Format.TimeFormat]): JdbcRowEvaluator[Time.LocalTime] =
        let* input = getStringNamed(label);
        let* ans = liftResult(Time/LocalTime.parse(formatter, input));
        point(ans)


}
