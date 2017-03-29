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
open Mtl

type mode = NAIVE | COMPRESS_LOCAL | COMPRESS_GLOBAL

type ctxt =
  {history: ((timestamp * int) * cell) list; (*reversed*)
   now: timestamp * int;
   arr: future_cell array;
   skip: bool}
type monitor =
  {init: ctxt;
   step: SS.t * timestamp -> ctxt -> ctxt}

let create fmt mode_hint formula =
  let _ = Printf.fprintf fmt "Monitoring %a\n%!" print_formula formula in
  let f_vec = Array.of_list (ssub formula) in
  let mode = if bounded_future formula then mode_hint else
    (Printf.fprintf fmt
    "The formula contains unbounded future operators and
will therefore be monitored in global mode.\n%!"; COMPRESS_GLOBAL) in
  let n = Array.length f_vec in

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

  let mk_top_cell a = mk_cell (fun i -> a.(i)) formula in
  let mk_top_fcell a = mk_fcell (fun i -> a.(i)) formula in

  let step (ev, t') ctxt =
    let (t, i) as d = ctxt.now in
    let fa = ctxt.arr in
    let skip = ctxt.skip in
    let a = Array.map (eval_future_cell t') fa in
    let old_history = ctxt.history in
    let clean_history = List.fold_left (fun history (d, cell) ->
      maybe_output_cell fmt false d (subst_cell a cell) add history) [] old_history in
    let history = maybe_output_cell fmt skip d (mk_top_cell a) add clean_history in
    let d' = (t', if t = t' then i + 1 else 0) in
    let fa' = progress f_vec a t ev t' in
    let history' = List.fold_left (fun history ((d, cell) as x) ->
      maybe_output_future fmt d (subst_cell_future fa' cell) (List.cons x) history) [] history in
    let skip' = maybe_output_future fmt d' (mk_top_fcell fa') (fun _ -> false) true in
    {history = history'; now = d'; arr = fa'; skip = skip'} in

  {init=init; step=step}
