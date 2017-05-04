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

val formula_to_string: formula -> string

module Monitor_MTL(C : Cell.Cell) : Monitor.Monitor with type formula = formula
