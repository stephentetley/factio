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


namespace ImportBase {

    def listIter(f: a -> Unit, xs: List[a]): Unit = match xs {
        case Nil => ()
        case x :: rs => { f(x); listIter(f, rs) }
    }

    pub def collectErrors(line: Int32, errs: List[String]): String =
        let sb = StringBuilder.new();
        StringBuilder.appendLine(sb, "${Int32.toString(line)}| Errors:");
        listIter(StringBuilder.appendLine(sb), errs);
        StringBuilder.toString(sb)

}