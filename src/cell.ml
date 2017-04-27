(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Util

let maybe_output case_cell fmt skip d cell f =
  case_cell (fun b -> (if skip then fun _ -> () else output_verdict fmt) (d, b); fun x -> x) (f (d, cell)) cell

type cell = V of bool * int | B of bool | C of cell * cell | D of cell * cell

let rec compare c d = match c, d with
  | V (true, i), V (true, j) -> Pervasives.compare i j
  | V (true, i), _ -> -1
  | _, V (true, i) -> 1
  | V (false, i), V (false, j) -> Pervasives.compare i j
  | V (false, _), _ -> -1
  | _, V (false, _) -> 1
  | B b, B c -> Pervasives.compare b c
  | B _, _ -> -1
  | _, B _ -> 1
  | C (c, d), C (c', d') -> let cc = Pervasives.compare c c' in if cc = 0 then compare d d' else cc
  | C _, _ -> -1
  | _, C _ -> 1
  | D (c, d), D (c', d') -> let cc = Pervasives.compare c c' in if cc = 0 then compare d d' else cc

type future_cell = Now of cell | Later of (timestamp -> cell)

let rec print_cell l out = function
  | V (b, x) -> Printf.fprintf out "%sx%d" (if b then "" else "¬") x
  | B b -> Printf.fprintf out (if b then "⊤" else "⊥")
  | C (f, g) -> Printf.fprintf out (paren l 2 "%a ∧ %a") (print_cell 2) f (print_cell 2) g
  | D (f, g) -> Printf.fprintf out (paren l 1 "%a ∨ %a") (print_cell 1) f (print_cell 1) g
let print_cell = print_cell 0

let case_cell_bool f g = function
  | B b -> f b
  | _ -> g

let maybe_output_cell fmt = maybe_output case_cell_bool fmt

let maybe_output_future fmt d fcell f =
  match fcell with
  | Now cell -> maybe_output_cell fmt false d cell (fun _ -> f)
  | Later _ -> f

let eval_future_cell t = function
  | Now c -> c
  | Later f -> f t

let rec cconj x y = match x, y with
  | (B c, d) | (d, B c) -> if c then d else B c
  | (C (c, d), e) -> cconj c (cconj d e)
  | (c, C (d, e)) ->
    let cd = compare c d in
    if cd = 0 then C (d, e)
    else if cd < 0 then C (c, C (d, e))
    else C (d, cconj c e)
  | _ -> 
    let xy = compare x y in
    if xy = 0 then x
    else if xy < 0 then C (x, y)
    else C (y, x)

let rec cdisj x y = match x, y with
  | (B c, d) | (d, B c) -> if c then B c else d
  | (D (c, d), e) -> cdisj c (cdisj d e)
  | (c, D (d, e)) ->
    let cd = compare c d in
    if cd = 0 then D (d, e)
    else if cd < 0 then D (c, D (d, e))
    else D (d, cdisj c e)
  | _ -> 
    let xy = compare x y in
    if xy = 0 then x
    else if xy < 0 then D (x, y)
    else D (y, x)

let rec cneg = function
  | C (c, d) -> cdisj (cneg c) (cneg d)
  | D (c, d) -> cconj (cneg c) (cneg d)
  | B b -> B (not b)
  | V (b, x) -> V (not b, x)

let cimp l r = cdisj (cneg l) r 
let cif b t e = cconj (cimp b t) (cimp (cneg b) e)

let is_true = function
  | B true -> true
  | _ -> false

let is_false = function
  | B false -> true
  | _ -> false

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

let rec map_cell f = function
  | C (c, d) -> cconj (map_cell f c) (map_cell f d)
  | D (c, d) -> cdisj (map_cell f c) (map_cell f d)
  | B b -> B b
  | V (b, x) -> maybe_flip b (f x)

let rec map_cell_future f = function
  | C (c, d) -> fcconj (map_cell_future f c) (map_cell_future f d)
  | D (c, d) -> fcdisj (map_cell_future f c) (map_cell_future f d)
  | B b -> Now (B b)
  | V (b, x) -> maybe_flip_future b (f x)

let subst_cell v = map_cell (Array.get v)
let subst_cell_future v = map_cell_future (Array.get v)

type bdd = TT | FF | Node of int * bdd * bdd

module IntMap = Map.Make(struct type t = int let compare = Pervasives.compare end)

let rec map_of m k = try Some (IntMap.find k m) with Not_found -> None

let node x t1 t2 = if t1 = t2 then t1 else Node (x, t1, t2)

let rec reduce xs = function
  | TT -> TT
  | FF -> FF
  | Node (x, t1, t2) -> match map_of xs x with
    | None -> node x (reduce (IntMap.add x true xs) t1) (reduce (IntMap.add x false xs) t2)
    | Some b -> reduce xs (if b then t1 else t2)

let rec norm xs x t1 t2 = match x with
  | TT -> reduce xs t1
  | FF -> reduce xs t2
  | Node (x, u1, u2) -> match map_of xs x with
    | None -> node x (norm (IntMap.add x true xs) u1 t1 t2) (norm (IntMap.add x false xs) u2 t1 t2)
    | Some true -> norm xs u1 t1 t2
    | Some false -> norm xs u2 t1 t2

let rec bdd_of = function
  | B b -> if b then TT else FF
  | V (true, i) -> Node (i, TT, FF)
  | V (false, i) -> Node (i, FF, TT)
  | C (b1, b2) -> norm IntMap.empty (bdd_of b1) (bdd_of b2) FF
  | D (b1, b2) -> norm IntMap.empty (bdd_of b1) TT (bdd_of b2)

let rec size = function
  | C (b1, b2) | D (b1, b2) -> 1 + size b1 + size b2
  | _ -> 0

let rec equiv b1 b2 =
  let t1 = bdd_of b1 in
  let t2 = bdd_of b2 in
  TT = norm IntMap.empty t1 t2 (norm IntMap.empty t2 FF TT)