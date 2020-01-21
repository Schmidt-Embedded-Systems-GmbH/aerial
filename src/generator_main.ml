open Generator
open QCheck

(*
compile with:
  ocamlbuild -pkgs qcheck src/generator.native
*)

let language_ref = ref mdl

let size_ref = ref None

let rate_ref = ref None

let num_ref = ref None

let montre_ref = ref false

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
\t -mdl - use Metric Dynamic Logic (default)
\t -mtl - use Metric Temporal Logic 
\t -montre - generate also the equivalent montre formula 
\t -rate r1,r2,...,rn - generate n montre formulas with ith formula's interval scaled by ri"

let process_args =
  let rec go = function
    | ("-mdl" :: args) ->
        language_ref := mdl;
        go args
    | ("-mtl" :: args) ->
        language_ref := mtl;
        go args
    | ("-montre" :: args) ->
        montre_ref := true;
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
    | ("-rate" :: rate :: args) ->
        montre_ref := true;
        rate_ref := Some ([int_of_string rate]);
        rates args
    | [] -> ()
    | _ -> usage ()
  and rates = function 
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
    | (rate :: args) ->
        let newrate = match !rate_ref with 
        | None -> [int_of_string rate]
        | Some x -> int_of_string rate::x
        in rate_ref := Some(newrate);
        rates args
    | [] -> () in
  go

let rec print_list = function
[] -> ()
| e::l -> print_string e ; print_newline () ; print_list l

let _ =
    Random.self_init ();
    process_args (List.tl (Array.to_list Sys.argv));
    let (module L:Language) = !language_ref in
    let size = match !size_ref with
      | None -> 10
      | Some x -> x in
    let num = match !num_ref with
      | None -> 1
      | Some x -> x in
    let rates = match !rate_ref with
      | None -> [1]
      | Some x -> x in
    print_list (List.map (L.formula_to_string !montre_ref (List.rev rates)) (Gen.generate ~n:num (L.generate !atoms_ref size)))

