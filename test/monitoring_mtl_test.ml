open Aerial
open Generator
open Channel
open Util
open Mtl

let props = SS.of_list
let full = lclosed_UI 0
let small = lclosed_rclosed_BI 2 3

let log = InputMock [
                     Event (props ["P0";"P1"], 1);
                     Event (props ["P1"],      2);
                     Event (props ["P1"],      3);
                     Event (props ["P2"],      3);
                     Event (props ["P2"],      4);
                     Event (props ["P2"],      4);
                     Event (props [],          100)
                    ]
let out = OutputMock []
let mode = COMPRESS_LOCAL


let formula1 = formula_to_string(p "P1")
let out1 = fun _ -> OutputMock [
                      BoolVerdict((1,0),true);
                      BoolVerdict((2,0),true);
                      BoolVerdict((3,0),true);
                      BoolVerdict((3,1),false);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false);
                      BoolVerdict((100,0),false); 
                     ]
let formula2 = formula_to_string(conj (p "P0") (p "P1"))
let out2 = fun _ -> OutputMock [
                      BoolVerdict((1,0),true);
                      BoolVerdict((2,0),false);
                      BoolVerdict((3,0),false);
                      BoolVerdict((3,1),false);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false);
                      BoolVerdict((100,0),false); 
                     ]
let formula3 = formula_to_string(disj (p "P0") (p "P1"))
let out3 = fun _ -> OutputMock [
                      BoolVerdict((1,0),true);
                      BoolVerdict((2,0),true);
                      BoolVerdict((3,0),true);
                      BoolVerdict((3,1),false);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false);
                      BoolVerdict((100,0),false); 
                     ]
let formula4 = formula_to_string(neg (p "P0"))
let out4 = fun _ -> OutputMock [
                      BoolVerdict((1,0),false);
                      BoolVerdict((2,0),true);
                      BoolVerdict((3,0),true);
                      BoolVerdict((3,1),true);
                      BoolVerdict((4,0),true);
                      BoolVerdict((4,1),true);
                      BoolVerdict((100,0),true); 
                     ]
let formula5 = formula_to_string(next full (p "P1"))
let out5 = fun _ -> OutputMock [
                      BoolVerdict((1,0),true);
                      BoolVerdict((2,0),true);
                      BoolVerdict((3,0),false);
                      BoolVerdict((3,1),false);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false);
                      (* BoolVerdict((100,0),false);  *)
                     ]
let formula6 = formula_to_string(prev full (p "P1"))
let out6 = fun _ -> OutputMock [
                      BoolVerdict((1,0),false);
                      BoolVerdict((2,0),true);
                      BoolVerdict((3,0),true);
                      BoolVerdict((3,1),true);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false);
                      BoolVerdict((100,0),false); 
                     ]
let formula7 = formula_to_string(until full (p "P0")  (p "P1"))
let out7 = fun _ -> OutputMock [
                      BoolVerdict((1,0),true);
                      BoolVerdict((2,0),true);
                      BoolVerdict((3,0),true);
                      BoolVerdict((3,1),false);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false); 
                      (* BoolVerdict((100,0),false);  *)
                     ]
let formula8 = formula_to_string(since full (p "P1")  (p "P0"))
let out8 = fun _ -> OutputMock [
                      BoolVerdict((1,0),true);
                      BoolVerdict((2,0),true);
                      BoolVerdict((3,0),true);
                      BoolVerdict((3,1),false);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false); 
                      BoolVerdict((100,0),false); 
                     ]
let formula9 = formula_to_string(eventually small (p "P1") )
let out9 = function 
           | NAIVE -> OutputMock [
                      BoolVerdict((1,0),true);
                      BoolVerdict((2,0),false);
                      BoolVerdict((3,0),false);
                      BoolVerdict((3,1),false);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false);
                      (* BoolVerdict((100,0),false);   *)
                     ]
            | _ -> OutputMock [
                      BoolVerdict((1,0),true);
                      EqVerdict((3,1),(3,0));
                      BoolVerdict((2,0),false);
                      BoolVerdict((3,0),false);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false);
                      (* BoolVerdict((100,0),false);   *)
                     ]
let formula10 = formula_to_string(once small (p "P1") )
let out10 = fun _ -> OutputMock [
                      BoolVerdict((1,0),false);
                      BoolVerdict((2,0),false);
                      BoolVerdict((3,0),true);
                      BoolVerdict((3,1),true);
                      BoolVerdict((4,0),true);
                      BoolVerdict((4,1),true); 
                      BoolVerdict((100,0),false); 
                     ]

(* ... *)

