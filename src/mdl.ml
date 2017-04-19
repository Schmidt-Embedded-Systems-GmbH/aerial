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
open Monitor

type formula =
| P of int * string
| Conj of formula * formula
| Disj of formula * formula
| Neg of formula
| PossiblyF of int * interval * regex * formula
| PossiblyP of int * interval * formula * regex
| Bool of bool
and regex =
| Wild
| Test of formula
| Alt of regex * regex
| Seq of regex * regex
| Star of regex

let rec print_formula l out = function
  | P (_, x) -> Printf.fprintf out "%s" x
  | Bool b -> Printf.fprintf out (if b then "⊤" else "⊥")
  | Conj (f, g) -> Printf.fprintf out (paren l 2 "%a ∧ %a") (print_formula 2) f (print_formula 2) g
  | Disj (f, g) -> Printf.fprintf out (paren l 1 "%a ∨ %a") (print_formula 1) f (print_formula 2) g
  | Neg f -> Printf.fprintf out "¬%a" (print_formula 3) f
  | PossiblyF (_, i, r, f) -> Printf.fprintf out (paren l 0 "<%a> %a %a") (print_regex 0) r print_interval i (print_formula 4) f
  | PossiblyP (_, i, f, r) -> Printf.fprintf out (paren l 0 "%a %a <%a>") (print_formula 4) f print_interval i (print_regex 0) r
and print_regex l out = function
  | Seq (Test f, Wild) -> Printf.fprintf out "%a" (print_formula 0) f
  | Wild -> Printf.fprintf out "."
  | Test f -> Printf.fprintf out "%a?" (print_formula 3) f
  | Alt (r, s) -> Printf.fprintf out (paren l 1 "%a + %a") (print_regex 1) r (print_regex 1) s
  | Seq (r, s) -> Printf.fprintf out (paren l 2 "%a%a") (print_regex 2) r (print_regex 2) s
  | Star (r) -> Printf.fprintf out "%a*" (print_regex 3) r
let print_formula = print_formula 0

let rec maxidx_of = function
  | P (i, x) -> i
  | Conj (f, g) | Disj (f, g) -> max (maxidx_of f) (maxidx_of g)
  | Neg f -> maxidx_of f
  | PossiblyF (j, _, _, _) | PossiblyP (j, _, _, _) -> j
  | Bool _ -> -1

let rec lift n = function
  | P (i, x) -> P (i + n, x)
  | Conj (f, g) -> Conj (lift n f, lift n g)
  | Disj (f, g) -> Disj (lift n f, lift n g)
  | Neg f -> Neg (lift n f)
  | PossiblyF (j, i, r, f) -> PossiblyF (j + n, i, lift_re n r, lift n f)
  | PossiblyP (j, i, f, r) -> PossiblyP (j + n, i, lift n f, lift_re n r)
  | Bool b -> Bool b
and lift_re n = function
  | Wild -> Wild
  | Test f -> Test (lift n f)
  | Alt (r, s) -> Alt (lift_re n r, lift_re n s)
  | Seq (r, s) -> Seq (lift_re n r, lift_re n s)
  | Star r -> Star (lift_re n r)

let p x = P (0, x)
let bool b = Bool b
let conj f g =
  match f, g with
  | Bool true, g | g, Bool true -> g
  | Bool false, _ | _, Bool false -> bool false
  | _ -> Conj (f, lift (maxidx_of f + 1) g)
let disj f g = 
  match f, g with
  | Bool false, g | g, Bool false -> g
  | Bool true, _ | _, Bool true -> bool true
  | _ -> Disj (f, lift (maxidx_of f + 1) g)
let rec neg = function
  | Disj (f, g) -> conj (neg f) (neg g)
  | Conj (f, g) -> disj (neg f) (neg g)
  | Neg f -> f
  | f -> Neg f
let wild = Wild
let test f = Test f
let empty = test (bool false)
let epsilon = test (bool true)
let alt f g = Alt (f, g)
let seq f g = 
  match f, g with
  | Test (Bool true), g | g, Test (Bool true) -> g
  | Test (Bool false), _ | _, Test (Bool false) -> Test (Bool false)
  | _ -> Seq (f, g)
let rec star = function
  | Star f -> star f
  | f -> Star f
let base f = seq (test f) wild

module RES = Set.Make(struct type t = regex let compare = compare end)

let rec split = function
  | Alt (r, s) -> RES.union (split r) (split s)
  | r -> RES.singleton r

