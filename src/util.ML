(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2016:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

infix upto

signature UTIL =
sig

val I: 'a -> 'a
val K: 'a -> 'b -> 'a
val map_prod: ('a -> 'b) -> ('c -> 'd) -> 'a * 'c -> 'b * 'd
val apfst: ('a -> 'b) -> 'a * 'c -> 'b * 'c
val apsnd: ('b -> 'c) -> 'a * 'b -> 'a * 'c
val upto: int * int -> int list
val cons: 'a -> 'a list -> 'a list
val fold: ('a -> 'b -> 'b) -> 'a list -> 'b -> 'b
val fold_rev: ('a -> 'b -> 'b) -> 'a list -> 'b -> 'b
val maps: ('a -> 'b list) -> 'a list -> 'b list
val member: ('a * 'b -> bool) -> 'b list -> 'a -> bool
val distinct: ('a * 'a -> bool) -> 'a list -> 'a list
val space_explode: string -> string -> string list

end;

structure Util : UTIL =
struct

fun I x = x;
fun K x _ = x;
fun map_prod f g (x, y) = (f x, g y);
fun apfst f = map_prod f I;
fun apsnd f = map_prod I f;

(*make the list [from, from + 1, ..., to]*)
fun ((i: int) upto j) =
  if i > j then [] else i :: (i + 1 upto j);

fun cons x xs = x :: xs;

fun fold _ [] y = y
  | fold f (x :: xs) y = fold f xs (f x y);

fun fold_rev _ [] y = y
  | fold_rev f (x :: xs) y = f x (fold_rev f xs y);

fun maps _ [] = []
  | maps f (x :: xs) = f x @ maps f xs;

fun member eq list x =
  let
    fun memb [] = false
      | memb (y :: ys) = eq (x, y) orelse memb ys;
  in memb list end;

(*makes a list of the distinct members of the input; preserves order, takes
  first of equal elements*)
fun distinct eq lst =
  let
    fun dist (rev_seen, []) = rev rev_seen
      | dist (rev_seen, x :: xs) =
          if member eq rev_seen x then dist (rev_seen, xs)
          else dist (x :: rev_seen, xs);
  in dist ([], lst) end;

fun space_explode _ "" = []
  | space_explode sep s = String.fields (fn c => str c = sep) s;

end;