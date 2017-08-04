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
open Channel


module type Formula = sig
  type f
  type memory
  module C : Cell
  val print_formula: output_channel -> f -> output_channel
  val init: f -> f * f array * memory
  val bounded_future: f -> bool
  val idx_of: f -> int
  val mk_cell: (int -> C.cell) -> f -> C.cell
  val mk_fcell: (int -> C.future_cell) -> f -> C.future_cell
  val progress: f array * memory  -> int * SS.t -> C.future_cell array -> C.future_cell array
end

module type Monitor = sig
  type formula
  type ctxt
  type monitor = {init: ctxt; step: SS.t * timestamp -> ctxt -> ctxt}
  val create: output_channel -> mode -> formula -> monitor
end

module Make(F : Formula) : Monitor with type formula = F.f = struct

type formula = F.f
module C = F.C
type ctxt =
  {history: ((timestamp * int) * C.cell) list; (*reversed*)
   now: timestamp * int;
   arr: C.future_cell array;
   skip: bool;
   output: output_channel}
type monitor =
  {init: ctxt;
   step: SS.t * timestamp -> ctxt -> ctxt}

let create outch mode_hint formula =
    let outch = output_event outch "Monitoring "  in
    let outch = F.print_formula outch formula in
    let outch = output_event outch "\n" in
  let (formula, f_vec, m) = F.init formula in
  
  let mode = if F.bounded_future formula then mode_hint else  
    COMPRESS_GLOBAL in
  let outch = if F.bounded_future formula then outch else output_event outch 
    "The formula contains unbounded future operators and
    will therefore be monitored in global mode.\n%!" in
  let n = Array.length f_vec in

  let init = {history = []; now = (-1, 0); arr = Array.make n (C.fcbool false); skip = true; output=outch} in

  let rec check_dup res entry h = match entry, h with
    | (_, []) -> (entry :: List.rev res, outch)
    | (((t, i), c), (((t', j), d) as entry') :: history) ->
        if mode = COMPRESS_GLOBAL || t = t'
        then
          if C.equiv c d
          then let outch = output_eq outch ((t, i), (t', j)) in (List.rev res @ entry' :: history, outch)
          else check_dup (entry' :: res) entry history
        else (entry :: List.rev res @ entry' :: history, outch) in
  
  let add = if mode = NAIVE then fun x y -> (List.cons x y, outch) else check_dup [] in

  let mk_top_fcell a = F.mk_fcell (fun i -> a.(i)) formula in

(* fun a b -> (List.cons a b, outch) *)

  let step (ev, t') ctxt =
    (* let _ = Printf.printf "Processing %a @ %d\n" (fun _ -> SS.iter print_string) ev t' in *)
    let (t, i) as d = ctxt.now in
    let outch = ctxt.output in 
    let fa = ctxt.arr in
    let skip = ctxt.skip in
    let delta = t' - t in
    let eval = C.eval_future_cell delta in
    (* let _ = Array.iteri (fun i fc -> Printf.printf "%d-%d %a: %a\n%!" i (F.idx_of f_vec.(i)) F.print_formula f_vec.(i) C.print_cell (eval fc)) fa in *)
    let old_history = ctxt.history in
    let clean_history = List.fold_left (fun history (d, cell) ->
      let (res,outch) = C.maybe_output_cell outch false d (eval (C.subst_cell_future fa cell)) add history in res) [] old_history in
    let history = let (res,outch) = C.maybe_output_cell outch skip d (eval (mk_top_fcell fa)) add clean_history in res in
    let d' = (t', if t = t' then i + 1 else 0) in
    let fa' = F.progress (f_vec, m) (delta, ev) fa in
    let history' = List.fold_left (fun history ((d, cell) as x) ->
      let (res,outch) = C.maybe_output_future outch d (C.subst_cell_future fa' cell) (fun b -> (List.cons x b,outch)) history in res) [] history in
    let (skip',outch) = C.maybe_output_future outch d' (mk_top_fcell fa') (fun _ -> (false,outch)) true in
    {history = history'; now = d'; arr = fa'; skip = skip'; output = outch} in

  {init=init; step=step}

  end
