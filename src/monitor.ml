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
  val fly: monitor -> input_channel -> output_channel
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


let fly mon log =
  let rec loop f x = loop f (f x) in
  let s (ctxt,ch) =
    let (line,ch) = input_event ch ctxt.output in
    (mon.step line ctxt,ch) in
  loop s (mon.init,log)

let create outch mode_hint formula =
    let outch = output_event outch "Monitoring "  in
    let outch = F.print_formula outch formula in
    let outch = output_event outch
      (" in mode \"" ^ (match mode_hint with NAIVE -> "naive" | COMPRESS_LOCAL -> "local" | COMPRESS_GLOBAL -> "global") ^ "\"") in
      let outch = output_event outch "\n" in
  let (formula, f_vec, m) = F.init formula in

  let mode = if F.bounded_future formula then mode_hint else
    COMPRESS_GLOBAL in
  let outch = if F.bounded_future formula then outch else output_event outch
    "The formula contains unbounded future operators and will therefore be monitored in global mode.\n" in
  let n = Array.length f_vec in

  let init = {history = []; now = (-1, 0); arr = Array.make n (C.fcbool false); skip = true; output=outch} in

  let rec check_dup res entry out h = match entry, h with
    | (_, []) -> (entry :: List.rev res, out)
    | (((t, i), c), (((t', j), d) as entry') :: history) ->
        if mode = COMPRESS_GLOBAL || t = t'
        then
          if C.equiv c d
          then let out1 = output_eq out ((t, i), (t', j)) in (List.rev res @ entry' :: history, out1)
          else check_dup (entry' :: res) entry out history
        else (entry :: List.rev res @ entry' :: history, out) in

  let add = if mode != NAIVE then check_dup [] else fun x c y  -> (List.cons x y, c) in

  let mk_top_fcell a = F.mk_fcell (fun i -> a.(i)) formula in

  let print_event _ ev =
    let tail s = if s = "" then "" else String.sub s 1 (String.length s - 1) in
    "{" ^ tail (tail (SS.fold (fun s t -> t ^ ", " ^ s) ev "")) ^ "}" in

  let formula_to_string _ f = channel_to_string (OC (F.print_formula (OutputMock []) f)) in
  let cell_to_string _ f = channel_to_string (OC (C.print_cell (OutputMock []) f)) in

  let step (ev, t') ctxt =
    let (t, i) as d = ctxt.now in
    let outch = ctxt.output in
    let fa = ctxt.arr in
    let skip = ctxt.skip in
    let delta = t' - t in
    let eval = C.eval_future_cell delta in

    let outch = output_debug 0 outch (fun _ ->
      Printf.sprintf "processing %a @ %d\n" print_event ev t') in
    let outch = output_debug 10 outch (fun _ -> "prev array:\n") in
    let outch =
      fst (Array.fold_left (fun (outch, i) fc ->
        (output_debug 10 outch (fun _ -> Printf.sprintf "%d) %a: %a\n" (F.idx_of f_vec.(i))
          formula_to_string f_vec.(i) cell_to_string (eval fc)), i + 1))
      (outch, 0) fa) in

    let old_history = ctxt.history in
    let (history, outch) = List.fold_left (fun (history, outch') (d, cell) ->
      C.maybe_output_cell outch' false d (eval (C.subst_cell_future fa cell)) add history)
      ([], outch) old_history in
    let (history, outch) = C.maybe_output_cell outch skip d (eval (mk_top_fcell fa)) add history in
    let d' = (t', if t = t' then i + 1 else 0) in
    let fa' = F.progress (f_vec, m) (delta, ev) fa in
    let (history, outch) = List.fold_left (fun (history, outch) ((d, cell) as x) ->
      C.maybe_output_future outch d (C.subst_cell_future fa' cell)
        (fun ch h -> (List.cons x h, ch)) history) ([], outch) history in
    let (skip, outch) =
      C.maybe_output_future outch d' (mk_top_fcell fa') (fun c _ -> (false, c)) true in
    let outch = output_debug 1 outch (fun _ ->
      Printf.sprintf "events in history: %d\n" (List.length history)) in

    let outch = output_debug 20 outch (fun _ -> "history:\n") in
    let outch = if history = [] then outch else
      List.fold_left (fun outch ((t, i), c) ->
        output_debug 20 outch (fun _ -> Printf.sprintf "%d:%d %a\n" t i cell_to_string c))
      outch history in

    {history = history; now = d'; arr = fa'; skip = skip; output = outch} in

  {init=init; step=step}

  end
