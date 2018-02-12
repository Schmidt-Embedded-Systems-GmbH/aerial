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
open Channel


let interval_gen max_lb max_delta =
  let lb = Gen.int_bound max_lb in
  let delta = Gen.int_bound max_delta in
  Gen.map2 (fun l d -> lclosed_rclosed_BI l (l + d)) lb delta

module type Language = sig
  type formula
  val generate: string list -> int -> formula QCheck.Gen.t
  val formula_to_string: int list -> formula  -> string
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
            (* comment for evaluation *)
            (* 1, Gen.map Mtl.neg   (go (n-1));  *)
            1, Gen.map2 Mtl.conj  (go m) (go (n - 1 - m));
            1, Gen.map2 Mtl.disj  (go m) (go (n - 1 - m));
            (* comment for evaluation *)
            (* 1, Gen.map2 Mtl.next  interval_gen (go (n-1));  *)
            2, Gen.map3 Mtl.until interval_gen (go m) (go (n - 1 - m));
            (* comment for evaluation *)
            (* 1, Gen.map2 Mtl.prev  interval_gen (go (n-1)); *)
            (* comment for evaluation *)
            (* 2, Gen.map3 Mtl.since interval_gen (go m) (go (n - 1 - m))  *)
            ])

    let rec formula_to_montre_string r l = Mtl.(function
      | P (_, x) -> Printf.sprintf "%s" x
      | Neg(x) -> Printf.sprintf "! %a" (fun x -> formula_to_montre_string r 0) x
      | Bool b -> Printf.sprintf (if b then "p || !p" else "p && !p")
      | Conj (f, g) -> Printf.sprintf (paren l 2 "%a & %a") (fun x -> formula_to_montre_string r 2) f (fun x -> formula_to_montre_string r 2) g
      | Disj (f, g) -> Printf.sprintf (paren l 1 "%a | %a") (fun x -> formula_to_montre_string r 1) f (fun x -> formula_to_montre_string r 1) g
      | Until (_, i, f, g) -> Printf.sprintf (paren l 0 "((%a)* ; %a) %% %a") (fun x -> formula_to_montre_string r 4) f (fun x -> formula_to_montre_string r 4) g (fun x -> interval_to_string) (multiply_I r i)
      | _ as x -> failwith "not supported " ^ formula_to_string x)
      let formula_to_montre_string r = formula_to_montre_string r 0
      let to_string = Mtl.formula_to_string
      let formula_to_string rs x = List.fold_left (fun s r -> (s ^ " # " ^ (formula_to_montre_string r x))) (to_string x) rs
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
              [
                0, Gen.map Mdl.neg   (gof (n-1));
                1, Gen.map2 Mdl.conj  (gof m) (gof (n - 1 - m));
                1, Gen.map2 Mdl.disj  (gof m) (gof (n - 1 - m));
                1, Gen.map3 Mdl.possiblyF (gor m) interval_gen (gof (n - 1 - m));
                0, Gen.map3 Mdl.possiblyP (gof m) interval_gen (gor (n - 1 - m))
              ]
            )
            (Gen.frequency
              [
                0, Gen.map Mdl.test   (gof (n-1));
                1, Gen.map Mdl.star   (gor (n-1));
                1, Gen.map2 Mdl.seq  (gor m) (gor (n - 1 - m));
                1, Gen.map2 Mdl.alt  (gor m) (gor (n - 1 - m))
              ]
            )) n)
    let rec formula_to_montre_string rt l = Mdl.(function
      | P (_, x) -> Printf.sprintf "%s" x
      | Neg(x) -> Printf.sprintf "! %a" (fun x -> formula_to_montre_string rt 0) x
      | Bool b -> Printf.sprintf (if b then "p || !p" else "p && !p")
      | Conj (f, g) -> Printf.sprintf (paren l 2 "%a & %a") (fun x -> formula_to_montre_string rt 2) f (fun x -> formula_to_montre_string rt 2) g
      | Disj (f, g) -> Printf.sprintf (paren l 1 "%a | %a") (fun x -> formula_to_montre_string rt 1) f (fun x -> formula_to_montre_string rt 1) g
      | MatchF (_, _, i, r) -> Printf.sprintf (paren l 0 "(%a) %% %a") (fun x -> regex_to_montre_string rt 4) r (fun x -> interval_to_string) (multiply_I rt i)
      | _ as x -> failwith "not supported " ^ formula_to_string x)
    and regex_to_montre_string rt l = Mdl.(function
      | Test f -> formula_to_montre_string rt 0 f  (* FIXME: Aparently this is now possible even though we only generate Mdl.baseF *)
      | Seq (Test f, Wild) -> formula_to_montre_string rt 0 f
      (* | Seq (Wild, Test f) -> formula_to_montre_string rt 0 f *)
      | Alt (r, s) -> Printf.sprintf (paren l 1 "%a | %a") (fun x -> regex_to_montre_string rt 1) r (fun x -> regex_to_montre_string rt 1) s
      | Seq (r, s) -> Printf.sprintf (paren l 1 "%a ; %a") (fun x -> regex_to_montre_string rt 1) r (fun x -> regex_to_montre_string rt 1) s
      | Star (r) -> Printf.sprintf "(%a)*" (fun x -> regex_to_montre_string rt 3) r
      | x -> failwith ("not supported " ^ Mdl.formula_to_string (Mdl.possiblyF x full (Mdl.bool true))))
    let formula_to_montre_string r = formula_to_montre_string r 0
    let to_string = Mdl.formula_to_string
    let formula_to_string rs x = List.fold_left (fun s r -> (s ^ " # " ^ (formula_to_montre_string r x))) (to_string x) rs
end
let mdl = (module MDL : Language)

let generate_mtl size atoms  =
  List.hd (Gen.generate ~n:1 (MTL.generate atoms size))

let generate_mdl size atoms  =
  List.hd (Gen.generate ~n:1 (MDL.generate atoms size))

let generate_log bound size atoms =
  (* let bound_gen tb = Gen.int_bound tb in *)
  let rec props acc = function
  | [] -> acc
  | s::ss -> props ([]::(List.map (fun x -> s::x) acc)) ss in
  let props a = props [[]] a in
  let event_gen tb = Gen.oneofl (List.map (fun x -> Event(SS.of_list x, tb)) (props atoms)) in
  (* let event_gen tb = Gen.map2 (fun x y -> Event(SS.of_list x, y)) (Gen.oneofl (props atoms)) (bound_gen tb) in *)
  let rec log_gen tb = function
  | 0 -> Gen.map (fun x -> [x]) (event_gen tb)
  | n -> (let ts = if tb = 0 then 0 else Random.int tb in
          let event = (event_gen tb) in
          Gen.map2 (fun x y -> x::y) event (log_gen ts (n-1))
         ) in
  let log_generator = Gen.map (fun x->InputMock (List.rev x)) (log_gen bound size) in
  List.hd (Gen.generate ~n:1 (log_generator))