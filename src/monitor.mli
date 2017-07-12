(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Util
open Cell

module type Formula = sig
  type f
  type memory
  module C : Cell
  val print_formula: out_channel -> f -> unit
  val init: f -> f * f array * memory
  val bounded_future: f -> bool
  val idx_of: f -> int
  val mk_cell: (int -> C.cell) -> f -> C.cell
  val mk_fcell: (int -> C.future_cell) -> f -> C.future_cell
  val progress: f array * memory  -> int * SS.t -> C.future_cell array -> C.future_cell array
end

module type Monitor = sig
  type formula
  type ctxt
  type monitor = {init: ctxt; step: SS.t * timestamp -> ctxt -> ctxt}
  val create: out_channel -> mode -> formula -> monitor
end

module Make : functor (F : Formula) -> Monitor with type formula = F.f