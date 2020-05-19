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

use FactIO.Error;
use FactIO.Error.{IteratorError, ReadFieldByIndex, ReadFieldByLabel, Generic};

namespace FactIO {

    /// TODO - change to more regular errors...
    pub enum Error {
        case IteratorError(Int32, Error),
        case ReadFieldByIndex(Int32, String),
        case ReadFieldByLabel(String, String),        
        case Generic(String)
    }
}

namespace FactIO/Error {

    pub def toString(e: Error): String = match e {
        case IteratorError(i, e1) => "Row: " + Int32.toString(i) + ", Error: " + toString(e1)
        case ReadFieldByIndex(ix, s) => "Read error, field: " + Int32.toString(ix) + " type: " + s
        case ReadFieldByLabel(l, s) => "Read error, field: " + l + " type: " + s
        case Generic(s) => "Error: " + s
    }

}
