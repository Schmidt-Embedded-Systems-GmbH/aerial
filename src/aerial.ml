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

exception EXIT

module type Language = sig
  type formula
  val parse: Lexing.lexbuf -> formula
  val example_formula: formula
  module Monitor: Monitor.Monitor with type formula = formula
end

module Mtl(C : Cell.Cell) : Language = struct
  type formula = Mtl.formula
  let parse = Mtl_parser.formula Mtl_lexer.token
  let example_formula = parse (Lexing.from_string "P0 U[0,5] (P1 U[2,6] P2)")
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
  module Monitor = Mdl.Monitor_MDL(C)
end
let mdl () =
  let (module C) = !cell_ref in
  (module Mdl(C) : Language)


let language_ref = ref mdl
let fmla_ref = ref None
let mode_ref = ref COMPRESS_LOCAL
let log_ref = ref (Input stdin)
let out_ref = ref (Output stdout)




let usage () = Format.eprintf
"Example usage: aerial -mode 1 -fmla test.fmla -log test.log -out test.out
Arguments:
\t -mdl - use Metric Dynamic Logic (default)
\t -mtl - use Metric Temporal Logic
\t -bdd - use BDDs
\t -nobdd - don't use BDDs (default)
\t -mode
\t\t 0 - naive
\t\t 1 - compress locally (default)
\t\t 2 - compress globally
\t -fmla
\t\t <file> - formula to be monitored (if none given some default formula will be used)\n
\t -log
\t\t <file> - log file (default: stdin)
\t -out
\t\t <file> - output file where the verdicts are printed to (default: stdout)\n%!"; raise EXIT

let mode_error () = Format.eprintf "mode should be either of 0, 1, 2\n"; raise EXIT

let process_args =
  let rec go = function
    | ("-mode" :: mode :: args) ->
      let mode =
        try (match int_of_string mode with
                0 -> NAIVE
              | 1 -> COMPRESS_LOCAL
              | 2 -> COMPRESS_GLOBAL
              | _ -> mode_error ())
        with Failure _ -> mode_error () in
      mode_ref := mode;
      go args
    | ("-log" :: logfile :: args) ->
        log_ref := Input (open_in logfile);
        go args
    | ("-mdl" :: args) ->
        language_ref := mdl;
        go args
    | ("-mtl" :: args) ->
        language_ref := mtl;
        go args
    | ("-bdd" :: args) ->
        cell_ref := (module Bdd.Cell);
        go args
    | ("-nobdd" :: args) ->
        cell_ref := (module Bexp.Cell);
        go args
    | ("-fmla" :: fmlafile :: args) ->
        let in_ch = open_in fmlafile in
        (match !fmla_ref with None -> () | Some i -> close_in i);
        fmla_ref := Some in_ch;
        go args
    | ("-out" :: outfile :: args) ->
        out_ref := Output (open_out outfile);
        go args
    | [] -> ()
    | _ -> usage () in
  go

let rec loop f x = loop f (f x)

let fly step init log =
  let step (ctxt,ch) = 
    let (line,ch) = input_event ch in
    (step line ctxt,ch) in 
  loop step (init,log)

let close () = match !out_ref with Output x -> close_out x | OutputMock x -> ()
 
let _ =
  try
    process_args (List.tl (Array.to_list Sys.argv));
    let (module L) = !language_ref () in
    let f = match !fmla_ref with
      | None -> L.example_formula
      | Some ch -> let f = L.parse (Lexing.from_channel ch) in (close_in ch; f) in
    let m = L.Monitor.create !out_ref !mode_ref f in
    fly m.L.Monitor.step m.L.Monitor.init !log_ref
  with
    | End_of_file -> let _ = output_event !out_ref "Bye.\n%!" in close (); exit 0
    | EXIT -> close (); exit 1
 