(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Util

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

let fma5  = Generator.MTL.to_string (Generator.generate_mtl 5 ["P0";"P1";"P2";"P3"])
let fma10 = Generator.MTL.to_string (Generator.generate_mtl 10 ["P0";"P1";"P2";"P3"])
let fma15 = Generator.MTL.to_string (Generator.generate_mtl 15 ["P0";"P1";"P2";"P3"])
let fma20 = Generator.MTL.to_string (Generator.generate_mtl 20 ["P0";"P1";"P2";"P3"])

(*$= parseMTLAndBack
  (parseMTLAndBack fma5)  (fma5)
  (parseMTLAndBack fma10) (fma10)
  (parseMTLAndBack fma15) (fma15)
  (parseMTLAndBack fma20) (fma20)
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

(* let mdlfma5  = Generator.MDL.to_string (Generator.generate_mdl 5 ["P0";"P1";"P2";"P3"])
let mdlfma10 = Generator.MDL.to_string (Generator.generate_mdl 10 ["P0";"P1";"P2";"P3"])
let mdlfma15 = Generator.MDL.to_string (Generator.generate_mdl 15 ["P0";"P1";"P2";"P3"])
let mdlfma20 = Generator.MDL.to_string (Generator.generate_mdl 20 ["P0";"P1";"P2";"P3"])


(*$= parseMDLAndBack
  (parseMDLAndBack mdlfma5)  (mdlfma5)
  (parseMDLAndBack mdlfma10) (mdlfma10)
  (parseMDLAndBack mdlfma15) (mdlfma15)
  (parseMDLAndBack mdlfma20) (mdlfma20)
*) *)

(*TODO check with Dmitriy about MTL DSL*)
(* let fma = until (lclosed_rclosed_BI 0 5) (p "P0") (until (lclosed_rclosed_BI 2 6) (p "P1") (p "P2")) *)
   (* let () = print_endline (parseMDLAndBack mdlfma15)    *)
