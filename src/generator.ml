(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Util
open QCheck


let interval_gen max_lb max_delta = 
  let lb = Gen.int_bound max_lb in
  let delta = Gen.int_bound max_delta in
  Gen.map2 (fun l d -> lclosed_rclosed_BI l (l + d)) lb delta

module type Language = sig
  type formula
  val generate: string list -> int -> formula QCheck.Gen.t 
  val formula_to_string: formula -> string
  val to_string: formula -> string
end



module MTL : Language = struct
  type formula = Mtl.formula
  let generate atoms = Gen.fix (fun go -> function
      | 0 -> Gen.oneofl (List.flatten (List.map (fun x-> [Mtl.p x; Mtl.neg (Mtl.p x)]) atoms))
      | n -> 
        let interval_gen = interval_gen 50 25 in
        let m = Random.int n in
          Gen.frequency
            [
            (*1, Gen.map Mtl.neg   (go (n-1));*)
            1, Gen.map2 Mtl.conj  (go m) (go (n - 1 - m));
            1, Gen.map2 Mtl.disj  (go m) (go (n - 1 - m));
            (*1, Gen.map2 Mtl.next  interval_gen (go (n-1));*)
            2, Gen.map3 Mtl.until interval_gen (go m) (go (n - 1 - m));
            (*1, Gen.map2 Mtl.prev  interval_gen (go (n-1));*)
            (*2, Gen.map3 Mtl.since interval_gen (go m) (go (n - 1 - m))*)
            ])

    let rec formula_to_montre_string l = Mtl.(function 
      | P (_, x) -> Printf.sprintf "%s" x
      | Neg(x) -> Printf.sprintf "! %a" (fun x -> formula_to_montre_string 0) x
      | Bool b -> Printf.sprintf (if b then "p || !p" else "p && !p")
      | Conj (f, g) -> Printf.sprintf (paren l 2 "%a & %a") (fun x -> formula_to_montre_string 2) f (fun x -> formula_to_montre_string 2) g
      | Disj (f, g) -> Printf.sprintf (paren l 1 "%a | %a") (fun x -> formula_to_montre_string 1) f (fun x -> formula_to_montre_string 1) g
      | Until (_, i, f, g) -> Printf.sprintf (paren l 0 "((%a)* ; %a) %% %a") (fun x -> formula_to_montre_string 4) f (fun x -> formula_to_montre_string 4) g (fun x -> interval_to_string) (multiply_I 100 i)
      | _ as x -> failwith "not supported " ^ formula_to_string x)
    let formula_to_montre_string = formula_to_montre_string 0
    let formula_to_string = Mtl.formula_to_string
    let formula_to_string x = formula_to_string x ^ " # " ^ formula_to_montre_string x
    let to_string = Mtl.formula_to_string
end
let mtl = (module MTL : Language)

module MDL : Language = struct
  type formula = Mdl.formula
  let generate atoms n = Gen.map fst (Gen.fix (fun go -> function
      | 0 -> Gen.pair (Gen.oneofl (List.map Mdl.p atoms)) (Gen.oneofl (List.map (fun x -> Mdl.baseF (Mdl.p x)) atoms))
      | n ->
        let interval_gen = interval_gen 50 25 in
        let gof m = Gen.map fst (go m) in
        let gor m = Gen.map snd (go m) in
        let m = Random.int n in
          Gen.pair
            (Gen.frequency
            [0, Gen.map Mdl.neg   (gof (n-1));
            1, Gen.map2 Mdl.conj  (gof m) (gof (n - 1 - m));
            1, Gen.map2 Mdl.disj  (gof m) (gof (n - 1 - m));
            1, Gen.map3 Mdl.possiblyF (gor m) interval_gen (gof (n - 1 - m));
            0, Gen.map3 Mdl.possiblyP (gof m) interval_gen (gor (n - 1 - m))])
            (Gen.frequency
            [0, Gen.map Mdl.test   (gof (n-1));
            1, Gen.map Mdl.star   (gor (n-1));
            1, Gen.map2 Mdl.seq  (gor m) (gor (n - 1 - m));
            1, Gen.map2 Mdl.alt  (gor m) (gor (n - 1 - m))])) n)
    let rec formula_to_montre_string l = Mdl.(function 
      | P (_, x) -> Printf.sprintf "%s" x
      | Neg(x) -> Printf.sprintf "! %a" (fun x -> formula_to_montre_string 0) x
      | Bool b -> Printf.sprintf (if b then "p || !p" else "p && !p")
      | Conj (f, g) -> Printf.sprintf (paren l 2 "%a & %a") (fun x -> formula_to_montre_string 2) f (fun x -> formula_to_montre_string 2) g
      | Disj (f, g) -> Printf.sprintf (paren l 1 "%a | %a") (fun x -> formula_to_montre_string 1) f (fun x -> formula_to_montre_string 1) g
      | PossiblyF (_, _, i, r, f) -> Printf.sprintf (paren l 0 "(%a ; %a) %% %a") (fun x -> formula_to_montre_string 4) f (fun x -> regex_to_montre_string 4) r (fun x -> interval_to_string) (multiply_I 100 i)
      | _ as x -> failwith "not supported " ^ formula_to_string x)
    and regex_to_montre_string l = Mdl.(function
      | Seq (Test f, Wild) -> formula_to_montre_string 0 f
      | Seq (Wild, Test f) -> formula_to_montre_string 0 f
      | Alt (r, s) -> Printf.sprintf (paren l 1 "%a | %a") (fun x -> regex_to_montre_string 1) r (fun x -> regex_to_montre_string 1) s
      | Seq (r, s) -> Printf.sprintf (paren l 1 "%a ; %a") (fun x -> regex_to_montre_string 1) r (fun x -> regex_to_montre_string 1) s
      | Star (r) -> Printf.sprintf "(%a)*" (fun x -> regex_to_montre_string 3) r
      | _ -> failwith "not supported ")
    let formula_to_montre_string = formula_to_montre_string 0
    let formula_to_string = Mdl.formula_to_string
    let formula_to_string x = formula_to_string x ^ " # " ^ formula_to_montre_string x
    let to_string = Mdl.formula_to_string
end
let mdl = (module MDL : Language)

let generate_mtl size atoms  = 
  List.hd (Gen.generate ~n:1 (MTL.generate atoms size))

let generate_mdl size atoms  = 
  List.hd (Gen.generate ~n:1 (MDL.generate atoms size))

