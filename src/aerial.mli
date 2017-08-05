(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

module type Language = sig
  type formula
  val parse: Lexing.lexbuf -> formula
  val example_formula: formula
  val formula_to_string: formula -> string
  module Monitor: Monitor.Monitor with type formula = formula
end 


val cell_ref: (module Cell.Cell) ref
val mtl: unit -> (module Language)
val mdl: unit -> (module Language)
val monitor: (Util.SS.t * int -> 'a -> 'a) -> 'a -> Channel.input_channel -> 'b