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

namespace ValidationExtras {

    
    pub def error(err: e): Validation[t, e] =
        Failure(Nel(err, Nil))


    pub def liftV2(f: (t1,t2) -> t3 & f, v1: Validation[t1, e], v2: Validation[t2, e]): Validation[t3, e] & f =
        Validation.ap(Validation.map(f, v1), v2)

    pub def liftV3(f: (t1,t2,t3) -> t4 & f, v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e]): Validation[t4, e] & f =
        Validation.ap(liftV2(f, v1, v2), v3)

    pub def liftV4(f: (t1,t2,t3,t4) -> t5 & f, v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e]): Validation[t5, e] & f=
        Validation.ap(liftV3(f, v1, v2, v3), v4)
    
    pub def liftV5(f: (t1,t2,t3,t4,t5) -> t6 & f, v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e]): Validation[t6, e] & f =
        Validation.ap(liftV4(f, v1, v2, v3, v4), v5)

    pub def liftV6(f: (t1,t2,t3,t4,t5,t6) -> t7 & f, v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e]): Validation[t7, e] & f =
        Validation.ap(liftV5(f, v1, v2, v3, v4, v5), v6)
    
    pub def liftV7(f: (t1,t2,t3,t4,t5,t6,t7) -> t8 & f, v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], v7: Validation[t7, e]): Validation[t8, e] & f=
        Validation.ap(liftV6(f, v1, v2, v3, v4, v5, v6), v7)
    
    pub def liftV8(f: (t1,t2,t3,t4,t5,t6,t7,t8) -> t9 & f, v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], v7: Validation[t7, e], v8: Validation[t8, e]): Validation[t9, e] & f =
        Validation.ap(liftV7(f, v1, v2, v3, v4, v5, v6, v7), v8)

    pub def liftV9(f: (t1,t2,t3,t4,t5,t6,t7,t8,t9) -> t10 & f, v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], v7: Validation[t7, e], v8: Validation[t8, e], v9: Validation[t9, e]): Validation[t10, e] & f =
        Validation.ap(liftV8(f, v1, v2, v3, v4, v5, v6, v7, v8), v9)
    
    pub def liftV10(f: (t1,t2,t3,t4,t5,t6,t7,t8,t9,t10) -> t11 & f, v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], v7: Validation[t7, e], v8: Validation[t8, e], v9: Validation[t9, e], v10: Validation[t10, e]): Validation[t11, e] & f =
        Validation.ap(liftV9(f, v1, v2, v3, v4, v5, v6, v7, v8, v9), v10)

    pub def pipeV2(v1: Validation[t1, e], v2: Validation[t2, e], f: (t1,t2) -> t3 & f): Validation[t3, e] & f=
        liftV2(f, v1, v2)

    pub def pipeV3(v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], f: (t1,t2,t3) -> t4 & f): Validation[t4, e] & f=
        liftV3(f, v1, v2, v3)
    
    pub def pipeV4(v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], f: (t1,t2,t3,t4) -> t5 & f): Validation[t5, e] & f=
        liftV4(f, v1, v2, v3, v4)

    pub def pipeV5(v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], f: (t1,t2,t3,t4,t5) -> t6 & f): Validation[t6, e] & f=
        liftV5(f, v1, v2, v3, v4, v5)

    pub def pipeV6(v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], f: (t1,t2,t3,t4,t5,t6) -> t7 & f): Validation[t7, e] & f=
        liftV6(f, v1, v2, v3, v4, v5, v6)

    pub def pipeV7(v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], v7: Validation[t7, e], f: (t1,t2,t3,t4,t5,t6,t7) -> t8 & f): Validation[t8, e] & f=
        liftV7(f, v1, v2, v3, v4, v5, v6, v7)

    pub def pipeV8(v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], v7: Validation[t7, e], v8: Validation[t8, e], f: (t1,t2,t3,t4,t5,t6,t7,t8) -> t9 & f): Validation[t9, e] & f =
        liftV8(f, v1, v2, v3, v4, v5, v6, v7, v8)

    pub def pipeV9(v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], v7: Validation[t7, e], v8: Validation[t8, e], v9: Validation[t9, e], f: (t1,t2,t3,t4,t5,t6,t7,t8,t9) -> t10 & f): Validation[t10, e] & f =
        liftV9(f, v1, v2, v3, v4, v5, v6, v7, v8, v9)

    pub def pipeV10(v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], v7: Validation[t7, e], v8: Validation[t8, e], v9: Validation[t9, e], v10: Validation[t10, e], f: (t1,t2,t3,t4,t5,t6,t7,t8,t9,t10) -> t11 & f): Validation[t11, e] & f =
        liftV10(f, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10)

}