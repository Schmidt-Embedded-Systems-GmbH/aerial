(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Util
open Generator

(*TEST MTL parsing*)

let parseMTL = fun x -> Mtl_parser.formula Mtl_lexer.token (Lexing.from_string x)
let parseMTLAndBack s = Mtl.formula_to_string (parseMTL s)
let checkMTL s =  parseMTLAndBack s = s

let fmasMTL = [
  "⊤";
  "⊥";
  "P0";
  "¬P0";
  "P0 ∧ P1";
  "P0 ∨ P1";
  "P0 ∧ P1 ∧ P2";
  "P0 ∧ P1 ∨ P2";
  "P0 ∨ P1 ∧ P2";
  "P0 ∨ P1 ∨ P2";
  "P0 U[0,∞) P1";
  "P0 S[0,∞) P1";
  "P0 U[0,∞) (P1 U[0,∞) P2)";
  "P0 U[0,∞) (P1 S[0,∞) P2)";
  "P0 S[0,∞) (P1 U[0,∞) P2)";
  "P0 S[0,∞) (P1 S[0,∞) P2)";
  "(P0 U[0,∞) P1) U[0,∞) P2";
  "(P0 U[0,∞) P1) S[0,∞) P2";
  "(P0 S[0,∞) P1) U[0,∞) P2";
  "(P0 S[0,∞) P1) S[0,∞) P2";
  "P0 U[0,5] (P1 U[2,6] P2)"
]

(*(*$T  checkMTL
      List.for_all (fun x -> x) (List.map (fun x -> checkMTL x) fmasMTL)
*)*)

(*$= parseMTLAndBack
  (parseMTLAndBack "⊤"                       )   ("⊤")
  (parseMTLAndBack "⊥"                       )   ("⊥")
  (parseMTLAndBack "P0"                      )   ("P0")
  (parseMTLAndBack "¬P0"                     )   ("¬P0")
  (parseMTLAndBack "P0 ∧ P1"                 )   ("P0 ∧ P1")
  (parseMTLAndBack "P0 ∨ P1"                 )   ("P0 ∨ P1")
  (parseMTLAndBack "P0 ∧ P1 ∧ P2"            )   ("P0 ∧ P1 ∧ P2")
  (parseMTLAndBack "P0 ∧ P1 ∨ P2"            )   ("P0 ∧ P1 ∨ P2")
  (parseMTLAndBack "P0 ∨ P1 ∧ P2"            )   ("P0 ∨ P1 ∧ P2")
  (parseMTLAndBack "P0 ∨ P1 ∨ P2"            )   ("P0 ∨ P1 ∨ P2")
  (parseMTLAndBack "P0 U[0,∞) P1"            )   ("P0 U[0,∞) P1")
  (parseMTLAndBack "P0 S[0,∞) P1"            )   ("P0 S[0,∞) P1")
  (parseMTLAndBack "P0 U[0,∞) (P1 U[0,∞) P2)")   ("P0 U[0,∞) (P1 U[0,∞) P2)")
  (parseMTLAndBack "P0 U[0,∞) (P1 S[0,∞) P2)")   ("P0 U[0,∞) (P1 S[0,∞) P2)")
  (parseMTLAndBack "P0 S[0,∞) (P1 U[0,∞) P2)")   ("P0 S[0,∞) (P1 U[0,∞) P2)")
  (parseMTLAndBack "P0 S[0,∞) (P1 S[0,∞) P2)")   ("P0 S[0,∞) (P1 S[0,∞) P2)")
  (parseMTLAndBack "(P0 U[0,∞) P1) U[0,∞) P2")   ("(P0 U[0,∞) P1) U[0,∞) P2")
  (parseMTLAndBack "(P0 U[0,∞) P1) S[0,∞) P2")   ("(P0 U[0,∞) P1) S[0,∞) P2")
  (parseMTLAndBack "(P0 S[0,∞) P1) U[0,∞) P2")   ("(P0 S[0,∞) P1) U[0,∞) P2")
  (parseMTLAndBack "(P0 S[0,∞) P1) S[0,∞) P2")   ("(P0 S[0,∞) P1) S[0,∞) P2")
  (parseMTLAndBack "P0 U[0,5] (P1 U[2,6] P2)")   ("P0 U[0,5] (P1 U[2,6] P2)")
*)

let fma5  = MTL.to_string (generate_mtl 5 ["P0";"P1";"P2";"P3"])
let fma10 = MTL.to_string (generate_mtl 10 ["P0";"P1";"P2";"P3"])
let fma15 = MTL.to_string (generate_mtl 15 ["P0";"P1";"P2";"P3"])
let fma20 = MTL.to_string (generate_mtl 20 ["P0";"P1";"P2";"P3"])

let string_printer s = s^""
(*$= parseMTLAndBack & ~printer:string_printer
  (fma5)  (parseMTLAndBack fma5)
  (fma10) (parseMTLAndBack fma10)
  (fma15) (parseMTLAndBack fma15)
  (fma20) (parseMTLAndBack fma20)
*)


(*TEST MDL parsing*)


let parseMDL = fun x -> Mdl_parser.formula Mdl_lexer.token (Lexing.from_string x)
let parseMDLAndBack s = Mdl.formula_to_string (parseMDL s)
let checkMDL s =  parseMDLAndBack s = s

let fmasMDL = [
  "⊤";
  "⊥";
  "P0";
  "¬P0";
  "P0 ∧ P1";
  "P0 ∨ P1";
  "P0 ∧ P1 ∧ P2";
  "P0 ∧ P1 ∨ P2";
  "P0 ∨ P1 ∧ P2";
  "P0 ∨ P1 ∨ P2";
  "<P0>  P1";
  "P1  <P0>";
  "<P0>  (<P1>  P2)";
  "<P0>  (P2  <P1>)";
  "(<P1>  P2)  <P0>";
  "(P2  <P1>)  <P0>";
  "<<P0>  P1>  P2";
  "P2  <<P0>  P1>";
  "<P1  <P0>>  P2";
  "P2  <P1  <P0>>";
  "<P0> [0,∞) P1";
  "P1 [0,∞) <P0>";
  "<P0> [0,∞) (<P1> [0,∞) P2)";
  "<P0> [0,∞) (P2 [0,∞) <P1>)";
  "(<P1> [0,∞) P2) [0,∞) <P0>";
  "(P2 [0,∞) <P1>) [0,∞) <P0>";
  "<<P0> [0,∞) P1> [0,∞) P2";
  "P2 [0,∞) <<P0> [0,∞) P1>";
  "<P1 [0,∞) <P0>> [0,∞) P2";
  "P2 [0,∞) <P1 [0,∞) <P0>>";
  "<P0> (4,9] P1";
  "P1 (4,9] <P0>";
  "<P0> (4,9] (<P1> (4,9] P2)";
  "<P0> (4,9] (P2 (4,9] <P1>)";
  "(<P1> (4,9] P2) (4,9] <P0>";
  "(P2 (4,9] <P1>) (4,9] <P0>";
  "<<P0> (4,9] P1> (4,9] P2";
  "P2 (4,9] <<P0> (4,9] P1>";
  "<P1 (4,9] <P0>> (4,9] P2";
  "P2 (4,9] <P1 (4,9] <P0>>";
  "<P0 P1> P2";
  "P2 <P0 P1>";
  "<P0* P1> P2";
  "P2 <P0* P1>";
  "<P0 + P1> P2";
  "P2 <P0 + P1>";
]
(*(*$T  checkMDL
      List.for_all (fun x -> x) (List.map (fun x -> checkMDL x) fmasMDL)
*)*)


(*$= parseMDLAndBack
  (parseMDLAndBack "⊤"                          ) ("⊤")
  (parseMDLAndBack "⊥"                          ) ("⊥")
  (parseMDLAndBack "P0"                         ) ("P0")
  (parseMDLAndBack "¬P0"                        ) ("¬P0")
  (parseMDLAndBack "P0 ∧ P1"                    ) ("P0 ∧ P1")
  (parseMDLAndBack "P0 ∨ P1"                    ) ("P0 ∨ P1")
  (parseMDLAndBack "P0 ∧ P1 ∧ P2"               ) ("P0 ∧ P1 ∧ P2")
  (parseMDLAndBack "P0 ∧ P1 ∨ P2"               ) ("P0 ∧ P1 ∨ P2")
  (parseMDLAndBack "P0 ∨ P1 ∧ P2"               ) ("P0 ∨ P1 ∧ P2")
  (parseMDLAndBack "P0 ∨ P1 ∨ P2"               ) ("P0 ∨ P1 ∨ P2")
  (parseMDLAndBack "<P0> [0,∞) P1"              ) ("<P0> [0,∞) P1" )
  (parseMDLAndBack "P1 [0,∞) <P0>"              ) ("P1 [0,∞) <P0>" )
  (parseMDLAndBack "<P0> [0,∞) (<P1> [0,∞) P2)" ) ("<P0> [0,∞) (<P1> [0,∞) P2)")
  (parseMDLAndBack "<P0> [0,∞) (P2 [0,∞) <P1>)" ) ("<P0> [0,∞) (P2 [0,∞) <P1>)")
  (parseMDLAndBack "(<P1> [0,∞) P2) [0,∞) <P0>" ) ("(<P1> [0,∞) P2) [0,∞) <P0>")
  (parseMDLAndBack "(P2 [0,∞) <P1>) [0,∞) <P0>" ) ("(P2 [0,∞) <P1>) [0,∞) <P0>")
  (parseMDLAndBack "<<P0> [0,∞) P1> [0,∞) P2"   ) ("<<P0> [0,∞) P1> [0,∞) P2")
  (parseMDLAndBack "P2 [0,∞) <<P0> [0,∞) P1>"   ) ("P2 [0,∞) <<P0> [0,∞) P1>")
  (parseMDLAndBack "<P1 [0,∞) <P0>> [0,∞) P2"   ) ("<P1 [0,∞) <P0>> [0,∞) P2")
  (parseMDLAndBack "P2 [0,∞) <P1 [0,∞) <P0>>"   ) ("P2 [0,∞) <P1 [0,∞) <P0>>")
  (parseMDLAndBack "<P0> (4,9] P1"              ) ("<P0> [5,9] P1")
  (parseMDLAndBack "P1 (4,9] <P0>"              ) ("P1 [5,9] <P0>")
  (parseMDLAndBack "<P0> (4,9] (<P1> (4,9] P2)" ) ("<P0> [5,9] (<P1> [5,9] P2)")
  (parseMDLAndBack "<P0> (4,9] (P2 (4,9] <P1>)" ) ("<P0> [5,9] (P2 [5,9] <P1>)")
  (parseMDLAndBack "(<P1> (4,9] P2) (4,9] <P0>" ) ("(<P1> [5,9] P2) [5,9] <P0>")
  (parseMDLAndBack "(P2 (4,9] <P1>) (4,9] <P0>" ) ("(P2 [5,9] <P1>) [5,9] <P0>")
  (parseMDLAndBack "<<P0> (4,9] P1> (4,9] P2"   ) ("<<P0> [5,9] P1> [5,9] P2")
  (parseMDLAndBack "P2 (4,9] <<P0> (4,9] P1>"   ) ("P2 [5,9] <<P0> [5,9] P1>")
  (parseMDLAndBack "<P1 (4,9] <P0>> (4,9] P2"   ) ("<P1 [5,9] <P0>> [5,9] P2")
  (parseMDLAndBack "P2 (4,9] <P1 (4,9] <P0>>"   ) ("P2 [5,9] <P1 [5,9] <P0>>")
  (parseMDLAndBack "<P0 P1> P2"                 ) ("<P0 P1> [0,∞) P2")
  (parseMDLAndBack "P2 <P0 P1>"                 ) ("P2 [0,∞) <P0 P1>")
  (parseMDLAndBack "<P0* P1> P2"                ) ("<P0* P1> [0,∞) P2")
  (parseMDLAndBack "P2 <P0* P1>"                ) ("P2 [0,∞) <P0* P1>")
  (parseMDLAndBack "<P0 + P1> P2"               ) ("(<P1> [0,∞) P2) ∨ (<P0> [0,∞) P2)")
  (parseMDLAndBack "P2 <P0 + P1>"               ) ("(P2 [0,∞) <P1>) ∨ (P2 [0,∞) <P0>)")
*)

let mdlfma5  = let fma = MDL.to_string (generate_mdl 5 ["P0";"P1";"P2";"P3"]) in print_endline fma; fma
let mdlfma10 = let fma = MDL.to_string (generate_mdl 10 ["P0";"P1";"P2";"P3"]) in print_endline fma; fma
let mdlfma15 = let fma = MDL.to_string (generate_mdl 15 ["P0";"P1";"P2";"P3"]) in print_endline fma; fma
let mdlfma20 = let fma = MDL.to_string (generate_mdl 20 ["P0";"P1";"P2";"P3"]) in print_endline fma; fma

(*$= parseMDLAndBack & ~printer:string_printer
  (mdlfma5)  (parseMDLAndBack mdlfma5)
  (mdlfma10) (parseMDLAndBack mdlfma10)
  (mdlfma15) (parseMDLAndBack mdlfma15)
  (mdlfma20) (parseMDLAndBack mdlfma20)
*)

(*TODO check with Dmitriy about MTL DSL*)
(* let fma = until (lclosed_rclosed_BI 0 5) (p "P0") (until (lclosed_rclosed_BI 2 6) (p "P1") (p "P2")) *)
   (* let () = print_endline (parseMDLAndBack mdlfma15)    *)
