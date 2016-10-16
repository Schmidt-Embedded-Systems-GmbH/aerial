(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2016:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

signature ATOM =
sig
  eqtype atom

end

signature MONITOR =
sig
  eqtype atom
  type ctxt
  type monitor =
    {init: ctxt, step: atom list * MTL.timestamp -> ctxt -> ctxt}
  val create: atom MTL.formula -> MTL.mode -> (string -> unit) -> monitor
  val traverse: monitor -> atom MTL.trace -> ctxt
end

functor Monitor(A: ATOM) : MONITOR =
struct

open Util
open Cell
open MTL

fun lookup v i = Vector.sub (v, i);
fun update v i x = Vector.update (v, i, x);
fun index v f =
  (case Vector.findi (fn (_, g) => g = f) v of
    SOME (i, _) => i
  | NONE => raise Fail "not found");

datatype future_cell = Now of cell | Later of timestamp -> cell

fun eval_future_cell _ (Now c) = c
  | eval_future_cell t (Later f) = f t;

fun fcconj (Now c) (Now d) = Now (cconj c d)
  | fcconj (fc as Now c) (fd as Later f) =
    if is_CBool c
    then if dest_CBool c then fd else fc
    else Later (fn t => cconj c (f t))
  | fcconj (fc as Later f) (fd as Now d) =
    if is_CBool d
    then if dest_CBool d then fc else fd
    else Later (fn t => cconj (f t) d)
  | fcconj (Later f) (Later g) = Later (fn t => cconj (f t) (g t));

fun fcdisj (Now c) (Now d) = Now (cdisj c d)
  | fcdisj (fc as Now c) (fd as Later f) =
    if is_CBool c
    then if dest_CBool c then fc else fd
    else Later (fn t => cdisj c (f t))
  | fcdisj (fc as Later f) (fd as Now d) =
    if is_CBool d
    then if dest_CBool d then fd else fc
    else Later (fn t => cdisj (f t) d)
  | fcdisj (Later f) (Later g) = Later (fn t => cdisj (f t) (g t));

fun fcneg (Now c) = Now (cneg c)
  | fcneg (Later f) = Later (fn t => cneg (f t));

fun to_future_cell f = fold_cell (fn b => Now (CBool b)) f fcconj fcdisj fcneg;

val dummy_future_cell = Later (fn _ => raise Fail "uninitilized cell");

type atom = A.atom;
type ctxt =
  {history : ((timestamp * int) * cell) list, (*reversed*)
   next : ((timestamp * int) * future_cell vector) * bool}
type monitor =
  {init: ctxt,
   step: atom list * MTL.timestamp -> ctxt -> ctxt}

fun create F mode output =
  let
    val F_vec = Vector.fromList (ssub F);
    val from_int = lookup F_vec;
    val to_int = index F_vec;
    val n = Vector.length F_vec;
    val next = CPoint o to_int;

    fun fill_next curr ev t =
      let
        val (t_prev, offset, v_prev) =
          (case curr of ((t_prev, offset), v) => (t_prev, if t_prev = t then offset + 1 else 0, v));
        fun fill_cell i v =
          let
            val future_cell =
              let
                fun curr f = lookup v (to_int f);
                fun prev f = to_future_cell (lookup v) (lookup v_prev (to_int f));
              in
                (case from_int i of
                  P x => Now (CBool (member (op =) ev x))
                | Bool b => Now (CBool b)
                | Conj (f, g) => fcconj (curr f) (curr g)
                | Disj (f, g) => fcdisj (curr f) (curr g)
                | Neg f => fcneg (curr f)
                | Prev (i, f) =>
                    if mem_I (t - t_prev) i then prev f else Now (CBool false)
                | Next (i, f) =>
                    Later (fn t_next => if mem_I (t_next - t) i then next f else CBool false)
                | Since (i, f, g) => fcdisj
                    (if mem_I 0 i then curr g else Now (CBool false))
                    (if case_I (fn i => t - t_prev > right_BI i) (K false) i
                     then Now (CBool false)
                     else fcconj (curr f) (prev (Since (subtract_I (t - t_prev) i, f, g))))
                | Until (i, f, g) => fcdisj
                    (if mem_BI 0 i then curr g else Now (CBool false))
                    (Later (fn t_next => if t_next - t > right_BI i
                     then CBool false
                     else cconj (eval_future_cell t_next (curr f))
                       (next (Until (subtract_BI (t_next - t) i, f, g))))))
              end;
          in
            update v i future_cell
          end;
      in
        ((t, offset), fold fill_cell (0 upto n - 1)
          (Vector.tabulate (n, fn _ => dummy_future_cell)))
      end;

    val init =
      {history = [], next = (((~1, 0), Vector.tabulate (n, K (Now (CBool false)))), true)} : ctxt;

    fun output_verdict ((t, i), b) = output
      (Int.toString t ^ ":" ^ Int.toString i ^ (if b then " TT\n" else " FF\n"));

    fun output_eq ((t, i), (t', j)) = output
      (Int.toString t ^ ":" ^ Int.toString i ^ " = " ^ Int.toString t' ^ ":" ^ Int.toString j ^ "\n");

    fun maybe_output skip (d : timestamp * int) cell f =
      if is_CBool cell
      then ((if skip then K () else output_verdict) (d, dest_CBool cell); I)
      else f (d, cell);

    fun check_dup done entry [] = entry :: rev done
      | check_dup done (entry as ((t, i), c)) ((entry' as ((t', j), d)) :: history) =
        if mode = COMPRESS_GLOBAL orelse t = t'
        then
          if cell_equiv c d
          then (output_eq ((t, i), (t', j)); rev done @ entry' :: history)
          else check_dup (entry' :: done) entry history
        else entry :: rev done @ entry' :: history;

    val insert = if mode = NAIVE then cons else check_dup [];

    fun step (ev, t) (ctxt : ctxt) =
      let
        val ((d, old_curr), skip) = #next ctxt;
        val curr = Vector.map (eval_future_cell t) old_curr;
        val old_history = #history ctxt;
        val clean_history = fold_rev (fn (d, old_cell) => fn history =>
          let
            val cell = map_cell (lookup curr) old_cell;
          in
            maybe_output false d cell insert history
          end) old_history [];
        val history = maybe_output skip d (lookup curr (n - 1)) insert clean_history;
        val next as (next_d, v) = fill_next (d, curr) ev t;
        val history_next = fold_rev (fn (d, cell) => fn history =>
          let
            val fcell = to_future_cell (lookup v) cell;
          in
            (case fcell of
              Now c => if is_CBool c then (output_verdict (d, dest_CBool c); history)
                else (d, cell) :: history
            | _ => (d, cell) :: history)
          end) history [];
        val skip =
          (case lookup v (n - 1) of
            Now c => if is_CBool c then (output_verdict (next_d, dest_CBool c); true) else false
          | Later _ => false);
      in
        {history = history_next, next = (next, skip)} : ctxt
      end;
  in
    {init = init, step = step} : monitor
  end;

fun traverse m tr = fold (#step m) tr (#init m);

end;