let rec nullable_overapprox = function
  | Wild -> false
  | Test f -> true
  | Alt (r, s) -> nullable_overapprox r || nullable_overapprox s
  | Seq (r, s) -> nullable_overapprox r && nullable_overapprox s
  | Star r -> true

let seqs l s = RES.map (fun r -> seq r s) l

let rec der_overapprox = function
  | Wild -> RES.singleton epsilon
  | Test f -> RES.empty
  | Alt (r, s) -> RES.union (der_overapprox r) (der_overapprox s)
  | Seq (r, s) -> RES.union (seqs (der_overapprox r) s) (if nullable_overapprox r then der_overapprox s else RES.empty)
  | Star r -> seqs (der_overapprox r) (star r)

let ders_overapprox r =
  let s0 = RES.singleton r in
  let init = (s0, s0) in
  let step s d =
    let d' = RES.fold (fun r x -> RES.union x (RES.diff (der_overapprox r) s)) d RES.empty in
    (RES.union s d', d') in
  let rec go (s, d) =
    ((*RES.iter (Printf.printf "%a\n%!" (print_regex 0)) d;*) if RES.is_empty d then s else go (step s d)) in
  go init

(*
let _ = ders_overapprox (star (seq ( (base (p "x"))) ( (base (p "y")))))
let _ = Printf.printf "----------------------\n%!"
let _ = ders_overapprox (star (star (star (seq (base (p "x")) (base (p "y"))))))
*)

let imp f g = disj (neg f) g
let iff f g = conj (imp f g) (imp g f)
let possiblyF r i f = RES.fold (fun r -> fun x -> disj (PossiblyF (0, i, r, f)) x) (split r) (bool false) (*FIXME lift*)
let possiblyP f i r = RES.fold (fun r -> fun x -> disj (PossiblyP (0, i, f, r)) x) (split r) (bool false) (*FIXME lift*)
let necessarilyF r i f = neg (possiblyF r i (neg f))
let necessarilyP f i r = neg (possiblyP (neg f) i r)
let next i f = possiblyF (base (bool true)) i f
let prev i f = possiblyP f i (base (bool true))
let until i f g = possiblyF (star (base f)) i g
let since i f g = possiblyP g i (star (base f))
let release i f g = neg (until i (neg f) (neg g))
let weak_until i f g = release i g (disj f g)
let trigger i f g = neg (since i (neg f) (neg g))
let eventually i f = until i (bool true) f
let always i f = neg (eventually i (neg f))
let once i f = since i (bool true) f
let historically i f = neg (once i (neg f))


module MDL : Formula with type f = formula = struct

type f = formula
type t = formula array

let rec bounded_future = function
  | Bool _ -> true
  | P _ -> true
  | PossiblyP (_, _, f, r) -> bounded_future f && bounded_future_re r
  | Conj (f, g) | Disj (f, g) -> bounded_future f && bounded_future g
  | PossiblyF (_, i, r, f) ->
      case_I (fun _ -> true) (fun _ -> false) i && bounded_future_re r && bounded_future f
  | Neg f -> bounded_future f
and bounded_future_re = function
  | Wild -> true
  | Test f -> bounded_future f
  | Alt (r, s) | Seq (r, s) -> bounded_future_re r && bounded_future_re s
  | Star r -> bounded_future_re r

let print_formula = print_formula

let mk_idx_of arr = arr

let idx_of arr f = snd (Array.fold_left (fun (b, i) g -> if b then (b, i) else if f = g then (true, i) else (false, i+1)) (false, 0) arr) (*function
  | P (j, _) | PossiblyF (j, _, _, _) | PossiblyP (j, _, _, _) -> j
  | _ -> failwith "not an indexed subformula"*)

let mk cnj dsj neg bo idx_of idx =
  let rec go = function
    | Conj (f, g) -> cnj (go f) (go g)
    | Disj (f, g) -> dsj (go f) (go g)
    | Neg f -> neg (go f)
    | Bool b -> bo b
    | f -> idx (idx_of f) in
  go
let mk_cell = mk cconj cdisj cneg (fun b -> B b)
let mk_fcell = mk fcconj fcdisj fcneg (fun b -> Now (B b))

let conj_lifted f g = Conj (f, g)
let disj_lifted f g = Disj (f, g)
(*let since_lifted i f g = Since (maxidx_of g + right_I i + 1, i, f, g)
let until_lifted i f g = Until (maxidx_of g + right_I i + 1, i, f, g)
*)

