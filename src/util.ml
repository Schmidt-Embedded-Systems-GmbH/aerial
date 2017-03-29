(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

(*make the list [from, from + 1, ..., to]*)
let rec ( -- ) i j =
  if i > j then [] else i :: (i + 1 -- j)

let paren h k x = if h>k then "("^^x^^")" else x

module SS = Set.Make(String)
type timestamp = int
type trace = (SS.t * timestamp) list

type uinterval = UI of int
type binterval = BI of int * int
type interval = B of binterval | U of uinterval
let case_I f1 f2 = function
  | (B i) -> f1 i
  | (U i) -> f2 i
let map_I f1 f2 = case_I (fun i -> B (f1 i)) (fun i -> U (f2 i))

let subtract n i = if i < n then 0 else i - n

let lclosed_UI i = UI i
let lopen_UI i = UI (i + 1)
let nonempty_BI l r = if l <= r then BI (l, r) else raise (Failure "empty interval")
let lclosed_rclosed_BI i j = nonempty_BI i j
let lopen_rclosed_BI i j = nonempty_BI (i + 1) j
let lclosed_ropen_BI i j = nonempty_BI i (j - 1)
let lopen_ropen_BI i j = nonempty_BI (i + 1) (j - 1)
let left_UI (UI i) = i
(*let left_BI (BI (i, _)) = i*)
let right_BI (BI (_, j)) = j
(*val left_I = case_I left_BI left_UI*)
let right_I = case_I right_BI left_UI
let full = U (UI 0)

let subtract_UI n (UI i) = UI (subtract n i)
let subtract_BI n (BI (i, j)) = BI (subtract n i, subtract n j)
let subtract_I n = map_I (subtract_BI n) (subtract_UI n)

let mem_UI t (UI l) = l <= t
let mem_BI t (BI (l, r)) = l <= t && t <= r
let mem_I t = case_I (mem_BI t) (mem_UI t)

let print_binterval out = function
  | BI (i, j) -> Printf.fprintf out "[%d,%d]" i j

let print_interval out = function
  | U (UI i) -> Printf.fprintf out "[%d,∞)" i
  | B i -> Printf.fprintf out "%a" print_binterval i

let output_verdict fmt ((t, i), b) = Printf.fprintf fmt "%d:%d %B\n" t i b
let output_eq fmt ((t, i), (t', j)) = Printf.fprintf fmt "%d:%d = %d:%d\n" t i t' j
