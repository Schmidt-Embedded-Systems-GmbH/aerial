(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2016:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

signature MTL =
sig
  type BInterval
  type UInterval
  datatype Interval = B of BInterval | U of UInterval
  val case_I: (BInterval -> 'a) -> (UInterval -> 'a) -> Interval -> 'a
  datatype 'a formula =
      Bool of bool
    | Conj of 'a formula * 'a formula
    | Disj of 'a formula * 'a formula
    | Neg of 'a formula
    | Next of Interval * 'a formula
    | P of 'a
    | Prev of Interval * 'a formula
    | Since of Interval * 'a formula * 'a formula
    | Until of BInterval * 'a formula * 'a formula
  val lclosed_UI: int -> UInterval
  val lclosed_rclosed_BI: int -> int -> BInterval
  val lclosed_ropen_BI: int -> int -> BInterval
  val lopen_UI: int -> UInterval
  val lopen_rclosed_BI: int -> int -> BInterval
  val lopen_ropen_BI: int -> int -> BInterval
  val mem_BI: int -> BInterval -> bool
  val mem_I: int -> Interval -> bool
  val right_BI: BInterval -> int
  val ssub: ''a formula -> ''a formula list
  val subtract_BI: int -> BInterval -> BInterval
  val subtract_I: int -> Interval -> Interval
  eqtype timestamp
  type 'a trace = ('a list * timestamp) list
  datatype mode = NAIVE | COMPRESS_LOCAL | COMPRESS_GLOBAL
end

structure MTL : MTL =
struct

open Util

type timestamp = int;

datatype UInterval = lclosed_UI of int
datatype BInterval = BI of int * int;
datatype Interval = B of BInterval | U of UInterval;
fun case_I f1 _ (B i) = f1 i
  | case_I _ f2 (U i) = f2 i;
fun map_I f1 f2 = case_I (B o f1) (U o f2);

fun subtract n i = if i < n then 0 else i - n;

fun lopen_UI i = lclosed_UI (i + 1);
fun nonempty_BI l r = if l <= r then BI (l, r) else raise Fail "empty interval";
fun lclosed_rclosed_BI i j = nonempty_BI i j;
fun lopen_rclosed_BI i j = nonempty_BI (i + 1) j;
fun lclosed_ropen_BI i j = nonempty_BI i (j - 1);
fun lopen_ropen_BI i j = nonempty_BI (i + 1) (j - 1);
fun left_UI (lclosed_UI i) = i;
(*fun left_BI (BI (i, _)) = i;*)
fun right_BI (BI (_, j)) = j;
(*val left_I = case_I left_BI left_UI;*)
val right_I = case_I right_BI left_UI;

fun subtract_UI n (lclosed_UI i) = lclosed_UI (subtract n i);
fun subtract_BI n (BI (i, j)) = BI (subtract n i, subtract n j);
fun subtract_I n = map_I (subtract_BI n) (subtract_UI n);

datatype 'a formula =
  P of 'a
| Conj of 'a formula * 'a formula
| Disj of 'a formula * 'a formula
| Neg of 'a formula
| Prev of Interval * 'a formula
| Since of Interval * 'a formula * 'a formula
| Next of Interval * 'a formula
| Until of BInterval * 'a formula * 'a formula
| Bool of bool;

fun mem_UI t (lclosed_UI l) = l <= t;
fun mem_BI t (BI (l, r)) = l <= t andalso t <= r;
fun mem_I t = case_I (mem_BI t) (mem_UI t);

fun sub (Neg f) = Neg f :: sub f
  | sub (Conj (f, g)) = Conj (f, g) :: sub f @ sub g
  | sub (Disj (f, g)) = Disj (f, g) :: sub f @ sub g
  | sub (Next (i,f)) = Next (i,f) :: sub f
  | sub (Prev (i,f)) = Prev (i,f) :: sub f
  | sub (Since (i, f, g)) = Since (i,f,g) :: sub f @ sub g
  | sub (Until (i, f, g)) = Until (i,f,g) :: sub f @ sub g
  | sub f = [f]

fun aux (Since (i,f,g)) = map (fn n => Since (subtract_I n i, f, g)) (1 upto right_I i)
  | aux (Until (i,f,g)) = map (fn n => Until (subtract_BI n i, f, g)) (1 upto right_BI i)
  | aux _ = []

fun ssub f = distinct (op =) (rev (maps (fn x => x :: aux x) (sub f)));

type 'a trace = ('a list * timestamp) list
datatype mode = NAIVE | COMPRESS_LOCAL | COMPRESS_GLOBAL

end;