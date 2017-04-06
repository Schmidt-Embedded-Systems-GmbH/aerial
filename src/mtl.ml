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

type formula =
| P of int * string
| Conj of int * formula * formula
| Disj of int * formula * formula
| Neg of int * formula
| Prev of int * interval * formula
| Since of int * interval * formula * formula
| Next of int * interval * formula
| Until of int * interval * formula * formula
| Bool of bool

let hash = function
  | P (i, _) | Conj (i, _, _)  | Disj (i, _, _) | Neg (i, _)
    | Prev (i, _, _) | Since (i, _, _, _) | Next (i, _, _) | Until (i, _, _, _) -> i
  | Bool b -> if b then -1 else -2

let bool b = Bool b
let p x = P (i_id (8 * s_id x), x)
let conj f g = Conj (i_id (8 * pairs [hash f; hash g] + 1), f, g)
let disj f g = Disj (i_id (8 * pairs [hash f; hash g] + 2), f, g)
let neg f = Neg (i_id (8 * pairs [hash f] + 3), f)
let prev i f = Prev (i_id (8 * pairs [hash_I i; hash f] + 4), i, f)
let next i f = Next (i_id (8 * pairs [hash_I i; hash f] + 5), i, f)
let since i f g = Since (i_id (8 * pairs [hash_I i; hash f; hash g] + 6), i, f, g)
let until i f g = Until (i_id (8 * pairs [hash_I i; hash f; hash g] + 7), i, f, g)

let imp f g = disj (neg f) g
let iff f g = conj (imp f g) (imp g f)
let release i f g = neg (until i (neg f) (neg g))
let weak_until i f g = release i g (disj f g)
let trigger i f g = neg (since i (neg f) (neg g))
let eventually i f = until i (bool true) f
let always i f = neg (eventually i (neg f))
let once i f = since i (bool true) f
let historically i f = neg (once i (neg f))

module MTL : Formula with type f = formula and type t = int array = struct

type f = formula
type t = int array

let rec bounded_future = function
  | Bool _ -> true
  | P _ -> true
  | Since (_, _, f, g) | Conj (_, f, g) | Disj (_, f, g) -> bounded_future f && bounded_future g
  | Until (_, i, f, g) ->
      case_I (fun _ -> true) (fun _ -> false) i && bounded_future f && bounded_future g
  | Neg (_, f) | Prev (_, _, f) | Next (_, _, f) -> bounded_future f

let rec print_formula l out = function
  | P (_, x) -> Printf.fprintf out "%s" x
  | Bool b -> Printf.fprintf out (if b then "⊤" else "⊥")
  | Conj (_, f, g) -> Printf.fprintf out (paren l 2 "%a ∧ %a") (print_formula 2) f (print_formula 2) g
  | Disj (_, f, g) -> Printf.fprintf out (paren l 1 "%a ∨ %a") (print_formula 1) f (print_formula 2) g
  | Neg (_, f) -> Printf.fprintf out "¬%a" (print_formula 3) f
  | Prev (_, i, f) -> Printf.fprintf out (paren l 3 "●%a %a") print_interval i (print_formula 4) f
  | Next (_, i, f) -> Printf.fprintf out (paren l 3 "○%a %a") print_interval i (print_formula 4) f
  | Since (_, i, f, g) -> Printf.fprintf out (paren l 0 "%a S%a %a") (print_formula 4) f print_interval i (print_formula 4) g
  | Until (_, i, f, g) -> Printf.fprintf out (paren l 0 "%a U%a %a") (print_formula 4) f print_interval i (print_formula 4) g
let print_formula = print_formula 0

let mk_idx_of f_vec =
  let h = Array.make !max_id 0 in
  let _ = Array.fold_left (fun i f -> Printf.printf "(%d) %a -> %d\n%!" (hash f) print_formula f i; h.(hash f) <- i; i + 1) 0 f_vec in
  h

let idx_of h f = (*Printf.printf "(%d) %a\n%!" (hash f) print_formula f;*) h.(hash f)

let rec sub = function 
  | Neg (_, f) -> sub f
  | Conj (_, f, g) -> sub g @ sub f
  | Disj (_, f, g) -> sub g @ sub f
  | Next (_,i,f) -> next i f :: sub f
  | Prev (_,i,f) -> prev i f :: sub f
  | Since (_, i, f, g) -> since i f g :: sub g @ sub f
  | Until (_, i, f, g) -> until i f g :: sub g @ sub f
  | P _ as f -> [f]
  | _ -> []

let aux = function
  | Since (_,i,f,g) -> List.map (fun n -> since (subtract_I n i) f g) (1 -- right_I i)
  | Until (_,i,f,g) -> List.map (fun n -> until (subtract_I n i) f g) (1 -- right_I i)
  | _ -> []

let ssub f = List.rev (List.concat (List.map (fun x -> x :: aux x) (sub f)))
let mk cnj dsj neg bo idx_of idx =
  let rec go = function
    | Conj (_, f, g) -> cnj (go f) (go g)
    | Disj (_, f, g) -> dsj (go f) (go g)
    | Neg (_, f) -> neg (go f)
    | Bool b -> bo b
    | f -> idx (idx_of f) in
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
    b.(i) <- match f_vec.(i) with
    | P (_, x) -> Now (B (SS.mem x ev))
    | Prev (_, i, f) ->
        if mem_I (t - t_prev) i then prev f else Now (B false)
    | Next (_, i, f) ->
        Later (fun t_next -> if mem_I (t_next - t) i then next f else B false)
    | Since (_, i, f, g) -> fcdisj
        (if mem_I 0 i then curr g else Now (B false))
        (if case_I (fun i -> t - t_prev > right_BI i) (fun _ -> false) i
          then Now (B false)
          else fcconj (curr f) (prev (since (subtract_I (t - t_prev) i) f g)))
    | Until (_, i, f, g) -> fcdisj
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