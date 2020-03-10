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


namespace FactIOBase {

    pub def collectErrors(line: Int32, errs: List[String]): String =
        collectErrorsHelper(line, errs) as & Pure

    def collectErrorsHelper(line: Int32, errs: List[String]): String & Impure =
        let sb = StringBuilder.new();
        StringBuilder.appendLine(sb, "${Int32.toString(line)}| Errors:");
        List.foreach(StringBuilder.appendLine(sb), errs);
        StringBuilder.toString(sb)

    ///
    /// Apply the effectful function `f` to all the elements in the array `a`.
    ///
    pub def foreachWithIndex(f: (a, Int32) -> Unit & Impure, a: Array[a]): Unit & Impure =
        let len = Array.length(a);
        if (len < 1) () else foreachWithIndexHelper(f, a, len, 0)

    ///
    /// Helper for `foreachWithIndex`.
    ///
    def foreachWithIndexHelper(f: (a, Int32)-> Unit & Impure, a: Array[a], len: Int32, i: Int32): Unit & Impure =
        if (i >= len)
            ()
        else {
            f(a[i], i);
            foreachWithIndexHelper(f, a, len, i + 1)
        }


    ///
    /// Render the array `a` as a String. Elements are rendered with the
    /// function `f` and separated with the string `sep`.
    ///
    /// Candidate for inclusion in stdlib Array.
    ///
    pub def mkStringBy(f: a -> Str, sep: Str, a: Array[a]): Str =
        mkStringByHelper(f, sep, a) as & Pure

    def mkStringByHelper(f: a -> Str, sep: Str, a: Array[a]): Str & Impure =
        let sb = StringBuilder.new();
        let step = (x,i) ->
            if (i == 0)
                StringBuilder.appendString(sb, f(x))
            else {
                StringBuilder.appendString(sb, sep);
                StringBuilder.appendString(sb, f(x))
            };
        foreachWithIndex(step, a);
        StringBuilder.toString(sb)

}