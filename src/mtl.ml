(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Util

type timestamp = int

type uinterval = UI of int
type binterval = BI of int * int
type interval = B of binterval | U of uinterval
let case_I f1 f2 = function
  | (B i) -> f1 i
  | (U i) -> f2 i
let map_I f1 f2 = case_I (fun i -> B (f1 i)) (fun i -> U (f2 i))

let subtract n i = if i < n then 0 else i - n

let lclosed_UI i = UI i
let lopen_UI i = UI (i + 1)
let nonempty_BI l r = if l <= r then BI (l, r) else raise (Failure "empty interval")
let lclosed_rclosed_BI i j = nonempty_BI i j
let lopen_rclosed_BI i j = nonempty_BI (i + 1) j
let lclosed_ropen_BI i j = nonempty_BI i (j - 1)
let lopen_ropen_BI i j = nonempty_BI (i + 1) (j - 1)
let left_UI (UI i) = i
(*let left_BI (BI (i, _)) = i*)
let right_BI (BI (_, j)) = j
(*val left_I = case_I left_BI left_UI*)
let right_I = case_I right_BI left_UI
let full = U (UI 0)

let subtract_UI n (UI i) = UI (subtract n i)
let subtract_BI n (BI (i, j)) = BI (subtract n i, subtract n j)
let subtract_I n = map_I (subtract_BI n) (subtract_UI n)

type formula =
| P of int * string
| Conj of formula * formula
| Disj of formula * formula
| Neg of formula
| Prev of int * interval * formula
| Since of int * interval * formula * formula
| Next of int * interval * formula
| Until of int * binterval * formula * formula
| Bool of bool

let rec atoms = function
  | P (_, x) -> SS.singleton x
  | Conj (f, g) | Disj (f, g) | Since (_, _, f, g) | Until (_, _, f, g) -> SS.union (atoms f) (atoms g)
  | Neg f | Prev (_, _, f) | Next (_, _, f) -> atoms f
  | Bool _ -> SS.empty

let print_binterval out = function
  | BI (i, j) -> Printf.fprintf out "[%d,%d]" i j

let print_interval out = function
  | U (UI i) -> Printf.fprintf out "[%d,∞)" i
  | B i -> Printf.fprintf out "%a" print_binterval i

let rec print_formula l out = function
  | P (_, x) -> Printf.fprintf out "%s" x
  | Bool b -> Printf.fprintf out (if b then "⊤" else "⊥")
  | Conj (f, g) -> Printf.fprintf out (paren l 2 "%a ∧ %a") (print_formula 2) f (print_formula 2) g
  | Disj (f, g) -> Printf.fprintf out (paren l 1 "%a ∨ %a") (print_formula 1) f (print_formula 2) g
  | Neg f -> Printf.fprintf out "¬%a" (print_formula 3) f
  | Prev (_, i, f) -> Printf.fprintf out (paren l 3 "●%a %a") print_interval i (print_formula 4) f
  | Next (_, i, f) -> Printf.fprintf out (paren l 3 "○%a %a") print_interval i (print_formula 4) f
  | Since (_, i, f, g) -> Printf.fprintf out (paren l 3 "%a S%a %a") (print_formula 4) f print_interval i (print_formula 4) g
  | Until (_, i, f, g) -> Printf.fprintf out (paren l 3 "%a U%a %a") (print_formula 4) f print_binterval i (print_formula 4) g
let print_formula = print_formula 0

let idx_of = function
  | P (j, _) | Prev (j, _, _) | Next (j, _, _) | Since (j, _, _, _) | Until (j, _, _, _) -> j
  | _ -> failwith "not an indexed subformula"

let rec maxidx_of = function
  | P (i, x) -> i
  | Conj (f, g) | Disj (f, g) -> max (maxidx_of f) (maxidx_of g)
  | Neg f -> maxidx_of f
  | Prev (j, _, f) | Next (j, _, f) -> max j (maxidx_of f)
  | Since (j, _, f, g) | Until (j, _, f, g) -> max j (max (maxidx_of f) (maxidx_of g))
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
let conj_lifted f g = Conj (f, g)
let disj_lifted f g = Disj (f, g)
let prev i f = Prev (maxidx_of f + 1, i, f)
let next i f = Next (maxidx_of f + 1, i, f)
let since i f g = let n = maxidx_of f + 1 in Since (maxidx_of g + n + right_I i + 1, i, f, lift n g)
let since_lifted i f g = Since (maxidx_of g + right_I i + 1, i, f, g)
let until i f g = let n = maxidx_of f + 1 in Until (maxidx_of g + n + right_BI i + 1, i, f, lift n g)
let until_lifted i f g = Until (maxidx_of g + right_BI i + 1, i, f, g)
let bool b = Bool b
let release i f g = neg (until i (neg f) (neg g))
let weak_until i f g = release i g (disj f g)
let trigger i f g = neg (since i (neg f) (neg g))
let eventually i f = until i (bool true) f
let always i f = neg (eventually i (neg f))
let once i f = since i (bool true) f
let historically i f = neg (once i (neg f))

let mem_UI t (UI l) = l <= t
let mem_BI t (BI (l, r)) = l <= t && t <= r
let mem_I t = case_I (mem_BI t) (mem_UI t)

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
  | Until (j,i,f,g) -> List.map (fun n -> Until (j - n, subtract_BI n i, f, g)) (1 -- right_BI i)
  | _ -> []

let ssub f = List.rev (List.concat (List.map (fun x -> x :: aux x) (sub f)))

type 'a trace = (SS.t * timestamp) list

let t = SS.of_list ["abc"; "cde"]