(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Util
open Mtl

let output_verdict fmt ((t, i), b) = Printf.fprintf fmt "%d:%d %B\n" t i b
let output_eq fmt ((t, i), (t', j)) = Printf.fprintf fmt "%d:%d = %d:%d\n" t i t' j

let maybe_output case_cell fmt skip d cell f =
  case_cell (fun b -> (if skip then fun _ -> () else output_verdict fmt) (d, b); fun x -> x) (f (d, cell)) cell

type mode = NAIVE | COMPRESS_LOCAL | COMPRESS_GLOBAL

type cell = V of bool * int | B of bool | C of cell * cell | D of cell * cell
type future_cell = Now of cell | Later of (timestamp -> cell)

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

let cconj x y = match x, y with
  | (B c, d) | (d, B c) -> if c then d else B c
  | _ -> C (x, y)

let cdisj x y = match x, y with
  | (B c, d) | (d, B c) -> if c then B c else d
  | _ -> D (x, y)

let rec cneg = function
  | C (c, d) -> D (cneg c, cneg d)
  | D (c, d) -> C (cneg c, cneg d)
  | B b -> B (not b)
  | V (b, x) -> V (not b, x)

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

module IntMap = Map.Make(struct type t = int let compare = compare end)

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
  (*let _ = if size b1 + size b2 > 0 then Format.printf "%d:%d\n%!" (size b1) (size b2) else () in*)
  let t1 = bdd_of b1 in
  let t2 = bdd_of b2 in
  TT = norm IntMap.empty t1 t2 (norm IntMap.empty t2 FF TT)

type ctxt =
  {history: ((timestamp * int) * cell) list; (*reversed*)
   now: timestamp * int;
   arr: future_cell array;
   skip: bool}
type monitor =
  {init: ctxt;
   step: SS.t * timestamp -> ctxt -> ctxt}

let create fmt mode formula =
  let _ = Printf.fprintf fmt "Monitoring %a\n%!" print_formula formula in
  let f_vec = Array.of_list (ssub formula) in
  let n = Array.length f_vec in
  let rec next = function
    | Conj (f, g) -> cconj (next f) (next g)
    | Disj (f, g) -> cdisj (next f) (next g)
    | Neg f -> cneg (next f)
    | Bool b -> B b
    | f -> V (true, idx_of f) in

  let init = {history = []; now = (-1, 0); arr = Array.make n (Now (B false)); skip = true} in

  let rec check_dup res entry h = match entry, h with
    | (_, []) -> entry :: List.rev res
    | (((t, i), c), (((t', j), d) as entry') :: history) ->
        if mode = COMPRESS_GLOBAL || t = t'
        then
          if equiv c d
          then (output_eq fmt ((t, i), (t', j)); List.rev res @ entry' :: history)
          else check_dup (entry' :: res) entry history
        else entry :: List.rev res @ entry' :: history in
  
  let add = if mode = NAIVE then List.cons else check_dup [] in

  let progress a t_prev ev t =
    let b = Array.make n (Now (B false)) in
    let rec curr = function
      | Conj (f, g) -> fcconj (curr f) (curr g)
      | Disj (f, g) -> fcdisj (curr f) (curr g)
      | Neg f -> fcneg (curr f)
      | Bool b -> Now (B b)
      | f -> b.(idx_of f) in
    let rec prev = function
      | Conj (f, g) -> cconj (prev f) (prev g)
      | Disj (f, g) -> cdisj (prev f) (prev g)
      | Neg f -> cneg (prev f)
      | Bool b -> B b
      | f -> a.(idx_of f) in
    let prev f = subst_cell_future b (prev f) in
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
          (if mem_BI 0 i then curr g else Now (B false))
          (Later (fun t_next -> if t_next - t > right_BI i
            then B false
            else cconj (eval_future_cell t_next (curr f))
              (next (until_lifted (subtract_BI (t_next - t) i) f g))))
      | _ -> failwith "not a temporal formula"
    done;
    b in

  let step (ev, t') ctxt =
    let (t, i) as d = ctxt.now in
    let fa = ctxt.arr in
    let skip = ctxt.skip in
    let a = Array.map (eval_future_cell t') fa in
    let old_history = ctxt.history in
    let clean_history = List.fold_left (fun history (d, cell) ->
      maybe_output_cell fmt false d (subst_cell a cell) add history) [] old_history in
    let history = maybe_output_cell fmt skip d a.(n - 1) add clean_history in
    let d' = (t', if t = t' then i + 1 else 0) in
    let fa' = progress a t ev t' in
    let history' = List.fold_left (fun history ((d, cell) as x) ->
      maybe_output_future fmt d (subst_cell_future fa' cell) (List.cons x) history) [] history in
    let skip' = maybe_output_future fmt d' fa'.(n - 1) (fun _ -> false) true in
    {history = history'; now = d'; arr = fa'; skip = skip'} in

  {init=init; step=step}
