(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Util
open Channel


module type Language = sig
  type formula
  val parse: Lexing.lexbuf -> formula
  val example_formula: formula
  val formula_to_string: formula -> string
  module Monitor: Monitor.Monitor with type formula = formula
end

module Mtl(C : Cell.Cell) : Language = struct
  type formula = Mtl.formula
  let parse = Mtl_parser.formula Mtl_lexer.token
  let example_formula = parse (Lexing.from_string "P0 U[0,5] (P1 U[2,6] P2)")
  let formula_to_string = Mtl.formula_to_string
  module Monitor = Mtl.Monitor_MTL(C)
end

let cell_ref = ref (module Bdd_safa.Cell : Cell.Cell)
let mtl () =
  let (module C) = !cell_ref in
  (module Mtl(C) : Language)

module Mdl(C : Cell.Cell) : Language = struct
  type formula = Mdl.formula
  let parse = Mdl_parser.formula Mdl_lexer.token
  let example_formula = parse (Lexing.from_string "P0 U[0,5] (P1 U[2,6] P2)")
  let formula_to_string = Mdl.formula_to_string
  module Monitor = Mdl.Monitor_MDL(C)
end
let mdl () =
  let (module C) = !cell_ref in
  (module Mdl(C) : Language)

(* TODO: pass a generic L.formula instead of string? *)
let check fma log out language mode =
  let (module L:Language) = language () in
  try
  let f = L.parse (Lexing.from_string fma) in
  let m = L.Monitor.create out mode f in
    L.Monitor.fly m log
  with
    | End_of_mock o -> output_event o "Bye.\n"
