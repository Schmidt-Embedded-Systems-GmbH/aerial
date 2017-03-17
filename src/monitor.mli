(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

open Util
open Mtl

type mode = NAIVE | COMPRESS_LOCAL | COMPRESS_GLOBAL

type ctxt
type monitor = {init: ctxt; step: SS.t * timestamp -> ctxt -> ctxt}

val create: out_channel -> mode -> formula -> monitor