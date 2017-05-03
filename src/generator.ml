open Util
open QCheck

(*
compile with:
  ocamlbuild -pkgs qcheck src/generator.native
*)

module type Language = sig
  type formula
  val generate: formula QCheck.Gen.t 
  val formula_to_string: formula -> string
end

module MTL : Language = struct
  type formula = Mtl.formula
  let interval_gen = 
    let lb = Gen.small_nat in
    let ub = Gen.small_int in
    Gen.map2 lclosed_rclosed_BI lb ub
  let generate = QCheck.Gen.(sized @@ fix
  (fun self n -> match n with
    | 1 ->  map Mtl.p small_string
    | n ->
    let m = Random.int n in 
      frequency
        [1, map  Mtl.neg   (self (n-1));
         1, map2 Mtl.conj  (self m) (self (n-m));
         1, map2 Mtl.disj  (self m) (self (n-m));
         1, map2 Mtl.next  (interval_gen) (self (n-1));
         1, map3 Mtl.until (interval_gen) (self m) (self (n-m));
         1, map2 Mtl.prev  (interval_gen) (self (n-1));
         1, map3 Mtl.since (interval_gen) (self m) (self (n-m))]
    ))
    let formula_to_string = Mtl.formula_to_string
    
end
let mtl = (module MTL : Language)

(*module MDL : Language = struct
  type formula = Mdl.formula
  let interval_gen = 
    let lb = Gen.small_nat in
    let ub = Gen.small_int in
    Gen.map2 lclosed_rclosed_BI lb ub
  let generate = let generate = QCheck.Gen.(sized @@ fix
  (fun self n -> match n with
    | 1 ->  map Mdl.p small_string
    | n ->  
    let m = Random.int n in 
      frequency
        [1, map  Mdl.neg   (self (n-1));
         1, map2 Mdl.conj  (self m) (self (n-m));
         1, map2 Mdl.disj  (self m) (self (n-m))
         (*... *)]
  ))
  let formula_to_string = Mdl.formula_to_string
end
let mdl = (module MDL : Language)*)

let language_ref = ref mtl

let size_ref = ref None


(*let interval_gen = 
  let lb = Gen.small_nat in
  let ub = Gen.small_int in
  if lb < ub then (Gen.map2 lclosed_rclosed_BI lb ub) 
             else (Gen.map2 lclosed_rclosed_BI ub lb)*)


let usage () = Format.eprintf
"Generates a random formula of a given language.
Example usage: generator -mdl
Arguments:
\t -mdl - use Metric Dynamic Logic
\t -mtl - use Metric Temporal Logic (default)"

let process_args =
  let rec go = function
    | ("-mdl" :: args) ->
        (*language_ref := mdl;*)
        go args
    | ("-mtl" :: args) ->
        language_ref := mtl;
        go args
    | ("-size" :: size :: args) ->
        size_ref := Some (int_of_string size);
        go args
    | [] -> ()
    | _ -> usage () in
  go

let rec print_list = function 
[] -> ()
| e::l -> print_string e ; print_string " " ; print_list l

let _ = 
    Random.self_init ();
    process_args (List.tl (Array.to_list Sys.argv));
    let (module L) = !language_ref in
    let size = match !size_ref with 
      | None -> 10
      | Some x -> x
    in
    print_list (List.map L.formula_to_string (Gen.generate ~n:size L.generate))
    
