open Aerial
open Channel
open Util
open Mtl

let props = SS.of_list

let log = InputMock [Noise "foo";
                     Event (props ["P0";"P1"], 1);
                     Event (props ["P1"], 2);
                     Event (props ["P1"], 3);
                     Event (props ["P2"], 3);
                     Event (props ["P2"], 4);
                     Noise "foo"
                    ]
let out = OutputMock []
let language_ref = ref mtl
let formula = Mtl.formula_to_string(until (lclosed_rclosed_BI 0 5) (p "P0") (until (lclosed_UI 2) (p "P1") (p "P2")))
let mode = NAIVE

(*$T 
  true
*)
 
let () =  print_endline (channel_to_string (check formula log out mtl mode))
