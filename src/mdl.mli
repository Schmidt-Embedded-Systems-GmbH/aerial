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
| PossiblyF of int * int * interval * regex * formula
| PossiblyP of int * int * interval * formula * regex
| Bool of bool
and regex =
| Wild
| Test of formula
| Alt of regex * regex
| Seq of regex * regex
| Star of regex

val p: string -> formula
val conj: formula -> formula -> formula
val disj: formula -> formula -> formula
val imp: formula -> formula -> formula
val iff: formula -> formula -> formula
val neg: formula -> formula
val possiblyF: regex -> interval -> formula -> formula
val possiblyP: formula -> interval -> regex -> formula
val necessarilyF: regex -> interval -> formula -> formula
val necessarilyP: formula -> interval -> regex -> formula
val base: formula -> regex
val test: formula -> regex
val wild: regex
val empty: regex
val epsilon: regex
val alt: regex -> regex -> regex
val seq: regex -> regex -> regex
val star: regex -> regex
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

module Monitor_MDL : Monitor.Monitor with type formula = formula