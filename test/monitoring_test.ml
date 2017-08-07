open Aerial
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


let formula1 = Mtl.formula_to_string(p "P1")
let out1 = fun _ -> OutputMock [
                      BoolVerdict((1,0),true);
                      BoolVerdict((2,0),true);
                      BoolVerdict((3,0),true);
                      BoolVerdict((3,1),false);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false);
                      BoolVerdict((100,0),false); 
                     ]
let formula2 = Mtl.formula_to_string(conj (p "P0") (p "P1"))
let out2 = fun _ -> OutputMock [
                      BoolVerdict((1,0),true);
                      BoolVerdict((2,0),false);
                      BoolVerdict((3,0),false);
                      BoolVerdict((3,1),false);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false);
                      BoolVerdict((100,0),false); 
                     ]
let formula3 = Mtl.formula_to_string(disj (p "P0") (p "P1"))
let out3 = fun _ -> OutputMock [
                      BoolVerdict((1,0),true);
                      BoolVerdict((2,0),true);
                      BoolVerdict((3,0),true);
                      BoolVerdict((3,1),false);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false);
                      BoolVerdict((100,0),false); 
                     ]
let formula4 = Mtl.formula_to_string(neg (p "P0"))
let out4 = fun _ -> OutputMock [
                      BoolVerdict((1,0),false);
                      BoolVerdict((2,0),true);
                      BoolVerdict((3,0),true);
                      BoolVerdict((3,1),true);
                      BoolVerdict((4,0),true);
                      BoolVerdict((4,1),true);
                      BoolVerdict((100,0),true); 
                     ]
let formula5 = Mtl.formula_to_string(next full (p "P1"))
let out5 = fun _ -> OutputMock [
                      BoolVerdict((1,0),true);
                      BoolVerdict((2,0),true);
                      BoolVerdict((3,0),false);
                      BoolVerdict((3,1),false);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false);
                      (* BoolVerdict((100,0),false);  *)
                     ]
let formula6 = Mtl.formula_to_string(prev full (p "P1"))
let out6 = fun _ -> OutputMock [
                      BoolVerdict((1,0),false);
                      BoolVerdict((2,0),true);
                      BoolVerdict((3,0),true);
                      BoolVerdict((3,1),true);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false);
                      BoolVerdict((100,0),false); 
                     ]
let formula7 = Mtl.formula_to_string(until full (p "P0")  (p "P1"))
let out7 = fun _ -> OutputMock [
                      BoolVerdict((1,0),true);
                      BoolVerdict((2,0),true);
                      BoolVerdict((3,0),true);
                      BoolVerdict((3,1),false);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false); 
                      (* BoolVerdict((100,0),false);  *)
                     ]
let formula8 = Mtl.formula_to_string(since full (p "P1")  (p "P0"))
let out8 = fun _ -> OutputMock [
                      BoolVerdict((1,0),true);
                      BoolVerdict((2,0),true);
                      BoolVerdict((3,0),true);
                      BoolVerdict((3,1),false);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false); 
                      BoolVerdict((100,0),false); 
                     ]
let formula9 = Mtl.formula_to_string(eventually small (p "P1") )
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
let formula10 = Mtl.formula_to_string(once small (p "P1") )
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
let pretty_print = channel_to_string
let filter_verdicts = verdicts
let mtltest = mtl
let checktest = check
(*$= checktest & ~printer:pretty_print
  (out1 mode) (filter_verdicts (checktest formula1 log out mtltest mode))
  (out2 mode) (filter_verdicts (checktest formula2 log out mtltest mode))
  (out3 mode) (filter_verdicts (checktest formula3 log out mtltest mode))
  (out4 mode) (filter_verdicts (checktest formula4 log out mtltest mode))
  (out5 mode) (filter_verdicts (checktest formula5 log out mtltest mode))
  (out6 mode) (filter_verdicts (checktest formula6 log out mtltest mode))
  (out7 mode) (filter_verdicts (checktest formula7 log out mtltest mode))
  (out8 mode) (filter_verdicts (checktest formula8 log out mtltest mode))
  (out9 mode) (filter_verdicts (checktest formula9 log out mtltest mode))
  (out10 mode) (filter_verdicts (checktest formula10 log out mtltest mode))
*)
 
(* let () =  print_endline (channel_to_string (check formula log out mtl mode)) *)
