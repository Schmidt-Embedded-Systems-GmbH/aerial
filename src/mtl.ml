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
open Channel

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
| Now of int * formula

let rec formula_to_string l = function
  | P (_, x) -> Printf.sprintf "%s" x
  | Bool b -> Printf.sprintf (if b then "⊤" else "⊥")
  | Conj (f, g) -> Printf.sprintf (paren l 2 "%a ∧ %a") (fun x -> formula_to_string 2) f (fun x -> formula_to_string 2) g
  | Disj (f, g) -> Printf.sprintf (paren l 1 "%a ∨ %a") (fun x -> formula_to_string 1) f (fun x -> formula_to_string 2) g
  | Neg f -> Printf.sprintf "¬%a" (fun x -> formula_to_string 3) f
  | Prev (_, i, f) -> Printf.sprintf (paren l 3 "●%a %a") (fun x -> interval_to_string) i (fun x -> formula_to_string 4) f
  | Now (_, f) -> Printf.sprintf (paren l 3 "%a") (fun x -> formula_to_string 4) f
  | Next (_, i, f) -> Printf.sprintf (paren l 3 "○%a %a") (fun x -> interval_to_string) i (fun x -> formula_to_string 4) f
  | Since (_, i, f, g) -> Printf.sprintf (paren l 0 "%a S%a %a") (fun x -> formula_to_string 4) f (fun x -> interval_to_string) i (fun x -> formula_to_string 4) g
  | Until (_, i, f, g) -> Printf.sprintf (paren l 0 "%a U%a %a") (fun x -> formula_to_string 4) f (fun x -> interval_to_string) i (fun x -> formula_to_string 4) g
let formula_to_string = formula_to_string 0

let print_formula out f = output_event out (formula_to_string f)


(*precondition: temporal formulas always bigger than their subformulas*)
let rec maxidx_of = function
  | P (i, x) -> i
  | Conj (f, g) | Disj (f, g) -> max (maxidx_of f) (maxidx_of g)
  | Neg f -> maxidx_of f
  | Prev (j, _, _) | Next (j, _, _) -> j
  | Since (j, _, _, _) | Until (j, _, _, _) -> j
  | Bool _ -> -1
  | Now (j, _) -> j

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
  | Now (j, f) -> Now (j + n, lift n f)

let p x = P (0, x)
let bool b = Bool b
let conj f g =
  match f, g with
  | Bool true, g | g, Bool true -> g
  | Bool false, _ | _, Bool false -> bool false
  | _ -> Conj (f, lift (maxidx_of f + 1) g)
let disj f g =
  match f, g with
  | Bool false, g | g, Bool false -> g
  | Bool true, _ | _, Bool true -> bool true
  | _ -> Disj (f, lift (maxidx_of f + 1) g)
let rec neg f =
  match f with
  | Disj (f, g) -> Conj (neg f, neg g)
  | Conj (f, g) -> Disj (neg f, neg g)
  | Neg f -> f
  | _ -> Neg f
let imp f g = disj (neg f) g
let iff f g = conj (imp f g) (imp g f)
let prev i f = Prev (maxidx_of f + 2, i, f)
let now f = Now (maxidx_of f + 1, f)
let next i f = Next (maxidx_of f + 1, i, f)

let since_lifted i f g = Since (maxidx_of g + right_I i + 1, i, f, g)
let until_lifted i f g = Until (maxidx_of g + right_I i + 1, i, f, g)

let since i f g = let n = maxidx_of f + 1 in since_lifted i f (lift n g)
let until i f g = let n = maxidx_of f + 1 in until_lifted i f (lift n g)
let release i f g = neg (until i (neg f) (neg g))
let weak_until i f g = release i g (disj f g)
let trigger i f g = neg (since i (neg f) (neg g))
let eventually i f = until i (bool true) f
let always i f = neg (eventually i (neg f))
let once i f = since i (bool true) f
let historically i f = neg (once i (neg f))

module MTL(C : Cell) : Formula with type f = formula = struct

type f = formula
type memory = ()
module C = C
open C

let rec bounded_future = function
  | Bool _ -> true
  | P _ -> true
  | Since (_, _, f, g) | Conj (f, g) | Disj (f, g) -> bounded_future f && bounded_future g
  | Until (_, i, f, g) ->
      case_I (fun _ -> true) (fun _ -> false) i && bounded_future f && bounded_future g
  | Neg f | Prev (_, _, f) | Next (_, _, f) | Now (_, f) -> bounded_future f