let rec sub = function 
  | Neg f -> sub f
  | Conj (f, g) -> sub g @ sub f
  | Disj (f, g) -> sub g @ sub f
  | PossiblyF (j, i, r, f) -> PossiblyF (j, i, r, f) :: sub_re r @ sub f
  | PossiblyP (j, i, f, r) -> PossiblyP (j, i, f, r) :: sub f @ sub_re r
  | P _ as f -> [f]
  | _ -> []
and sub_re = function
  | Wild -> []
  | Test f -> sub f
  | Alt (r, s) | Seq (r, s) -> sub_re r @ sub_re s
  | Star r -> sub_re r

let rec rev_re = function
  | Wild -> Wild
  | Test f -> Test f
  | Alt (r, s) -> Alt (rev_re r, rev_re s)
  | Seq (r, s) -> Seq (rev_re s, rev_re r)
  | Star r -> Star (rev_re r)

let ders_overapprox x = RES.elements (ders_overapprox x)
let rev_ders_overapprox x = List.map rev_re (ders_overapprox (rev_re x))

let aux = function
  | PossiblyF (_,i,r,f) -> List.flatten (List.map (fun n ->
      List.map (fun s -> possiblyF s (subtract_I n i) f) (ders_overapprox r)) (0 -- right_I i))
  | PossiblyP (_,i,f,r) -> List.flatten (List.map (fun n ->
      List.map (fun s -> possiblyP f (subtract_I n i) s) (rev_ders_overapprox r)) (0 -- right_I i))
  | f -> [f]

let ssub f = List.rev (List.concat (List.map (fun x -> aux x) (sub f)))

let nullable curr cnj dsj tt ff =
  let rec go = function
  | Wild -> ff
  | Test f -> curr f
  | Alt (r, s) -> dsj (go r) (go s)
  | Seq (r, s) -> cnj (go r) (go s)
  | Star r -> tt
  in go
let fnullable curr = nullable curr fcconj fcdisj (Now (B true)) (Now (B false))
let nullable curr = nullable curr cconj cdisj (B true) (B false)

let derF curr finish =
  let rec go fin = function
  | Wild -> fin epsilon
  | Test f -> B false
  | Alt (r, s) -> cdisj (go fin r) (go fin s)
  | Seq (r, s) -> let r' = go (fun t -> fin (seq t s)) r in cif (nullable curr r) (cdisj r' (go fin s)) r'
  | Star r -> go (fun t -> fin (seq t (star r))) r
  in go finish

let derP curr finish =
  let rec go fin = function
  | Wild -> fin epsilon
  | Test f -> Now (B false)
  | Alt (r, s) -> fcdisj (go fin r) (go fin s)
  | Seq (r, s) -> let s' = go (fun t -> fin (seq r t)) s in fcif (fnullable curr r) (fcdisj (go fin r) s') s'
  | Star r -> go (fun t -> fin (seq (star r) t)) r
  in go finish

let progress f_vec idx_of a t_prev ev t =
  let n = Array.length f_vec in
  let b = Array.make n (Now (B false)) in
  let curr = mk_fcell idx_of (fun i -> b.(i)) in
  let prev = mk_cell idx_of (fun i -> a.(i)) in
  let prev f = subst_cell_future b (prev f) in
  let next = mk_cell idx_of (fun i -> V (true, i)) in
  for i = 0 to n - 1 do
    b.(i) <- match f_vec.(i) with
    | P (_, x) -> Now (B (SS.mem x ev))
    | PossiblyF (_, i, r, f) -> fcdisj
        (if mem_I 0 i then fcconj (fnullable curr r) (curr f) else Now (B false))
        (Later (fun t_next -> if case_I (fun i -> t_next - t > right_BI i) (fun _ -> false) i
          then B false
          else derF (fun f -> eval_future_cell t_next (curr f)) (fun s -> next (possiblyF s (subtract_I (t_next - t) i) f)) r))
    | PossiblyP (_, i, f, r) -> fcdisj
        (if mem_I 0 i then fcconj (fnullable curr r) (curr f) else Now (B false))
        (if case_I (fun i -> t - t_prev > right_BI i) (fun _ -> false) i
          then Now (B false)
          else derP curr (fun s -> prev (possiblyP f (subtract_I (t - t_prev) i) s)) r)
    
    | _ -> failwith "not a temporal formula"
  done;
  b

end

module Monitor_MDL = Monitor.Make(MDL)