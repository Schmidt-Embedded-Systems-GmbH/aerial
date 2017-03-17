(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Util
open Mtl
open Monitor

exception EXIT

let fmla_ref = ref (Parser.formula Lexer.token (Lexing.from_string "P0 U[0,5] (P1 U[2,6] P2)"))
let mode_ref = ref COMPRESS_LOCAL
let log_ref = ref stdin
let out_ref = ref stdout

let read_file filename = 
  let lines = ref [] in
  let chan = open_in filename in
  try
    while true; do
      lines := input_line chan :: !lines
    done; !lines
  with End_of_file ->
    close_in chan;
    List.rev !lines

let parse_line s =
  match String.split_on_char ' ' (String.sub s 1 (String.length s - 1)) with
  | [] -> None
  | raw_t :: preds ->
    try Some (SS.of_list (List.filter (fun x -> x <> "()") preds), int_of_string raw_t)
    with Failure _ -> None

let rec get_next log =
  match parse_line (input_line log) with None -> get_next log | Some x -> x

let rec loop f x = loop f (f x)

let fly m log =
  let step ctxt = m.step (get_next log) ctxt
  in loop step m.init
  

let usage () = Format.eprintf
"Example usage: aerial -mode 1 -fmla test.fmla -log test.log -out test.out
Arguments:
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

let read_fmla in_ch =
  Parser.formula Lexer.token (Lexing.from_channel in_ch)

let process_args =
  let rec (go : string list -> unit) = function
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
        log_ref := open_in logfile;
        go args
    | ("-fmla" :: fmlafile :: args) ->
        let in_ch = open_in fmlafile in
        fmla_ref := read_fmla in_ch;
        close_in in_ch;
        go args
    | ("-out" :: outfile :: args) ->
        out_ref := open_out outfile;
        go args
    | [] -> ()
    | _ -> usage () in
  go

let _ =
  try
    process_args (List.tl (Array.to_list Sys.argv));
    let m = Monitor.create !out_ref !mode_ref !fmla_ref in
    fly m !log_ref
  with
    | End_of_file -> Printf.fprintf !out_ref "Bye.\n%!"; close_out !out_ref; exit 0
    | EXIT -> close_out !out_ref; exit 1