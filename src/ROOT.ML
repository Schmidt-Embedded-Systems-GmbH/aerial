(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2016:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

val _ =
  PolyML.use "src/util.ML";
  PolyML.use "src/cell.ML";
  PolyML.use "src/mtl.ML";
  PolyML.use "src/monitor.ML";
  PolyML.use "src/aerial.ML";

fun read_formula s =
  let
    val stream = TextIO.openString ("local open MTL in val _ = Aerial.F_ref := " ^ s ^ "; end;");
  in
    PolyML.compiler (fn () => TextIO.input1 stream, [])
  end;

fun main () = Aerial.main read_formula (CommandLine.arguments ())
  handle Aerial.EOL => (print "Bye.\n"; OS.Process.exit OS.Process.success)
  handle Aerial.EXIT => OS.Process.exit OS.Process.failure;