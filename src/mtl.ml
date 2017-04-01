(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Util
open Cell
open Monitor
open Hashcons

type formula = formula_node hash_consed
and formula_node =
| P of string
| Conj of formula * formula
| Disj of formula * formula
| Neg of formula
| Prev of interval * formula
| Since of interval * formula * formula
| Next of interval * formula
| Until of interval * formula * formula
| Bool of bool

module HC = Hashcons.Make(struct
  type t = formula_node
  let hash x = match x with
    | P x -> Hashtbl.hash x
    | Conj (f, g) -> Hashtbl.hash (2, f.hkey, g.hkey)
    | Disj (f, g) -> Hashtbl.hash (3, f.hkey, g.hkey)
    | Neg f -> Hashtbl.hash (5, f.hkey)
    | Prev (i, f) -> Hashtbl.hash (7, hash_I i, f.hkey)
    | Since (i, f, g) -> Hashtbl.hash (11, hash_I i, f.hkey, g.hkey)
    | Next (i, f) -> Hashtbl.hash (13, hash_I i, f.hkey)
    | Until (i, f, g) -> Hashtbl.hash (17, hash_I i, f.hkey, g.hkey)
    | Bool b -> Hashtbl.hash b
  let equal x y = match x,y with
    | P x, P y -> x = y
    | Bool b, Bool c -> b = c
    | Neg f, Neg f' -> f == f'
    | Conj (f,g), Conj (f',g') | Disj (f,g), Disj (f',g') -> f == f' && g == g'
    | Next (i,f), Next (j,f') | Prev (i,f), Prev (j,f') -> i = j && f == f'
    | Until (i,f,g), Until (j,f',g') | Since (i,f,g), Since (j,f',g') -> i = j && f == f' && g == g'
    | _ -> false
  end)

let hashcons = HC.hashcons (HC.create 10003)

let p x = hashcons (P x)
let bool b = hashcons (Bool b)
let conj f g =
  match f.node, g.node with
  | Bool true, _ -> g
  | _, Bool true -> f
  | Bool false, _ | _, Bool false -> bool false
  | _ -> hashcons (Conj (f, g))
let disj f g = 
  match f.node, g.node with
  | Bool false, _ -> g
  | _, Bool false -> f
  | Bool true, _ | _, Bool true -> bool true
  | _ -> hashcons (Disj (f, g))
let rec neg f =
  match f.node with
  | Disj (f, g) -> conj (neg f) (neg g)
  | Conj (f, g) -> disj (neg f) (neg g)
  | Neg f -> f
  | _ -> hashcons (Neg f)
let imp f g = disj (neg f) g
let iff f g = conj (imp f g) (imp g f)
let prev i f = hashcons (Prev (i, f))
let next i f = hashcons (Next (i, f))
let since i f g = hashcons (Since (i, f, g))
let until i f g = hashcons (Until (i, f, g))
let release i f g = neg (until i (neg f) (neg g))
let weak_until i f g = release i g (disj f g)
let trigger i f g = neg (since i (neg f) (neg g))
let eventually i f = until i (bool true) f
let always i f = neg (eventually i (neg f))
let once i f = since i (bool true) f
let historically i f = neg (once i (neg f))

module MTL : Formula with type f = formula and type t = (formula_node, int) Hmap.t = struct

type f = formula
type t = (formula_node, int) Hmap.t

let rec bounded_future f = match f.node with
  | Bool _ -> true
  | P _ -> true
  | Since (_, f, g) | Conj (f, g) | Disj (f, g) -> bounded_future f && bounded_future g
  | Until (i, f, g) ->
      case_I (fun _ -> true) (fun _ -> false) i && bounded_future f && bounded_future g
  | Neg f | Prev (_, f) | Next (_, f) -> bounded_future f

let rec print_formula l out f = match f.node with
  | P x -> Printf.fprintf out "%s" x
  | Bool b -> Printf.fprintf out (if b then "⊤" else "⊥")
  | Conj (f, g) -> Printf.fprintf out (paren l 2 "%a ∧ %a") (print_formula 2) f (print_formula 2) g
  | Disj (f, g) -> Printf.fprintf out (paren l 1 "%a ∨ %a") (print_formula 1) f (print_formula 2) g
  | Neg f -> Printf.fprintf out "¬%a" (print_formula 3) f
  | Prev (i, f) -> Printf.fprintf out (paren l 3 "●%a %a") print_interval i (print_formula 4) f
  | Next (i, f) -> Printf.fprintf out (paren l 3 "○%a %a") print_interval i (print_formula 4) f
  | Since (i, f, g) -> Printf.fprintf out (paren l 0 "%a S%a %a") (print_formula 4) f print_interval i (print_formula 4) g
  | Until (i, f, g) -> Printf.fprintf out (paren l 0 "%a U%a %a") (print_formula 4) f print_interval i (print_formula 4) g
let print_formula = print_formula 0

let rec sub x = match x.node with 
  | Neg f -> sub f
  | Conj (f, g) | Disj (f, g) -> sub g @ sub f
  | Next (_, f) | Prev (_, f) -> x :: sub f
  | Since (_, f, g) | Until (_, f, g) -> x :: sub g @ sub f
  | P _ -> [x]
  | _ -> []

let aux x =  match x.node with
  | Since (i,f,g) -> List.map (fun n -> since (subtract_I n i) f g) (1 -- right_I i)
  | Until (i,f,g) -> List.map (fun n -> until (subtract_I n i) f g) (1 -- right_I i)
  | _ -> []

let ssub f = List.rev (List.concat (List.map (fun x -> x :: aux x) (sub f)))
let mk_idx_of arr = snd (Array.fold_left (fun (i, h) f -> (i + 1, Hmap.add f i h)) (0, Hmap.empty) arr)
let idx_of h f = Hmap.find f h

let mk cnj dsj neg bo idx_of idx =
  let rec go x = match x.node with
    | Conj (f, g) -> cnj (go f) (go g)
    | Disj (f, g) -> dsj (go f) (go g)
    | Neg f -> neg (go f)
    | Bool b -> bo b
    | _ -> idx (idx_of x) in
  go
let mk_cell = mk cconj cdisj cneg (fun b -> B b)
let mk_fcell = mk fcconj fcdisj fcneg (fun b -> Now (B b))

let progress f_vec idx_of a t_prev ev t =
  let n = Array.length f_vec in
  let b = Array.make n (Now (B false)) in
  let curr = mk_fcell idx_of (fun i -> b.(i)) in
  let prev = mk_cell idx_of (fun i -> a.(i)) in
  let prev f = subst_cell_future b (prev f) in
  let next = mk_cell idx_of (fun i -> V (true, i)) in
  for i = 0 to n - 1 do
    b.(i) <- match f_vec.(i).node with
    | P x -> Now (B (SS.mem x ev))
    | Prev (i, f) ->
        if mem_I (t - t_prev) i then prev f else Now (B false)
    | Next (i, f) ->
        Later (fun t_next -> if mem_I (t_next - t) i then next f else B false)
    | Since (i, f, g) -> fcdisj
        (if mem_I 0 i then curr g else Now (B false))
        (if case_I (fun i -> t - t_prev > right_BI i) (fun _ -> false) i
          then Now (B false)
          else fcconj (curr f) (prev (since (subtract_I (t - t_prev) i) f g)))
    | Until (i, f, g) -> fcdisj
        (if mem_I 0 i then curr g else Now (B false))
        (Later (fun t_next -> if case_I (fun i -> t_next - t > right_BI i) (fun _ -> false) i
          then B false
          else cconj (eval_future_cell t_next (curr f))
            (next (until (subtract_I (t_next - t) i) f g))))
    | _ -> failwith "not a temporal formula"
  done;
  b

end

module Monitor_MTL = Monitor.Make(MTL)