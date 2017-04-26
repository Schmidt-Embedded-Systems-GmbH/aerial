(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Util

type cell = V of bool * int | B of bool | C of cell * cell | D of cell * cell
type future_cell = Now of cell | Later of (timestamp -> cell)

val print_cell: out_channel -> cell -> unit

val maybe_output_cell: out_channel -> bool -> timestamp * int -> cell -> ((timestamp * int) * cell -> 'a -> 'a) -> 'a -> 'a
val maybe_output_future: out_channel -> timestamp * int -> future_cell -> ('a -> 'a) -> 'a -> 'a

val cconj: cell -> cell -> cell
val cdisj: cell -> cell -> cell
val cneg: cell -> cell
val cimp: cell -> cell -> cell
val cif: cell -> cell -> cell -> cell

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

type bdd
val bdd_of: cell -> bdd
val maybe_output_bdd: out_channel -> bool -> timestamp * int -> bdd -> ((timestamp * int) * bdd -> 'a -> 'a) -> 'a -> 'a
val map_bdd: (int -> cell) -> bdd -> bdd
val subst_bdd: cell array -> bdd -> bdd
val subst_bdd_future: future_cell array -> bdd -> bdd
val equiv_bdd: bdd -> bdd -> bool