(* let rec print_formula l out = function
  | P (_, x) -> Printf.fprintf out "%s" x
  | Bool b -> Printf.fprintf out (if b then "⊤" else "⊥")
  | Conj (f, g) -> Printf.fprintf out (paren l 2 "%a ∧ %a") (print_formula 2) f (print_formula 2) g
  | Disj (f, g) -> Printf.fprintf out (paren l 1 "%a ∨ %a") (print_formula 1) f (print_formula 1) g
  | Neg f -> Printf.fprintf out "¬%a" (print_formula 3) f
  | Prev (_, i, f) -> Printf.fprintf out (paren l 3 "●%a %a") print_interval i (print_formula 4) f
  | Next (_, i, f) -> Printf.fprintf out (paren l 3 "○%a %a") print_interval i (print_formula 4) f
  | Since (_, i, f, g) -> Printf.fprintf out (paren l 0 "%a S%a %a") (print_formula 4) f print_interval i (print_formula 4) g
  | Until (_, i, f, g) -> Printf.fprintf out (paren l 0 "%a U%a %a") (print_formula 4) f print_interval i (print_formula 4) g
let print_formula = print_formula 0 *)

let print_formula = print_formula

let idx_of = function
  | P (j, _) | Prev (j, _, _) | Next (j, _, _) | Since (j, _, _, _) | Until (j, _, _, _) -> j | Now (j, _) -> j
  | _ -> failwith "not an indexed subformula"

let rec sub = function
  | Neg f -> sub f
  | Conj (f, g) -> sub g @ sub f
  | Disj (f, g) -> sub g @ sub f
  | Next (j,i,f) -> Next (j,i,f) :: sub f
  | Prev (j,i,f) -> Prev (j,i,f) :: Now (j - 1, f) :: sub f
  | Since (j, i, f, g) -> Since (j,i,f,g) :: sub g @ sub f
  | Until (j, i, f, g) -> Until (j,i,f,g) :: sub g @ sub f
  | P _ as f -> [f]
  | _ -> []

let aux = function
  | Since (j,i,f,g) -> List.map (fun n -> Since (j - n, subtract_I n i, f, g)) (0 -- right_I i)
  | Until (j,i,f,g) -> List.map (fun n -> Until (j - n, subtract_I n i, f, g)) (0 -- right_I i)
  | f -> [f]

let init f = (f, Array.of_list (List.rev (List.concat (List.map aux (sub f)))), ())
let mk cnj dsj neg bo idx =
  let rec go = function
    | Conj (f, g) -> cnj (go f) (go g)
    | Disj (f, g) -> dsj (go f) (go g)
    | Neg f -> neg (go f)
    | Bool b -> bo b
    | f -> idx (idx_of f) in
  go
let mk_cell = mk cconj cdisj cneg cbool
let mk_fcell = mk fcconj fcdisj fcneg fcbool

let progress (f_vec, _) (delta, ev) a =
  let n = Array.length f_vec in
  let b = Array.make n (fcbool false) in
  let curr = mk_fcell (fun i -> b.(i)) in
  let prev = mk_fcell (fun i -> a.(i)) in
  let prev f = subst_cell_future b (eval_future_cell delta (prev f)) in
  let next = mk_cell (cvar true) in
  for i = 0 to n - 1 do
    b.(i) <- match f_vec.(i) with
    | P (_, x) -> fcbool (SS.mem x ev)
    | Prev (_, i, f) ->
          if mem_I delta i then prev (now f) else fcbool false
    | Now (_, f) -> curr f
    | Next (_, i, f) ->
        Later (fun delta' -> if mem_I delta' i then next f else cbool false)
    | Since (_, i, f, g) -> fcdisj
        (if mem_I 0 i then curr g else fcbool false)
        (if case_I (fun i -> delta > right_BI i) (fun _ -> false) i
          then fcbool false
          else fcconj (curr f) (prev (since_lifted (subtract_I delta i) f g)))
    | Until (_, i, f, g) -> fcdisj
        (if mem_I 0 i then curr g else fcbool false)
        (Later (fun delta' -> if case_I (fun i -> delta' > right_BI i) (fun _ -> false) i
          then cbool false
          else cconj (eval_future_cell delta' (curr f))
            (next (until_lifted (subtract_I delta' i) f g))))
    | _ -> failwith "not a temporal formula"
  done;
  b

end

module Monitor_MTL(C : Cell) = Monitor.Make(MTL(C))
