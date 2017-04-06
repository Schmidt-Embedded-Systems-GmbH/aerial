(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

val ( -- ): int -> int -> int list
val paren: int -> int -> ('b, 'c, 'd, 'e, 'f, 'g) format6 -> ('b, 'c, 'd, 'e, 'f, 'g) format6

module SS: Set.S with type elt = string
type timestamp = int
type trace = (SS.t * timestamp) list

val s_id: string -> int
val i_id: int -> int
val max_id: int ref
val pairs: int list -> int

type binterval
type uinterval
type interval = B of binterval | U of uinterval

val lclosed_UI: int -> uinterval
val lclosed_rclosed_BI: int -> int -> binterval
val lclosed_ropen_BI: int -> int -> binterval
val lopen_UI: int -> uinterval
val lopen_rclosed_BI: int -> int -> binterval
val lopen_ropen_BI: int -> int -> binterval
val mem_BI: int -> binterval -> bool
val mem_I: int -> interval -> bool
val right_BI: binterval -> int
val right_I: interval -> int
val full: interval
val subtract_BI: int -> binterval -> binterval
val subtract_I: int -> interval -> interval
val hash_I: interval -> int
val case_I: (binterval -> 'a) -> (uinterval -> 'a) -> interval -> 'a
val print_interval: out_channel -> interval -> unit

val output_verdict: out_channel -> (timestamp * int) * bool -> unit
val output_eq: out_channel -> (timestamp * int) * (timestamp * int) -> unit

type mode = NAIVE | COMPRESS_LOCAL | COMPRESS_GLOBAL