open Util
open QCheck

(*
compile with:
  ocamlbuild -pkgs qcheck src/generator.native
*)

let interval_gen max_lb max_delta = 
  let lb = Gen.int_bound max_lb in
  let delta = Gen.int_bound max_delta in
  Gen.map2 (fun l d -> lclosed_rclosed_BI l (l + d)) lb delta

module type Language = sig
  type formula
  val generate: string list -> int -> formula QCheck.Gen.t 
  val formula_to_string: formula -> string
end

module MTL : Language = struct
  type formula = Mtl.formula
  let generate atoms =
    let rec go = function
      | 0 -> Gen.oneofl (List.map Mtl.p atoms)
      | n -> 
        let interval_gen = interval_gen 100 50 in
        let m = Random.int n in
          Gen.frequency
            [1, Gen.map Mtl.neg   (go (n-1));
            1, Gen.map2 Mtl.conj  (go m) (go (n - 1 - m));
            1, Gen.map2 Mtl.disj  (go m) (go (n - 1 - m));
            1, Gen.map2 Mtl.next  interval_gen (go (n-1));
            1, Gen.map3 Mtl.until interval_gen (go m) (go (n - 1 - m));
            1, Gen.map2 Mtl.prev  interval_gen (go (n-1));
            1, Gen.map3 Mtl.since interval_gen (go m) (go (n - 1 - m))] in
      go
    let formula_to_string = Mtl.formula_to_string
    
end
let mtl = (module MTL : Language)

module MDL : Language = struct
  type formula = Mdl.formula
  let generate atoms =
    let rec go = function
      | 0 -> Gen.map Mdl.p (Gen.oneofl atoms)
      | n ->
        let interval_gen = interval_gen 100 50 in
        let m = Random.int n in
          Gen.frequency
            [1, Gen.map Mdl.neg   (go (n-1));
            1, Gen.map2 Mdl.conj  (go m) (go (n - 1 - m));
            1, Gen.map2 Mdl.disj  (go m) (go (n - 1 - m));
            1, Gen.map2 Mdl.next  interval_gen (go (n-1));
            1, Gen.map3 Mdl.until interval_gen (go m) (go (n - 1 - m));
            1, Gen.map2 Mdl.prev  interval_gen (go (n-1));
            1, Gen.map3 Mdl.since interval_gen (go m) (go (n - 1 - m))] in
      go
    let formula_to_string = Mdl.formula_to_string
    
end
let mdl = (module MDL : Language)

let language_ref = ref mtl

let size_ref = ref None

let num_ref = ref None

let atoms_ref = ref ["p"; "q"; "r"]


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
        language_ref := mdl;
        go args
    | ("-mtl" :: args) ->
        language_ref := mtl;
        go args
    | ("-size" :: size :: args) ->
        size_ref := Some (int_of_string size);
        go args
    | ("-num" :: num :: args) ->
        num_ref := Some (int_of_string num);
        go args
    | ("-atoms" :: atoms :: args) ->
        atoms_ref := String.split_on_char ',' atoms;
        go args
    | [] -> ()
    | _ -> usage () in
  go

let rec print_list = function 
[] -> ()
| e::l -> print_string e ; print_newline () ; print_list l

let _ = 
    Random.self_init ();
    process_args (List.tl (Array.to_list Sys.argv));
    let (module L) = !language_ref in
    let size = match !size_ref with 
      | None -> 10
      | Some x -> x in
    let num = match !num_ref with 
      | None -> 1
      | Some x -> x in
    print_list (List.map L.formula_to_string (Gen.generate ~n:num (L.generate !atoms_ref size)))
    
