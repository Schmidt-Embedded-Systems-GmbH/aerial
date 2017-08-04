(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Util
open Channel
(*open Big_int*)

module Cell : Cell.Cell = struct

type bdd = TT | FF | Node of int * int * bdd * bdd

let rec map_of m k = m k
let empty _ = None
let add x b f y = if x = y then Some b else f y
(*
let hash = function
  | TT -> zero_big_int
  | FF -> unit_big_int
  | Node (h, _, _, _) -> h

let pair a b = if ge_big_int a b then add_big_int (square_big_int a) (add_big_int a b) else add_big_int a (square_big_int b)
let rec pairs = function
  | x :: y :: ys -> pairs (pair x y :: ys)
  | [x] -> x
  | [] -> failwith "cannot pair empty list"
*)
(*let pairs is = let res = pairs is in (Printf.printf "Computed hash: %d\n%!" res; res)*)
(*
let node x t1 t2 =
  if eq_big_int (hash t1) (hash t2) then t1
  else Node (pairs [big_int_of_int x; hash t1; hash t2], x, t1, t2)
*)

let hash = function
  | TT -> 0
  | FF -> 1
  | Node (h, _, _, _) -> h

let pair a b = if a >= b then a * a + a + b else a + b * b
let rec pairs = function
  | x :: y :: ys -> pairs (pair x y :: ys)
  | [x] -> x
  | [] -> failwith "cannot pair empty list"
(*let pairs is = let res = pairs is in (Printf.printf "Computed hash: %d\n%!" res; res)*)

let node x t1 t2 =
  if hash t1 = hash t2 then t1
  else Node (pairs [x; hash t1; hash t2], x, t1, t2)

let rec reduce xs = function
  | TT -> TT
  | FF -> FF
  | Node (_, x, t1, t2) -> match map_of xs x with
    | None -> node x (reduce (add x true xs) t1) (reduce (add x false xs) t2)
    | Some b -> reduce xs (if b then t1 else t2)

let rec norm xs x t1 t2 = match x with
  | TT -> reduce xs t1
  | FF -> reduce xs t2
  | Node (_, x, u1, u2) -> match map_of xs x with
    | None -> node x (norm (add x true xs) u1 t1 t2) (norm (add x false xs) u2 t1 t2)
    | Some true -> norm xs u1 t1 t2
    | Some false -> norm xs u2 t1 t2


let maybe_output case_cell fmt skip d cell f =
  case_cell
    (fun b ->
      let fmt = if skip then fmt else output_verdict fmt (d, b)
      in fun x -> (x, fmt))
    (fun x -> f (d, cell) x) cell 

type cell = bdd
type future_cell = Now of cell | Later of (timestamp -> cell)

let rec cell_to_string l = function
  | TT -> Printf.sprintf "⊤"
  | FF -> Printf.sprintf "⊥"
  | Node (_, x, u1, u2) -> Printf.sprintf (paren l 1 "if %d then %a else %a") x (fun x -> cell_to_string 1) u1 (fun x -> cell_to_string 1) u2


let cell_to_string = cell_to_string 0

let print_cell out c = output_event out (cell_to_string c)

let cbool b = if b then TT else FF
let cvar b i = if b then node i TT FF else node i FF TT
let cconj b1 b2 = norm empty b1 b2 FF
let cdisj b1 b2 = norm empty b1 TT b2
let rec cneg = function
  | TT -> FF
  | FF -> TT
  | Node (_, x, l, r) -> node x (cneg l) (cneg r)

let rec map_cell f = function
  | Node (_, x, l, r) -> norm empty (f x) (map_cell f l) (map_cell f r)
  | b -> b

let case_cell_bool f g = function
  | TT -> f true
  | FF -> f false
  | _ -> g

let maybe_output_cell fmt = maybe_output case_cell_bool fmt

let maybe_output_future fmt d fcell f =
  match fcell with
  | Now cell -> maybe_output_cell fmt false d cell (fun _ -> f)
  | Later _ -> f

let eval_future_cell t = function
  | Now c -> c
  | Later f -> f t

let cimp l r = cdisj (cneg l) r 
let cif b t e = cconj (cimp b t) (cimp (cneg b) e)

let is_true = function
  | TT -> true
  | _ -> false

let is_false = function
  | FF -> true
  | _ -> false

let fcbool b = Now (cbool b)
let fcvar b i = Now (cvar b i)

let fcconj x y = match x, y with
  | (Now c, Now d) -> Now (cconj c d)
  | (Now c, Later f) | (Later f, Now c) ->
    if is_true c then Later f
    else if is_false c then Now c
    else Later (fun t -> cconj c (f t))
  | (Later f, Later g) -> Later (fun t -> cconj (f t) (g t))

let fcdisj x y = match x, y with
  | (Now c, Now d) -> Now (cdisj c d)
  | (Now c, Later f) | (Later f, Now c) ->
    if is_true c then Now c
    else if is_false c then Later f
    else Later (fun t -> cdisj c (f t))
  | (Later f, Later g) -> Later (fun t -> cdisj (f t) (g t))

let fcneg = function
  | Now c -> Now (cneg c)
  | Later f -> Later (fun t -> cneg (f t))

let fcimp l r = fcdisj (fcneg l) r 
let fcif b t e = fcconj (fcimp b t) (fcimp (fcneg b) e)

let maybe_flip b = if b then fun x -> x else cneg
let maybe_flip_future b = if b then fun x -> x else fcneg

let rec map_cell_future f = function
  | Node (_, x, l, r) -> (match f x, map_cell_future f l, map_cell_future f r with
     | Now c, Now t, Now e -> Now (norm empty c t e)
     | c, l, r -> Later (fun d ->
       norm empty (eval_future_cell d c) (eval_future_cell d l) (eval_future_cell d r)))
  | b -> Now b

let map_future_cell f = function
  | Now c -> map_cell_future f c
  | Later g -> Later (fun delta -> map_cell (fun x -> eval_future_cell delta (f x)) (g delta))

let subst_cell v = map_cell (Array.get v)
let subst_cell_future v = map_cell_future (Array.get v)

let rec equiv t1 t2 = TT = norm empty t1 t2 (norm empty t2 FF TT)

end