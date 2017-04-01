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
  type t
  val print_formula: out_channel -> f -> unit
  val ssub: f -> f list
  val mk_idx_of: f array -> t
  val idx_of: t -> f -> int
  val bounded_future: f -> bool
  val mk_cell: (f -> int) -> (int -> cell) -> f -> cell
  val mk_fcell: (f -> int) -> (int -> future_cell) -> f -> future_cell
  val progress: f array -> (f -> int) -> cell array -> int -> SS.t -> int -> future_cell array
end

module type Monitor = sig
  type formula
  type ctxt
  type monitor = {init: ctxt; step: SS.t * timestamp -> ctxt -> ctxt}
  val create: out_channel -> mode -> formula -> monitor
end

module Make : functor (F : Formula) -> Monitor with type formula = F.f