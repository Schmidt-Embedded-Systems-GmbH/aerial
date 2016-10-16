(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2016:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

signature CELL =
sig
  type cell
  val fold_cell: (bool -> 'a) -> (int -> 'a) ->
    ('a -> 'a -> 'a) -> ('a -> 'a -> 'a) -> ('a -> 'a) -> cell -> 'a
  val map_cell: (int -> cell) -> cell -> cell
  val CBool: bool -> cell
  val is_CBool: cell -> bool
  val dest_CBool: cell -> bool
  val CPoint: int -> cell
  val cconj: cell -> cell -> cell
  val cdisj: cell -> cell -> cell
  val cneg: cell -> cell
  val cell_equiv : cell -> cell -> bool
end

structure Cell : CELL =
struct

datatype ('a, 'b) mapping = Mapping of ('a -> 'b option);

datatype bdd = TT | FF | Node of int * bdd * bdd;

datatype cell =
  CBool of bool
| CPoint of int
| CConj of cell * cell
| CDisj of cell * cell
| CNeg of cell

fun is_CBool (CBool _) = true
  | is_CBool _ = false;

fun dest_CBool (CBool b) = b
  | dest_CBool _ = raise Fail "dest_CBool";

fun cconj (CBool true) c = c
  | cconj c (CBool true) = c
  | cconj (CBool false) _ = CBool false
  | cconj _ (CBool false) = CBool false
  | cconj c d = CConj (c, d);

fun cdisj (CBool false) c = c
  | cdisj c (CBool false) = c
  | cdisj (CBool true) _ = CBool true
  | cdisj _ (CBool true) = CBool true
  | cdisj c d = CDisj (c, d);

fun cneg (CBool b) = CBool (not b)
  | cneg (CConj (c, d)) = CDisj (cneg c, cneg d)
  | cneg (CDisj (c, d)) = CConj (cneg c, cneg d)
  | cneg c = CNeg c;

fun fold_cell bool point conj disj neg =
  let
     fun go (CConj (c, d)) = conj (go c) (go d)
       | go (CDisj (c, d)) = disj (go c) (go d)
       | go (CNeg c) = neg (go c)
       | go (CPoint i) = point i
       | go (CBool b) = bool b;
  in
    go
  end;

fun map_cell f = fold_cell CBool f cconj cdisj cneg;

fun fun_upd f a b x = (if x = a then b else f x);

val empty : ('a, 'b) mapping = Mapping (fn _ => NONE);

fun lookup (Mapping y) = y;

fun update xb xa (Mapping x) = Mapping (fun_upd x xb (SOME xa));

fun mkNode x t1 t2 = (if t1 = t2 then t1 else Node (x, t1, t2));

fun reduce env (Node (x, t1, t2)) =
  (case lookup env x
    of NONE =>  mkNode x (reduce (update x true env) t1) (reduce (update x false env) t2)
    | SOME b => reduce env (if b then t1 else t2))
  | reduce _ TT = TT
  | reduce _ FF = FF;

fun norm env TT t1 _ = reduce env t1
  | norm env FF _ t2 = reduce env t2
  | norm env (Node (x, t1, t2)) t3 t4 =
    (case lookup env x
      of NONE =>
        mkNode x (norm (update x true env) t1 t3 t4)
          (norm (update x false env) t2 t3 t4)
      | SOME true => norm env t1 t3 t4
      | SOME false => norm env t2 t3 t4);

fun bdd_of (CBool b) = (if b then TT else FF)
  | bdd_of (CPoint x) = Node (x, TT, FF)
  | bdd_of (CNeg b) = norm empty (bdd_of b) FF TT
  | bdd_of (CConj (b1, b2)) = norm empty (bdd_of b1) (bdd_of b2) FF
  | bdd_of (CDisj (b1, b2)) = norm empty (bdd_of b1) TT (bdd_of b2);

fun cell_equiv b1 b2 =
  let
    val t1 = bdd_of b1;
    val t2 = bdd_of b2;
  in
    TT = (norm empty t1 t2 (norm empty t2 FF TT))
  end;

end;