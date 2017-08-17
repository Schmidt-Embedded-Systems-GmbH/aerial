(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Aerial
open Util
open Channel

exception EXIT

let language_ref = ref mdl
let fmla_ref = ref None
let mode_ref = ref COMPRESS_GLOBAL
let log_ref = ref (Input stdin)
let out_ref = ref (Output stdout)

let usage () = Format.eprintf
"Example usage: aerial -mode 1 -fmla test.fmla -log test.log -out test.out
Arguments:
\t -mdl     \t- use Metric Dynamic Logic (default)
\t -mtl     \t- use Metric Temporal Logic
\t -bdd     \t- use BDDs
\t -nobdd   \t- don't use BDDs (default)
\t -flush   \t- flush output channel after every write
\t -noflush \t- let runtime flush the output (default)
\t -mode
\t\t naive  - naive
\t\t local  - compress locally
\t\t global - compress globally (default)
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
            | 0 -> NAIVE
            | 1 -> COMPRESS_LOCAL
            | 2 -> COMPRESS_GLOBAL
            | _ -> mode_error ())
        with Failure _ ->
            try (match mode with
                | "naive" | "NAIVE" | "Naive" -> NAIVE
                | "local" | "LOCAL" | "Local" -> COMPRESS_LOCAL
                | "global" | "GLOBAL" | "Global" -> COMPRESS_GLOBAL
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
    | ("-flush" :: args) ->
        out_ref := (match !out_ref with Output ch -> OutputFlushed ch | x -> x);
        go args
    | ("-noflush" :: args) ->
        out_ref := (match !out_ref with OutputFlushed ch -> Output ch | x -> x);
        go args
    | [] -> ()
    | _ -> usage () in
  go

 let close out = match out with Output x | OutputFlushed x -> close_out x | OutputMock x -> ()

(*TODO: reuse check from aerial module*)
(* check f !log_ref !out_ref !language_ref !mode_ref *)
let _ =
  try
    process_args (List.tl (Array.to_list Sys.argv));
    let (module L) = !language_ref () in
    let f = match !fmla_ref with
      | None -> L.example_formula
      | Some ch -> let f = L.parse (Lexing.from_channel ch) in (close_in ch; f) in
    let m = L.Monitor.create !out_ref !mode_ref f in
    L.Monitor.monitor m.L.Monitor.step m.L.Monitor.init !log_ref
  with
    | End_of_file -> let _ = output_event !out_ref "Bye.\n" in close !out_ref; exit 0
    | EXIT -> close !out_ref; exit 1
  