(* Functions under test: *)
let pretty_print = fun x -> channel_to_string (OC x)
let filter_verdicts = verdicts
let test_language = Aerial.mtl
let checktest formula log out test_language mode = 
  let _ = print_endline "Checking random log:" in
  let _ = print_endline (channel_to_string (IC log)) in 
  let _ = print_endline ("w.r.t. random formula: " ^ formula) in
  check formula log out test_language mode
(*$= checktest & ~printer:pretty_print
  (out1 mode) (filter_verdicts (checktest formula1 log out test_language mode))
  (out2 mode) (filter_verdicts (checktest formula2 log out test_language mode))
  (out3 mode) (filter_verdicts (checktest formula3 log out test_language mode))
  (out4 mode) (filter_verdicts (checktest formula4 log out test_language mode))
  (out5 mode) (filter_verdicts (checktest formula5 log out test_language mode))
  (out6 mode) (filter_verdicts (checktest formula6 log out test_language mode))
  (out7 mode) (filter_verdicts (checktest formula7 log out test_language mode))
  (out8 mode) (filter_verdicts (checktest formula8 log out test_language mode))
  (out9 mode) (filter_verdicts (checktest formula9 log out test_language mode))
  (out10 mode) (filter_verdicts (checktest formula10 log out test_language mode))
*)


let fma5  = Generator.MTL.to_string (Generator.generate_mtl 5 ["P0";"P1";"P2";"P3"])
let fma10 = Generator.MTL.to_string (Generator.generate_mtl 10 ["P0";"P1";"P2";"P3"])
let fma15 = Generator.MTL.to_string (Generator.generate_mtl 15 ["P0";"P1";"P2";"P3"])
let fma20 = Generator.MTL.to_string (Generator.generate_mtl 20 ["P0";"P1";"P2";"P3"])
let fma40 = Generator.MTL.to_string (Generator.generate_mtl 40 ["P0";"P1";"P2";"P3"])
let fma60 = Generator.MTL.to_string (Generator.generate_mtl 60 ["P0";"P1";"P2";"P3"])
let fma100= Generator.MTL.to_string (Generator.generate_mtl 100 ["P0";"P1";"P2";"P3"])


let log10 = generate_log 300 20 ["P0";"P1";"P2";"P3"]

let no_eq_verdicts=eliminate_eq_verdicts
let mode_xref = NAIVE
let sort_verdicts = sort
(*$= checktest & ~printer:pretty_print
  (sort_verdicts (filter_verdicts (checktest fma5   log10 out test_language mode_xref))) (no_eq_verdicts (checktest fma5   log10 out test_language mode))
  (sort_verdicts (filter_verdicts (checktest fma10  log10 out test_language mode_xref))) (no_eq_verdicts (checktest fma10  log10 out test_language mode))
  (sort_verdicts (filter_verdicts (checktest fma15  log10 out test_language mode_xref))) (no_eq_verdicts (checktest fma15  log10 out test_language mode))
  (sort_verdicts (filter_verdicts (checktest fma20  log10 out test_language mode_xref))) (no_eq_verdicts (checktest fma20  log10 out test_language mode))
  (sort_verdicts (filter_verdicts (checktest fma40  log10 out test_language mode_xref))) (no_eq_verdicts (checktest fma40  log10 out test_language mode))
  (sort_verdicts (filter_verdicts (checktest fma60  log10 out test_language mode_xref))) (no_eq_verdicts (checktest fma60  log10 out test_language mode))
  (sort_verdicts (filter_verdicts (checktest fma100 log10 out test_language mode_xref))) (no_eq_verdicts (checktest fma100 log10 out test_language mode))
*)


(* let ex = OutputMock [
                    BoolVerdict((0,0), false);
                    BoolVerdict((0,1), false);
                    BoolVerdict((0,2), false);
                    BoolVerdict((0,3), false);
                    EqVerdict((0,5),(0,4));
                    EqVerdict((0,7),(0,4));
                    BoolVerdict((0,4), false);
                    BoolVerdict((0,6), false);
                    BoolVerdict((0,8), false);
                    BoolVerdict((0,9), false);
                    BoolVerdict((0,10), false);
                    BoolVerdict((0,11), false);
                    BoolVerdict((0,12), false);
                    BoolVerdict((0,13), false);
                    BoolVerdict((1,0), false);
                    BoolVerdict((4,0), false);
                    BoolVerdict((11,0), false);
                    BoolVerdict((32,0), false);
                    BoolVerdict((98,0), false);
                    BoolVerdict((188,0), false);
                    ] *)

(* let _ =  print_endline (channel_to_string (IC (generate_log 100 10 ["P0";"P1";"P2";"P3"]))) *)
(* let _ = print_endline (channel_to_string (OC (eliminate_eq_verdicts ex))) *)
