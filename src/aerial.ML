(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2016:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

signature AERIAL =
sig
  val F_ref: string MTL.formula ref
  val main: (string -> unit -> unit) -> string list -> unit
  exception EOL
  exception EXIT
end

structure Aerial : AERIAL =
struct

open Util
open MTL

exception EOL
exception EXIT

val F_ref = ref (Until (lclosed_rclosed_BI 0 5, P "a", P "b"));
val mode_ref = ref COMPRESS_LOCAL;
val log_ref = ref TextIO.stdIn;
val out_ref = ref TextIO.stdOut;
structure M = Monitor(struct type atom = string; end);

fun parse_line s =
  (case space_explode " " (String.substring (s, 1, String.size s - 1)) of
    [] => NONE
  | (raw_t :: preds) =>
    (case Int.fromString raw_t of
      NONE => NONE
    | SOME t => SOME (List.filter (fn x => x <> "()") preds, t)));

fun get_next log =
  (case TextIO.inputLine log of
    NONE => raise EOL
  | SOME l => case parse_line l of NONE => get_next log | SOME x => x);

fun loop f x = loop f (f x)

fun fly m log =
  let
    fun step ctxt = #step m (get_next log) ctxt;
  in
    loop step (#init m)
  end;

fun usage () = (print
"Example usage: aerial -mode 1 -fmla test.fmla -log test.log -out test.out \n\
\Arguments:\n\
\\t -mode\n\
\\t\t 0 - naive\n\
\\t\t 1 - compress locally\n\
\\t\t 2 - compress globally\n\
\\t -fmla\n\
\\t\t <file> - formula to be monitored (if none given some default formula will be used)\n\
\\t -log\n\
\\t\t <file> - log file (default: stdin)\n\
\\t -out\n\
\\t\t <file> - output file where the verdicts are printed to (default: stdout)\n"; raise EXIT)

fun mode_error () = (print "mode should be either of 0, 1, 2\n"; raise EXIT);

fun process_args read_fmla =
  let
    fun go ("-mode" :: mode :: args) =
        let
          val mode =
            (case Int.fromString mode of
              NONE => mode_error ()
            | SOME i =>
              (case i of
                0 => NAIVE
              | 1 => COMPRESS_LOCAL
              | 2 => COMPRESS_GLOBAL
              | _ => mode_error ()));
        in
          (mode_ref := mode; go args)
        end
      | go ("-log" :: logfile :: args) =
         (log_ref := TextIO.openIn logfile; go args)
      | go ("-fmla" :: fmlafile :: args) =
         let
           val fmla = TextIO.openIn fmlafile;
           val s = TextIO.inputAll fmla;
         in
           (read_fmla s (); go args)
         end
      | go ("-out" :: outfile :: args) =
         (out_ref := TextIO.openOut outfile; go args)
      | go [] = ()
      | go _ = usage ()
  in
    go
  end;

fun main read_fmla args =
  let
    val _ = process_args read_fmla args;
    val m = M.create (!F_ref) (!mode_ref) (fn s => TextIO.output (!out_ref, s));;
  in
    fly m (!log_ref)
  end;

end;