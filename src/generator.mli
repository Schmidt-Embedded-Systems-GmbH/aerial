(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)
open Channel

module type Language = sig
  type formula
  val generate: string list -> int -> formula QCheck.Gen.t
  val formula_to_string: formula -> string
  val to_string: formula -> string
end

module MTL : Language
module MDL : Language

val mtl: (module Language)
val mdl: (module Language)

val generate_mtl: int -> string list -> MTL.formula
val generate_mdl: int -> string list -> MDL.formula
val generate_log: int -> int -> Util.SS.elt list -> input_channel


