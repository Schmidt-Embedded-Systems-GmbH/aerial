(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

(* Copy of Damien Pous' implementation of Bdd's but monomorphised with int keys and bool leaves*)

open Util
open Channel
open Hashcons

(** BDD nodes are hashconsed to ensure unicity, whence the following two-levels type *)
type bdd = descr hash_consed
and descr = V of bool | N of int * bdd * bdd
let head x = x.node

type mem = {
  m: descr Hashcons.t;
  h: bool -> int;
  e: bool -> bool -> bool;
}

let init h e = {m=Hashcons.create 57;h;e}

(** specific hashconsing function *)
let hashcons m =
  let hash = function V x -> m.h x | N(a,l,r) -> Hashtbl.hash (a,l.hkey,r.hkey) in
  let equal x y = match x,y with
    | V x, V y -> m.e x y
    | N(a,l,r), N(a',l',r') -> a=a' && l==l' && r==r'
    | _ -> false
  in hashcons hash equal m.m

let constant mem v = hashcons mem (V v)

let node mem b x y = if x==y then x else hashcons mem (N(b,x,y))

let tag x = x.tag

let hash x = x.hkey

let cmp x y = compare x.tag y.tag

(* utilities for memoised recursive function over hashconsed values *)

let cleaners = ref []
let on_clean f = cleaners := f :: !cleaners
let reset_caches () = List.iter (fun f -> f()) !cleaners

let memo_rec1 f =
  let t = ref Hmap.empty in
  on_clean (fun () -> t := Hmap.empty);
  let rec aux x =
    try Hmap.find x !t
    with Not_found ->
      let y = f aux x in
      t := Hmap.add x y !t; y
  in aux

let memo_rec2 f =
  let t = ref Hmap.empty in
  on_clean (fun () -> t := Hmap.empty);
  let rec aux x y =
    try let tx = Hmap.find x !t in
	try Hmap.find y !tx
	with Not_found ->
	  let z = f aux x y in
	  tx := Hmap.add y z !tx; z
    with Not_found ->
      let z = f aux x y in
      let tx = ref Hmap.empty in
      t := Hmap.add x tx !t;
      tx := Hmap.add y z !tx;
      z
  in aux

let m = init Hashtbl.hash (=)

let bot = constant m false
let top = constant m true
let var b = node m b bot top
let rav b = node m b top bot

let neg = memo_rec1 (fun neg x ->
  match head x with
    | V v -> constant m (not v)
    | N(b,l,r) -> node m b (neg l) (neg r)
)

let dsj = memo_rec2 (fun dsj x y ->
  if x==y then x else
  match head x, head y with
    | V true, _ | _, V false -> x
    | _, V true | V false, _ -> y
    | N(b,l,r), N(b',l',r') ->
      match compare b b' with
	| 0 -> node m b  (dsj l l') (dsj r r')
	| 1 -> node m b' (dsj x l') (dsj x r')
	| _ -> node m b  (dsj l y ) (dsj r y )
)

let cnj = memo_rec2 (fun cnj x y ->
  if x==y then x else
  match head x, head y with
    | V false, _ | _, V true -> x
    | _, V false | V true, _ -> y
    | N(b,l,r), N(b',l',r') ->
      match compare b b' with
	| 0 -> node m b  (cnj l l') (cnj r r')
	| 1 -> node m b' (cnj x l') (cnj x r')
	| _ -> node m b  (cnj l y ) (cnj r y )
)

let ite b t e = dsj (cnj b t) (cnj (neg b) e)

let rec string_of_bdd i x = match head x with
  | V false -> Printf.sprintf "0"
  | V true -> Printf.sprintf "1"
  | N(a,{node=V false},{node=V true}) -> Printf.sprintf "%d" a
  | N(a,{node=V true},{node=V false}) -> Printf.sprintf "!%d" a
  | N(a,{node=V true},r) -> Printf.sprintf (paren i 0 "!%d+%a") a (fun _ -> string_of_bdd 0) r
  | N(a,l,{node=V true}) -> Printf.sprintf (paren i 0 "%d+%a") a (fun _ -> string_of_bdd 0) l
  | N(a,{node=V false},r) -> Printf.sprintf (paren i 1 "%d%a") a (fun _ -> string_of_bdd 1) r
  | N(a,l,{node=V false}) -> Printf.sprintf (paren i 1 "!%d%a") a (fun _ -> string_of_bdd 1) l
  | N(a,l,r) -> Printf.sprintf (paren i 0 "%d%a+!%d%a") a (fun _ -> string_of_bdd 1) r a (fun _ -> string_of_bdd 1) l

module Cell : Cell.Cell = struct
(*
let m = init Hashtbl.hash (=)
*)
let maybe_output case_cell fmt skip d cell f =
  case_cell
    (fun b ->
      let fmt = if skip then fmt else output_verdict fmt (d, b)
      in fun x -> (x, fmt))
    (fun x -> f (d, cell) fmt x) cell

type cell = bdd
type future_cell = Now of cell | Later of (timestamp -> cell)

let cell_to_string = string_of_bdd 0

let print_cell out c = output_event out (cell_to_string c)

let cbool b = if b then top else bot
let cvar b i = if b then node m i top bot else node m i bot top
let cconj = cnj
let cdisj = dsj
let cneg = neg

let rec map_cell f x = match head x with
  | V true -> top
  | V false -> bot
  | N (k, l, r) -> ite (f k) (map_cell f l) (map_cell f r)

let case_cell_bool f g x = match head x with
  | V b -> f b
  | _ -> g

let maybe_output_cell fmt = maybe_output case_cell_bool fmt

let maybe_output_future fmt d fcell f =
  match fcell with
  | Now cell -> maybe_output_cell fmt false d cell (fun _ -> f)
  | Later _ -> f fmt

let eval_future_cell t = function
  | Now c -> c
  | Later f -> f t

let cimp l r = cdisj (cneg l) r
let cif b t e = cconj (cimp b t) (cimp (cneg b) e)

let is_true x = match head x with
  | V true -> true
  | _ -> false

let is_false x = match head x with
  | V false -> true
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

let rec map_cell_future f x = match head x with
  | N (x, l, r) -> (match f x, map_cell_future f l, map_cell_future f r with
     | Now c, Now t, Now e -> Now (ite c t e)
     | c, l, r -> Later (fun d ->
       ite (eval_future_cell d c) (eval_future_cell d l) (eval_future_cell d r)))
  | _ -> Now x

let map_future_cell f = function
  | Now c -> map_cell_future f c
  | Later g -> Later (fun delta -> map_cell (fun x -> eval_future_cell delta (f x)) (g delta))

let subst_cell v = map_cell (Array.get v)
let subst_cell_future v = map_cell_future (Array.get v)

let rec equiv t1 t2 = (t1 = t2)

end
