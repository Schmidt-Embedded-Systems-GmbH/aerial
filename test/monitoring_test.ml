open Aerial
open Channel
open Util
open Mtl

let props = SS.of_list

let log = InputMock [
                     Event (props ["P0";"P1"], 1);
                     Event (props ["P1"], 2);
                     Event (props ["P1"], 3);
                     Event (props ["P2"], 3);
                     Event (props ["P2"], 4);
                     Event (props ["P2"], 4) 
                    ]
let out = OutputMock []
let language_ref = ref mtl
let mode = NAIVE
let formula1 = Mtl.formula_to_string(until (lclosed_rclosed_BI 0 5) (p "P0")  (p "P1"))
let out1 = OutputMock [
                      Info("Monitoring P0 U[0,5] P1\n");
                      BoolVerdict((1,0),true);
                      BoolVerdict((2,0),true);
                      BoolVerdict((3,0),true);
                      BoolVerdict((3,1),false);
                      BoolVerdict((4,0),false);
                      BoolVerdict((4,1),false);
                      Info("Bye.\n");
                     ]


let formula2 = Mtl.formula_to_string(until (lclosed_rclosed_BI 0 5) (p "P0") (until (lclosed_UI 2) (p "P1") (p "P2")))
(* ... *)

let pretty_print = channel_to_string
let mtltest = mtl
let checktest = check
(*$= checktest & ~printer:pretty_print
  (out1) (checktest formula1 log out mtltest mode) 
*)
 
(* let () =  print_endline (channel_to_string (check formula log out mtl mode)) *)
