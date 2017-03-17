(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Util

type binterval
type uinterval
type interval = B of binterval | U of uinterval

val lclosed_UI: int -> uinterval
val lclosed_rclosed_BI: int -> int -> binterval
val lclosed_ropen_BI: int -> int -> binterval
val lopen_UI: int -> uinterval
val lopen_rclosed_BI: int -> int -> binterval
val lopen_ropen_BI: int -> int -> binterval
val mem_BI: int -> binterval -> bool
val mem_I: int -> interval -> bool
val right_BI: binterval -> int
val right_I: interval -> int
val full: interval
val subtract_BI: int -> binterval -> binterval
val subtract_I: int -> interval -> interval
val case_I: (binterval -> 'a) -> (uinterval -> 'a) -> interval -> 'a

type timestamp = int
type 'a trace = (SS.t * timestamp) list

type formula = private
| P of int * string
| Conj of formula * formula
| Disj of formula * formula
| Neg of formula
| Prev of int * interval * formula
| Since of int * interval * formula * formula
| Next of int * interval * formula
| Until of int * interval * formula * formula
| Bool of bool

val print_interval: out_channel -> interval -> unit
val print_formula: out_channel -> formula -> unit

val idx_of: formula -> int
val bounded_future: formula -> bool

val p: string -> formula
val conj: formula -> formula -> formula
val disj: formula -> formula -> formula
val imp: formula -> formula -> formula
val iff: formula -> formula -> formula
val neg: formula -> formula
val prev: interval -> formula -> formula
val next: interval -> formula -> formula
val since: interval -> formula -> formula -> formula
val until: interval -> formula -> formula -> formula
val trigger: interval -> formula -> formula -> formula
val release: interval -> formula -> formula -> formula
val weak_until: interval -> formula -> formula -> formula
val always: interval -> formula -> formula
val eventually: interval -> formula -> formula
val once: interval -> formula -> formula
val historically: interval -> formula -> formula
val bool: bool -> formula

val conj_lifted: formula -> formula -> formula
val disj_lifted: formula -> formula -> formula
val since_lifted: interval -> formula -> formula -> formula
val until_lifted: interval -> formula -> formula -> formula

val ssub: formula -> formula list