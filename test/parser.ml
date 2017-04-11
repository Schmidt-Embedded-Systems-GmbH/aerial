open Util
open Mtl

let parseMtl = fun x -> Mtl_parser.formula Mtl_lexer.token (Lexing.from_string x)

let check s = formula_to_string (parseMtl s) = s ;;

(*$T check 
    check "⊤"
    check "⊥"

    check "P0"
    check "¬P0"
    check "P0 ∧ P1"
    check "P0 ∨ P1"
    check "P0 ∧ P1 ∧ P2"
    check "P0 ∧ P1 ∨ P2"
    check "P0 ∨ P1 ∧ P2"
    check "P0 ∨ P1 ∨ P2"

    check "P0 U[0,∞) P1"
    check "P0 S[0,∞) P1"
    check "P0 U[0,∞) (P1 U[0,∞) P2)"
    check "P0 U[0,∞) (P1 S[0,∞) P2)"
    check "P0 S[0,∞) (P1 U[0,∞) P2)"
    check "P0 S[0,∞) (P1 S[0,∞) P2)"
    check "(P0 U[0,∞) P1) U[0,∞) P2"
    check "(P0 U[0,∞) P1) S[0,∞) P2"
    check "(P0 S[0,∞) P1) U[0,∞) P2"
    check "(P0 S[0,∞) P1) S[0,∞) P2"

    check "P0 U[0,5] (P1 U[2,6] P2)"
*)

(*TODO check with Dmitriy about MTL DSL*)
let fma = until (lclosed_rclosed_BI 0 5) (p "P0") (until (lclosed_rclosed_BI 2 6) (p "P1") (p "P2"))
(*(*$= parseMtl & ~printer:printfm
  (parseMtl "P0 U[0,5] (P1 U[2,6] P2)")  ("P0 U[0,5] (P1 U[2,6] P2)")
*)*)

(*$Q parseMtl
  
*)

(*TODO repeat for MDL*)
let parseMdl = fun x -> Mdl_parser.formula Mdl_lexer.token (Lexing.from_string x)


(*let () = print_endline (formula_to_string (parseMtl "P0 U(0,5] P1"))*)
