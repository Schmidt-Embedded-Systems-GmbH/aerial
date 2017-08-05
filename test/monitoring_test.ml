open Aerial
open Channel
open Util
open Mtl

let log = InputMock [Noise "a"]
let out = OutputMock []
let language_ref = ref mtl
let formula = Mtl.formula_to_string(until (lclosed_rclosed_BI 0 5) (p "P0") (until (lclosed_rclosed_BI 2 6) (p "P1") (p "P2")))
let mode = NAIVE

let check fma log =
  let (module L) = !language_ref () in
  try
  let f = L.parse (Lexing.from_string fma) in
  let m = L.Monitor.create out mode f in
    monitor m.L.Monitor.step m.L.Monitor.init log
  with
    | End_of_file -> output_event out "Bye.\n%!" 
 
(*$T 
  true
*)
(* 
let () = match check formula log with 
          OutputMock m -> print_endline List.map m *)
