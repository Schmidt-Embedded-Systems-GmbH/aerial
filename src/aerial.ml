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

let cell_ref = ref (module Bexp.Cell : Cell.Cell)
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

let rec loop f x = loop f (f x)

let monitor step init log =
  let step (ctxt,ch) = 
    let (line,ch) = input_event ch in
    (step line ctxt,ch) in 
  loop step (init,log)

