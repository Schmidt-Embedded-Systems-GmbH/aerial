(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Util

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

open Cell

val mk_cell: (int -> cell) -> formula -> cell
val mk_fcell: (int -> future_cell) -> formula -> future_cell
val progress: formula array -> cell array -> int -> SS.t -> int -> future_cell array
