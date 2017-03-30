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
| Conj of formula * formula
| Disj of formula * formula
| Neg of formula
| Prev of int * interval * formula
| Since of int * interval * formula * formula
| Next of int * interval * formula
| Until of int * interval * formula * formula
| Bool of bool

(*precondition: temporal formulas always bigger than their subformulas*)
let rec maxidx_of = function
  | P (i, x) -> i
  | Conj (f, g) | Disj (f, g) -> max (maxidx_of f) (maxidx_of g)
  | Neg f -> maxidx_of f
  | Prev (j, _, _) | Next (j, _, _) -> j
  | Since (j, _, _, _) | Until (j, _, _, _) -> j
  | Bool _ -> -1

let rec lift n = function
  | P (i, x) -> P (i + n, x)
  | Conj (f, g) -> Conj (lift n f, lift n g)
  | Disj (f, g) -> Disj (lift n f, lift n g)
  | Neg f -> Neg (lift n f)
  | Prev (j, i, f) -> Prev (j + n, i, lift n f)
  | Next (j, i, f) -> Next (j + n, i, lift n f)
  | Since (j, i, f, g) -> Since (j + n, i, lift n f, lift n g)
  | Until (j, i, f, g) -> Until (j + n, i, lift n f, lift n g)
  | Bool b -> Bool b

let p x = P (0, x)
let conj f g = Conj (f, lift (maxidx_of f + 1) g)
let disj f g = Disj (f, lift (maxidx_of f + 1) g)
let neg f = Neg f
let imp f g = disj (neg f) g
let iff f g = conj (imp f g) (imp g f)
let prev i f = Prev (maxidx_of f + 1, i, f)
let next i f = Next (maxidx_of f + 1, i, f)
let since i f g = let n = maxidx_of f + 1 in Since (maxidx_of g + n + right_I i + 1, i, f, lift n g)
let until i f g = let n = maxidx_of f + 1 in Until (maxidx_of g + n + right_I i + 1, i, f, lift n g)
let bool b = Bool b
let release i f g = neg (until i (neg f) (neg g))
let weak_until i f g = release i g (disj f g)
let trigger i f g = neg (since i (neg f) (neg g))
let eventually i f = until i (bool true) f
let always i f = neg (eventually i (neg f))
let once i f = since i (bool true) f
let historically i f = neg (once i (neg f))

module MTL : Formula with type f = formula = struct

type f = formula

let rec atoms = function
  | P (_, x) -> SS.singleton x
  | Conj (f, g) | Disj (f, g) | Since (_, _, f, g) | Until (_, _, f, g) -> SS.union (atoms f) (atoms g)
  | Neg f | Prev (_, _, f) | Next (_, _, f) -> atoms f
  | Bool _ -> SS.empty

let rec bounded_future = function
  | Bool _ -> true
  | P _ -> true
  | Since (_, _, f, g) | Conj (f, g) | Disj (f, g) -> bounded_future f && bounded_future g
  | Until (_, i, f, g) ->
      case_I (fun _ -> true) (fun _ -> false) i && bounded_future f && bounded_future g
  | Neg f | Prev (_, _, f) | Next (_, _, f) -> bounded_future f

let rec print_formula l out = function
  | P (_, x) -> Printf.fprintf out "%s" x
  | Bool b -> Printf.fprintf out (if b then "⊤" else "⊥")
  | Conj (f, g) -> Printf.fprintf out (paren l 2 "%a ∧ %a") (print_formula 2) f (print_formula 2) g
  | Disj (f, g) -> Printf.fprintf out (paren l 1 "%a ∨ %a") (print_formula 1) f (print_formula 2) g
  | Neg f -> Printf.fprintf out "¬%a" (print_formula 3) f
  | Prev (_, i, f) -> Printf.fprintf out (paren l 3 "●%a %a") print_interval i (print_formula 4) f
  | Next (_, i, f) -> Printf.fprintf out (paren l 3 "○%a %a") print_interval i (print_formula 4) f
  | Since (_, i, f, g) -> Printf.fprintf out (paren l 0 "%a S%a %a") (print_formula 4) f print_interval i (print_formula 4) g
  | Until (_, i, f, g) -> Printf.fprintf out (paren l 0 "%a U%a %a") (print_formula 4) f print_interval i (print_formula 4) g
let print_formula = print_formula 0

let idx_of = function
  | P (j, _) | Prev (j, _, _) | Next (j, _, _) | Since (j, _, _, _) | Until (j, _, _, _) -> j
  | _ -> failwith "not an indexed subformula"

let conj_lifted f g = Conj (f, g)
let disj_lifted f g = Disj (f, g)
let since_lifted i f g = Since (maxidx_of g + right_I i + 1, i, f, g)
let until_lifted i f g = Until (maxidx_of g + right_I i + 1, i, f, g)

let rec sub = function 
  | Neg f -> sub f
  | Conj (f, g) -> sub g @ sub f
  | Disj (f, g) -> sub g @ sub f
  | Next (j,i,f) -> Next (j,i,f) :: sub f
  | Prev (j,i,f) -> Prev (j,i,f) :: sub f
  | Since (j, i, f, g) -> Since (j,i,f,g) :: sub g @ sub f
  | Until (j, i, f, g) -> Until (j,i,f,g) :: sub g @ sub f
  | P _ as f -> [f]
  | _ -> []

let aux = function
  | Since (j,i,f,g) -> List.map (fun n -> Since (j - n, subtract_I n i, f, g)) (1 -- right_I i)
  | Until (j,i,f,g) -> List.map (fun n -> Until (j - n, subtract_I n i, f, g)) (1 -- right_I i)
  | _ -> []

let ssub f = List.rev (List.concat (List.map (fun x -> x :: aux x) (sub f)))
let mk cnj dsj neg bo idx =
  let rec go = function
    | Conj (f, g) -> cnj (go f) (go g)
    | Disj (f, g) -> dsj (go f) (go g)
    | Neg f -> neg (go f)
    | Bool b -> bo b
    | f -> idx (idx_of f) in
  go
let mk_cell = mk cconj cdisj cneg (fun b -> B b)
let mk_fcell = mk fcconj fcdisj fcneg (fun b -> Now (B b))

let progress f_vec a t_prev ev t =
  let n = Array.length f_vec in
  let b = Array.make n (Now (B false)) in
  let curr = mk_fcell (fun i -> b.(i)) in
  let prev = mk_cell (fun i -> a.(i)) in
  let prev f = subst_cell_future b (prev f) in
  let next = mk_cell (fun i -> V (true, i)) in
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
          else fcconj (curr f) (prev (since_lifted (subtract_I (t - t_prev) i) f g)))
    | Until (_, i, f, g) -> fcdisj
        (if mem_I 0 i then curr g else Now (B false))
        (Later (fun t_next -> if case_I (fun i -> t_next - t > right_BI i) (fun _ -> false) i
          then B false
          else cconj (eval_future_cell t_next (curr f))
            (next (until_lifted (subtract_I (t_next - t) i) f g))))
    | _ -> failwith "not a temporal formula"
  done;
  b

end

module Monitor_MTL = Monitor.Make(MTL)