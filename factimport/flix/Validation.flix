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


enum DList[a] {
    case DList(List[a] -> List[a])
}


enum Validation[t, e] {
    case Valid(t),
    case Failure(DList[e])
}



namespace Validation {

    pub def dlistToList(xs: DList[a]): List[a] = 
        let DList(f) = xs; 
        f(Nil)

    pub def singleton(x: a): DList[a] = DList(xs -> x :: xs)

    pub def append(xs: DList[a], ys: DList[a]): DList[a] = 
        let DList(f) = xs;
        let DList(g) = ys;
        DList(f << g)

    pub def valid(x: t): Validation[t, e] = Valid(x)
    
    pub def error(err: e): Validation[t, e] = 
        let x: DList[e] = singleton(err);
        Failure(x)

    pub def validate(va: Validation[t, e]): Result[t, List[e]] =  match va {
        case Valid(a) => Result.Ok(a)
        case Failure(xs) => Result.Err(dlistToList(xs))
    }

    pub def fmap(f: t -> t1, va: Validation[t, e]): Validation[t1, e] = match va {
        case Valid(a) => Valid(f(a))
        case Failure(xs) => Failure(xs)
    }

    ///
    /// AKA mapM
    ///
    pub def mapV(f: a -> Validation[b, e], xs:List[a]): Validation[List[b], e] =
        mapVHelper1(f, xs, errs -> Failure(errs), x -> Valid(x))

    ///
    ///
    /// 
    pub def mapVHelper1(f: a -> Validation[b, e], xs:List[a], fk: DList[e] -> Validation[List[b], e], sk: List[b] -> Validation[List[b], e]): Validation[List[b], e] =
        match xs {
            case Nil => sk(Nil)
            case x :: rs => {
                match f(x) {
                    case Valid(a) => mapVHelper1(f, rs, fk, ys -> sk(a :: ys))
                    case Failure(errs) => mapVHelper2(f, rs, errs, fk)
                }
            }
        }

    def mapVHelper2(f: a -> Validation[b, e], xs:List[a], ac: DList[e], fk: DList[e] -> Validation[List[b], e]): Validation[List[b], e] =
        match xs {
            case Nil => fk(ac)
            case x :: rs => {
                match f(x) {
                    case Valid(_) => mapVHelper2(f, rs, ac, fk)
                    case Failure(e) => mapVHelper2(f, rs, append(ac, e), fk)
                }
            }
        }

    pub def ap(vf: Validation[t -> t1, e], va: Validation[t, e]): Validation[t1, e1] = match vf {
        case Valid(f) => fmap(f, va)
        case Failure(xs) => match va {
            case Valid(_) => Failure(xs)
            case Failure(ys) => Failure(append(xs,ys))
        }
    }

    pub def alt(va: Validation[t, e], vb: Validation[t, e]): Validation[t, e] = match va {
        case Valid(a) => Valid(a)
        case Failure(xs) => match vb {
            case Valid(b) => Valid(b)
            case Failure(ys) => Failure(append(xs,ys))
        }
    }

    pub def withDefault(x: t, va: Validation[t, e]): Validation[t, e] = match va {
        case Valid(a) => Valid(a)
        case Failure(_) => Valid(x)
    }

    pub def liftV2(f: (t1,t2) -> t3, v1: Validation[t1, e], v2: Validation[t2, e]): Validation[t3, e] = 
        ap(fmap(f, v1), v2)

    pub def liftV3(f: (t1,t2,t3) -> t4, v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e]): Validation[t4, e] = 
        ap(liftV2(f, v1, v2), v3)

    pub def liftV4(f: (t1,t2,t3,t4) -> t5, v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e]): Validation[t5, e] = 
        ap(liftV3(f, v1, v2, v3), v4)
    
    pub def liftV5(f: (t1,t2,t3,t4,t5) -> t6, v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e]): Validation[t6, e] = 
        ap(liftV4(f, v1, v2, v3, v4), v5)

    pub def liftV6(f: (t1,t2,t3,t4,t5,t6) -> t7, v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e]): Validation[t7, e] = 
        ap(liftV5(f, v1, v2, v3, v4, v5), v6)
    
    pub def liftV7(f: (t1,t2,t3,t4,t5,t6,t7) -> t8, v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], v7: Validation[t7, e]): Validation[t8, e] = 
        ap(liftV6(f, v1, v2, v3, v4, v5, v6), v7)
    
    pub def liftV8(f: (t1,t2,t3,t4,t5,t6,t7,t8) -> t9, v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], v7: Validation[t7, e], v8: Validation[t8, e]): Validation[t9, e] = 
        ap(liftV7(f, v1, v2, v3, v4, v5, v6, v7), v8)

    pub def liftV9(f: (t1,t2,t3,t4,t5,t6,t7,t8,t9) -> t10, v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], v7: Validation[t7, e], v8: Validation[t8, e], v9: Validation[t9, e]): Validation[t10, e] = 
        ap(liftV8(f, v1, v2, v3, v4, v5, v6, v7, v8), v9)
    
    pub def liftV10(f: (t1,t2,t3,t4,t5,t6,t7,t8,t9,t10) -> t11, v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], v7: Validation[t7, e], v8: Validation[t8, e], v9: Validation[t9, e], v10: Validation[t10, e]): Validation[t11, e] = 
        ap(liftV9(f, v1, v2, v3, v4, v5, v6, v7, v8, v9), v10)

    pub def pipeV2(v1: Validation[t1, e], v2: Validation[t2, e], f: (t1,t2) -> t3): Validation[t3, e] =
        liftV2(f, v1, v2)

    pub def pipeV3(v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], f: (t1,t2,t3) -> t4): Validation[t4, e] =
        liftV3(f, v1, v2, v3)
    
    pub def pipeV4(v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], f: (t1,t2,t3,t4) -> t5): Validation[t5, e] = 
        liftV4(f, v1, v2, v3, v4)

    pub def pipeV5(v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], f: (t1,t2,t3,t4,t5) -> t6): Validation[t6, e] = 
        liftV5(f, v1, v2, v3, v4, v5)

    pub def pipeV6(v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], f: (t1,t2,t3,t4,t5,t6) -> t7): Validation[t7, e] = 
        liftV6(f, v1, v2, v3, v4, v5, v6)

    pub def pipeV7(v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], v7: Validation[t7, e], f: (t1,t2,t3,t4,t5,t6,t7) -> t8): Validation[t8, e] = 
        liftV7(f, v1, v2, v3, v4, v5, v6, v7)

    pub def pipeV8(v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], v7: Validation[t7, e], v8: Validation[t8, e], f: (t1,t2,t3,t4,t5,t6,t7,t8) -> t9): Validation[t9, e] = 
        liftV8(f, v1, v2, v3, v4, v5, v6, v7, v8)

    pub def pipeV9(v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], v7: Validation[t7, e], v8: Validation[t8, e], v9: Validation[t9, e], f: (t1,t2,t3,t4,t5,t6,t7,t8,t9) -> t10): Validation[t10, e] = 
        liftV9(f, v1, v2, v3, v4, v5, v6, v7, v8, v9)

    pub def pipeV10(v1: Validation[t1, e], v2: Validation[t2, e], v3: Validation[t3, e], v4: Validation[t4, e], v5: Validation[t5, e], v6: Validation[t6, e], v7: Validation[t7, e], v8: Validation[t8, e], v9: Validation[t9, e], v10: Validation[t10, e], f: (t1,t2,t3,t4,t5,t6,t7,t8,t9,t10) -> t11): Validation[t11, e] = 
        liftV10(f, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10)

}