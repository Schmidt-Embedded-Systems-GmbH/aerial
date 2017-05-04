(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Util

type cell
type future_cell = Now of cell | Later of (timestamp -> cell)

val print_cell: out_channel -> cell -> unit

val maybe_output_cell: out_channel -> bool -> timestamp * int -> cell -> ((timestamp * int) * cell -> 'a -> 'a) -> 'a -> 'a
val maybe_output_future: out_channel -> timestamp * int -> future_cell -> ('a -> 'a) -> 'a -> 'a

val cbool: bool -> cell
val cvar: bool -> int -> cell
val cconj: cell -> cell -> cell
val cdisj: cell -> cell -> cell
val cneg: cell -> cell
val cimp: cell -> cell -> cell
val cif: cell -> cell -> cell -> cell

val fcbool: bool -> future_cell
val fcvar: bool -> int -> future_cell
val fcconj: future_cell -> future_cell -> future_cell
val fcdisj: future_cell -> future_cell -> future_cell
val fcneg: future_cell -> future_cell
val fcimp: future_cell -> future_cell -> future_cell
val fcif: future_cell -> future_cell -> future_cell -> future_cell

val eval_future_cell: timestamp -> future_cell -> cell

val map_cell: (int -> cell) -> cell -> cell
val map_cell_future: (int -> future_cell) -> cell -> future_cell
val subst_cell: cell array -> cell -> cell
val subst_cell_future: future_cell array -> cell -> future_cell

val equiv: cell -> cell -> bool