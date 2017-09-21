(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

(* Copy of Damien Pous' implementation of Bdd's but with int-keys instead of char-keys*)

open Util
open Channel
open Common
open Hashcons

(** BDD nodes are hashconsed to ensure unicity, whence the following two-levels type *)
type ('a,'k) node = ('a,'k) descr hash_consed
and ('a,'k) descr = V of 'a | N of 'k * ('a,'k) node * ('a,'k) node
let head x = x.node

type ('a,'k) mem = {
  m: ('a,'k) descr Hashcons.t;
  h: 'a -> int;
  e: 'a -> 'a -> bool;
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

let unary mem f =
  memo_rec1 (fun app x ->
    match head x with
      | V v -> constant mem (f v)
      | N(b,l,r) -> node mem b (app l) (app r)
  )

let binary mem f =
  memo_rec2 (fun app x y ->
    match head x, head y with
      | V v, V w -> constant mem (f v w)
      | V _, N(b,l,r) -> node mem b (app x l) (app x r)
      | N(b,l,r), V _ -> node mem b (app l y) (app r y)
      | N(b,l,r), N(b',l',r') ->
	match compare b b' with
	  | 0 -> node mem b  (app l l') (app r r')
	  | 1 -> node mem b' (app x l') (app x r')
	  | _ -> node mem b  (app l y ) (app r y )
  )

let times mem z =
  memo_rec2 (fun times f x ->
    match head f, head x with
      | V true, _ -> x
      | V false, _ -> z
      | N(b,l,r), V _ -> node mem b (times l x) (times r x)
      | N(b,l,r), N(b',l',r') ->
	match compare b b' with
	  | 0 -> node mem b  (times l l') (times r r')
	  | 1 -> node mem b' (times f l') (times f r')
	  | _ -> node mem b  (times l x ) (times r x )
  )

let hide mem a f =
  memo_rec1 (fun hide x ->
    match head x with
      | V v -> x
      | N(b,l,r) -> if a=b then f l r else node mem b (hide l) (hide r)
  )

let partial_apply mem f =
  memo_rec1 (fun pa x ->
    match head x with
      | V v -> x
      | N(b,l,r) ->
        match f b with
	  | Some false -> pa l
	  | Some true -> pa r
	  | None -> node mem b (pa l) (pa r)
  )

type ('a,'k) unifier =
    (('k * bool) list -> 'a -> 'a -> unit) ->
    ('a,'k) node -> ('a,'k) node -> unit


module Hset2 = struct
  let empty() =
    let t = ref Hmap.empty in
    on_clean (fun () -> t := Hmap.empty);
    t
  let mem t x y =
    try Hset.mem y !(Hmap.find x !t)
    with Not_found -> false
  let add t x y =
    try let tx = Hmap.find x !t in
	if Hset.mem y !tx then false
	else (tx := Hset.add y !tx; true)
    with Not_found ->
      let tx = ref (Hset.singleton y) in
      t := Hmap.add x tx !t;
      true
end

let unify_calls = Stats.counter "unify calls"
let unify_naive trace =
  let m = Hset2.empty() in
  fun f ->
    let rec app at x y =
      let app b c x y = app ((b,c)::at) x y in
      if x!=y && Hset2.add m x y then (
	Stats.incr unify_calls;
	if trace then Trace.line x.tag y.tag;
	match head x, head y with
	  | V v, V w -> f at v w
	  | V _, N(b,l,r) -> app b false x l; app b true x r
	  | N(b,l,r), V _ -> app b false l y; app b true r y
	  | N(b,l,r), N(c,l',r') ->
	    match compare b c with
	      | 0 -> app b false l l'; app b true r r'
	      | 1 -> app c false x l'; app c true x r'
	      | _ -> app b false l y ; app b true r y
      )
    in fun x y -> if x!=y && not (Hset2.mem m x y) then app [] x y

let unify_dsf trace =
  let m = ref Hmap.empty in
  on_clean (fun () -> m := Hmap.empty);
  let link x y = m := Hmap.add x y !m in
  let get x = try Some (Hmap.find x !m) with Not_found -> None in
  let rec repr x =
    match get x with
      | None -> x
      | Some y -> match get y with
	  | None -> y
	  | Some z -> link x z; repr z
  in
  let link x y =
    link x y;
    if trace then Trace.line x.tag y.tag
  in
  let rec unify at f x y =
    let unify b c x y = unify ((b,c)::at) f x y in
    let x = repr x in
    let y = repr y in
    if x!=y then (
      Stats.incr unify_calls;
      match head x, head y with
	| V a, V b -> link x y; f at a b
	| N(b,l,r), V _ -> link x y; unify b false l y; unify b true r y
	| V _, N(b,l,r) -> link y x; unify b false x l; unify b true x r
	| N(b,l,r), N(c,l',r') ->
	  match compare b c with
	    | 0 -> link x y; unify b false l l'; unify b true r r'
	    | 1 -> link y x; unify c false x l'; unify c true x r'
	    | _ -> link x y; unify b false l y ; unify b true r y )
  in fun f x y ->
    let x = repr x in
    let y = repr y in
    if x!=y then unify [] f x y

type key = int

type formula = (bool,key) node

let m = init Hashtbl.hash (=)

let bot = constant m false
let top = constant m true
let var b = node m b bot top
let rav b = node m b top bot

let neg = unary m not
let iff = binary m (=)
let xor = binary m (<>)

(* let dsj = binary (||) *)
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

(* let cnj = binary (&&) *)
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

let rec witness n =
  match head n with
    | V _ -> []
    | N(a,{node=V false},r) -> (a,true)::witness r
    | N(a,l,_) -> (a,false)::witness l

let rec string_of_formula i x = match head x with
  | V false -> Printf.sprintf "0"
  | V true -> Printf.sprintf "1"
  | N(a,{node=V false},{node=V true}) -> Printf.sprintf "%d" a
  | N(a,{node=V true},{node=V false}) -> Printf.sprintf "!%d" a
  | N(a,{node=V true},r) -> Printf.sprintf (paren i 0 "!%d+%a") a (fun _ -> string_of_formula 0) r
  | N(a,l,{node=V true}) -> Printf.sprintf (paren i 0 "%d+%a") a (fun _ -> string_of_formula 0) l
  | N(a,{node=V false},r) -> Printf.sprintf (paren i 1 "%d%a") a (fun _ -> string_of_formula 1) r
  | N(a,l,{node=V false}) -> Printf.sprintf (paren i 1 "!%d%a") a (fun _ -> string_of_formula 1) l
  | N(a,l,r) -> Printf.sprintf (paren i 0 "%d%a+!%d%a") a (fun _ -> string_of_formula 1) r a (fun _ -> string_of_formula 1) l

let walk g =
  let t = ref Hmap.empty in
  let rec walk x =
    try Hmap.find x !t
    with Not_found -> t := Hmap.add x () !t; g walk x
  in walk

let unary m f = unary m f
let binary m f = binary m f

module Cell : Cell.Cell = struct

let m = init Hashtbl.hash (=)

let maybe_output case_cell fmt skip d cell f =
  case_cell
    (fun b ->
      let fmt = if skip then fmt else output_verdict fmt (d, b)
      in fun x -> (x, fmt))
    (fun x -> f (d, cell) fmt x) cell

type cell = formula
type future_cell = Now of cell | Later of (timestamp -> cell)

let cell_to_string = string_of_formula 0

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
