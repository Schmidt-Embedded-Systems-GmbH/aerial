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
| PossiblyF of int * int * interval * regex * formula
| PossiblyP of int * int * interval * formula * regex
| Bool of bool
and regex =
| Wild
| Test of formula
| Alt of regex * regex
| Seq of regex * regex
| Star of regex

let rec formula_to_string l = function
  | P (_, x) -> Printf.sprintf "%s" x
  | Bool b -> Printf.sprintf (if b then "⊤" else "⊥")
  | Conj (f, g) -> Printf.sprintf (paren l 2 "%a ∧ %a") (fun x -> formula_to_string 2) f (fun x -> formula_to_string 2) g
  | Disj (f, g) -> Printf.sprintf (paren l 1 "%a ∨ %a") (fun x -> formula_to_string 1) f (fun x -> formula_to_string 2) g
  | Neg f -> Printf.sprintf "¬%a" (fun x -> formula_to_string 3) f
  | PossiblyF (_, _, i, r, f) -> Printf.sprintf (paren l 0 "<%a> %a %a") (fun x -> regex_to_string 0) r (fun x -> interval_to_string) i (fun x -> formula_to_string 4) f
  | PossiblyP (_, _, i, f, r) -> Printf.sprintf (paren l 0 "%a %a <%a>") (fun x -> formula_to_string 4) f (fun x -> interval_to_string) i (fun x -> regex_to_string 0) r
and regex_to_string l = function
  | Seq (Test f, Wild) -> Printf.sprintf "%a" (fun x -> formula_to_string 0) f
  | Seq (Wild, Test f) -> Printf.sprintf "%a" (fun x -> formula_to_string 0) f
  | Wild -> Printf.sprintf "."
  | Test f -> Printf.sprintf "%a?" (fun x -> formula_to_string 3) f
  | Alt (r, s) -> Printf.sprintf (paren l 1 "%a + %a") (fun x -> regex_to_string 1) r (fun x -> regex_to_string 1) s
  | Seq (r, s) -> Printf.sprintf (paren l 2 "%a %a") (fun x -> regex_to_string 2) r (fun x -> regex_to_string 2) s
  | Star (r) -> Printf.sprintf  "%a*" (fun x -> regex_to_string 3) r
let formula_to_string = formula_to_string 0


let rec print_formula l out = function
  | P (_, x) -> Printf.fprintf out "%s" x
  | Bool b -> Printf.fprintf out (if b then "⊤" else "⊥")
  | Conj (f, g) -> Printf.fprintf out (paren l 2 "%a ∧ %a") (print_formula 2) f (print_formula 2) g
  | Disj (f, g) -> Printf.fprintf out (paren l 1 "%a ∨ %a") (print_formula 1) f (print_formula 1) g
  | Neg f -> Printf.fprintf out "¬%a" (print_formula 3) f
  | PossiblyF (_, _, i, r, f) -> Printf.fprintf out (paren l 0 "<%a> %a %a") (print_regex 0) r print_interval i (print_formula 4) f
  | PossiblyP (_, _, i, f, r) -> Printf.fprintf out (paren l 0 "%a %a <%a>") (print_formula 4) f print_interval i (print_regex 0) r
and print_regex l out = function
  | Seq (Test f, Wild) -> Printf.fprintf out "%a" (print_formula 0) f
  | Seq (Wild, Test f) -> Printf.fprintf out "%a" (print_formula 0) f
  | Wild -> Printf.fprintf out "."
  | Test f -> Printf.fprintf out "%a?" (print_formula 3) f
  | Alt (r, s) -> Printf.fprintf out (paren l 1 "%a + %a") (print_regex 1) r (print_regex 1) s
  | Seq (r, s) -> Printf.fprintf out (paren l 2 "%a %a") (print_regex 2) r (print_regex 2) s
  | Star (r) -> Printf.fprintf out "%a*" (print_regex 3) r
let print_formula = print_formula 0

let rec maxidx_of = function
  | P (i, x) -> i
  | Conj (f, g) | Disj (f, g) -> max (maxidx_of f) (maxidx_of g)
  | Neg f -> maxidx_of f
  | PossiblyF (j, _, _, _, _) | PossiblyP (j, _, _, _, _) -> j
  | Bool _ -> -1

let rec maxidx_of_re = function
  | Wild -> -1
  | Test f -> maxidx_of f
  | Alt (r, s) | Seq (r, s) -> max (maxidx_of_re r) (maxidx_of_re s)
  | Star r -> maxidx_of_re r

let rec lift n = function
  | P (i, x) -> P (i + n, x)
  | Conj (f, g) -> Conj (lift n f, lift n g)
  | Disj (f, g) -> Disj (lift n f, lift n g)
  | Neg f -> Neg (lift n f)
  | PossiblyF (j, ii, i, r, f) -> PossiblyF (j + n, ii, i, lift_re n r, lift n f)
  | PossiblyP (j, ii, i, f, r) -> PossiblyP (j + n, ii, i, lift n f, lift_re n r)
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
let alt f g = Alt (f, lift_re (maxidx_of_re f + 1) g)
let seq f g = 
  match f, g with
  | Test (Bool true), g | g, Test (Bool true) -> g
  | Test (Bool false), _ | _, Test (Bool false) -> Test (Bool false)
  | _ -> Seq (f, lift_re (maxidx_of_re f + 1) g)
let seq_lifted f g = 
  match f, g with
  | Test (Bool true), g | g, Test (Bool true) -> g
  | Test (Bool false), _ | _, Test (Bool false) -> Test (Bool false)
  | _ -> Seq (f, g)
let rec star = function
  | Star f -> star f
  | f -> Star f
let baseF f = seq (test f) wild
let baseP f = seq wild (test f)

let rec compare f g = match f,g with
  | (Bool b, Bool c) -> Pervasives.compare b c
  | (Bool _, _) -> 1
  | (_, Bool _) -> -1
  | (P (_, x), P (_, y)) -> Pervasives.compare x y
  | (P _, _) -> 1
  | (_, P _) -> -1
  | (Conj (f, g), Conj (f', g')) -> let cf = compare f f' in if cf = 0 then compare g g' else cf
  | (Conj _, _) -> 1
  | (_, Conj _) -> -1
  | (Disj (f, g), Disj (f', g')) -> let cf = compare f f' in if cf = 0 then compare g g' else cf
  | (Disj _, _) -> 1
  | (_, Disj _) -> -1
  | (Neg f, Neg g) -> compare f g
  | (Neg _, _) -> 1
  | (_, Neg _) -> -1
  | (PossiblyF (_, _, i, r, f), PossiblyF (_, _, i', r', f')) ->
      let ci = Pervasives.compare i i' in if ci = 0 then
        (let cr = compare_re r r' in if cr = 0 then compare f f' else cr)
      else ci
  | (PossiblyF _, _) -> 1
  | (_, PossiblyF _) -> -1
  | (PossiblyP (_, _, i, f, r), PossiblyP (_, _, i', f', r')) ->
      let ci = Pervasives.compare i i' in if ci = 0 then
        (let cf = compare f f' in if cf = 0 then compare_re r r' else cf)
      else ci
and compare_re r s = match r,s with
  | (Wild, Wild) -> 0
  | (Wild, _) -> 1
  | (_, Wild) -> -1
  | (Test f, Test g) -> compare f g
  | (Test _, _) -> 1
  | (_, Test _) -> -1
  | (Alt (r, s), Alt (r', s')) -> let cr = compare_re r r' in if cr = 0 then compare_re s s' else cr
  | (Alt _, _) -> 1
  | (_, Alt _) -> -1
  | (Seq (r, s), Seq (r', s')) -> let cr = compare_re r r' in if cr = 0 then compare_re s s' else cr
  | (Seq _, _) -> 1
  | (_, Seq _) -> -1
  | (Star r, Star s) -> compare_re r s


module RES = Set.Make(struct type t = regex let compare = compare_re end)

let rec split = function
  | Alt (r, s) -> RES.union (split r) (split (lift_re (- maxidx_of_re r - 1) s))
  | r -> RES.singleton r

let rec nullable_overapprox = function
  | Wild -> false
  | Test f -> true
  | Alt (r, s) -> nullable_overapprox r || nullable_overapprox s
  | Seq (r, s) -> nullable_overapprox r && nullable_overapprox s
  | Star r -> true

let seqs l s = RES.map (fun r -> seq_lifted r s) l

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
    (*let _ = RES.iter (Printf.printf "%a\n%!" (print_regex 0)) d in*)
    if RES.is_empty d then s else go (step s d) in
  go init

let rec rev_re = function
  | Wild -> Wild
  | Test f -> Test f
  | Alt (r, s) -> Alt (rev_re r, rev_re s)
  | Seq (r, s) -> Seq (rev_re s, rev_re r)
  | Star r -> Star (rev_re r)

let nders r = RES.cardinal (ders_overapprox r)

let imp f g = disj (neg f) g
let iff f g = conj (imp f g) (imp g f)
let possiblyF r i f = RES.fold (fun s -> let n = maxidx_of_re s + 1 in
    disj (PossiblyF (maxidx_of f + n + (right_I i + 1) * nders s, right_I i + 1, i, s, lift n f))) (split r)
  (bool false)
let possiblyP f i r = RES.fold (fun s -> let n = maxidx_of f + 1 in
    disj (PossiblyP (maxidx_of_re s + n + (right_I i + 1) * nders (rev_re s), right_I i + 1, i, f, lift_re n s))) (split r)
  (bool false)
let necessarilyF r i f = neg (possiblyF r i (neg f))
let necessarilyP f i r = neg (possiblyP (neg f) i r)
let next i f = possiblyF (baseF (bool true)) i f
let prev i f = possiblyP f i (baseP (bool true))
let until i f g = possiblyF (star (baseF f)) i g
let since i f g = possiblyP g i (star (baseP f))
let release i f g = neg (until i (neg f) (neg g))
let weak_until i f g = release i g (disj f g)
let trigger i f g = neg (since i (neg f) (neg g))
let eventually i f = until i (bool true) f
let always i f = neg (eventually i (neg f))
let once i f = since i (bool true) f
let historically i f = neg (once i (neg f))


module MDL (C : Cell) : Formula with type f = formula and type memory = C.future_cell array = struct

type f = formula
type memory = C.future_cell array
module C = C
open C

let rec bounded_future = function
  | Bool _ -> true
  | P _ -> true
  | PossiblyP (_, _, _, f, r) -> bounded_future f && bounded_future_re r
  | Conj (f, g) | Disj (f, g) -> bounded_future f && bounded_future g
  | PossiblyF (_, _, i, r, f) ->
      case_I (fun _ -> true) (fun _ -> false) i && bounded_future_re r && bounded_future f
  | Neg f -> bounded_future f
and bounded_future_re = function
  | Wild -> true
  | Test f -> bounded_future f
  | Alt (r, s) | Seq (r, s) -> bounded_future_re r && bounded_future_re s
  | Star r -> bounded_future_re r

let print_formula = print_formula

let idx_of = function
  | P (j, _) | PossiblyF (j, _, _, _, _) | PossiblyP (j, _, _, _, _) -> j
  | _ -> failwith "not an indexed subformula"

let mk cnj dsj neg bo idx =
  let rec go = function
    | Conj (f, g) -> cnj (go f) (go g)
    | Disj (f, g) -> dsj (go f) (go g)
    | Neg f -> neg (go f)
    | Bool b -> bo b
    | f -> idx (idx_of f) in
  go
let mk_cell = mk cconj cdisj cneg cbool
let mk_fcell = mk fcconj fcdisj fcneg fcbool

let rec sub = function 
  | Neg f -> sub f
  | Conj (f, g) -> sub g @ sub f
  | Disj (f, g) -> sub g @ sub f
  | PossiblyF (j, ii, i, r, f) -> PossiblyF (j, ii, i, r, f) :: sub f @ sub_re r
  | PossiblyP (j, ii, i, f, r) -> PossiblyP (j, ii, i, f, r) :: sub_re r @ sub f
  | P _ as f -> [f]
  | _ -> []
and sub_re = function
  | Wild -> []
  | Test f -> sub f
  | Alt (r, s) | Seq (r, s) -> sub_re s @ sub_re r
  | Star r -> sub_re r

let ders_overapprox x = RES.elements (ders_overapprox x)
let rev_ders_overapprox x = List.map rev_re (ders_overapprox (rev_re x))

let aux = function
  | PossiblyF (j,ii,i,r,f) ->
      let ders = ders_overapprox r in
      let m = right_I i in
      List.concat (List.mapi (fun l s ->
        List.map (fun n -> PossiblyF (j - n - l * (m + 1), ii, subtract_I n i, s, f)) (0 -- m)) ders)
  | PossiblyP (j,ii,i,f,r) ->
      let ders = rev_ders_overapprox r in
      let m = right_I i in
      List.concat (List.mapi (fun l s ->
        List.map (fun n -> PossiblyP (j - n - l * (m + 1), ii, subtract_I n i, f, s)) (0 -- m)) ders)
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
let fnullable curr = nullable curr fcconj fcdisj (fcbool true) (fcbool false)
let nullable curr = nullable curr cconj cdisj (cbool true) (cbool false)

let derF curr finish =
  let rec go fin = function
  | Wild -> fin epsilon
  | Test f -> fcbool false
  | Alt (r, s) -> fcdisj (go fin r) (go fin s)
  | Seq (r, s) -> fcdisj (go (fun t -> fin (seq_lifted t s)) r) (fcconj (fnullable curr r) (go fin s))
  | Star r -> go (fun t -> fin (seq_lifted t (star r))) r
  in go finish

let derP curr finish =
  let rec go fin = function
  | Wild -> fin epsilon
  | Test f -> fcbool false
  | Alt (r, s) -> fcdisj (go fin r) (go fin s)
  | Seq (r, s) -> fcdisj (go (fun t -> fin (seq_lifted r t)) s) (fcconj (fnullable curr s) (go fin r))
  | Star r -> go (fun t -> fin (seq_lifted (star r) t)) r
  in go finish

let init f =
  let f_vec = Array.of_list (ssub f) in
  (*let _ = Array.iteri (fun i g -> Printf.printf "%d-%d:: %a\n%!" i (idx_of g) print_formula g) f_vec in*)
  let n = Array.length f_vec in
  (*local search more efficient, than just traversing the whole array*)
  let rec find offset = function
    | PossiblyF (j, ii, i, r, f) as g ->
      let l = j - offset * ii in
      let u = j + offset * ii in
      if l > 0 && compare f_vec.(l) (PossiblyF (l, ii, i, r, f)) = 0 then l
      else if l < u && u < n && compare f_vec.(u) (PossiblyF (u, ii, i, r, f)) = 0 then u
      else if l < 0 && u > n then failwith "find: out of bounds (F)"
      else find (offset + 1) g
    | PossiblyP (j, ii, i, f, r) as g ->
      let l = j - offset * ii in
      let u = j + offset * ii in
      if l >= 0 && compare f_vec.(l) (PossiblyP (l, ii, i, f, r)) = 0 then l
      else if u > l && u < n && compare f_vec.(u) (PossiblyP (u, ii, i, f, r)) = 0 then u
      else if l < 0 && u >= n then failwith "find: out of bounds (P)"
      else find (offset + 1) g
    | _ -> failwith "find: not a temporal subformula" in
  let find = find 0 in
  let rec reindex = function
    | PossiblyF (j, ii, i, r, f) as g -> PossiblyF (find g, ii, i, r, f)
    | PossiblyP (j, ii, i, f, r) as g -> PossiblyP (find g, ii, i, f, r)
    | Conj (f, g) -> Conj (reindex f, reindex g)
    | Disj (f, g) -> Disj (reindex f, reindex g)
    | Neg f -> Neg (reindex f)
    | g -> g in
  let v = cvar true in
  let mem = function
    | PossiblyF (j, ii, i, r, f) ->
        derF (fun h -> Now (mk_cell (fun i -> v (- i - 1)) h)) (fun s ->
          let k = find (PossiblyF (j, ii, i, s, f)) in
          Later (fun delta -> v (k - delta))) r
    | PossiblyP (j, ii, i, f, r) ->
        derP (fun h -> Now (mk_cell (fun i -> v (- i - 1)) h)) (fun s ->
          let k = find (PossiblyP (j, ii, i, f, s)) in
          Later (fun delta -> v (Format.printf "%d<%d\n" delta k; k - delta))) r
    | _ -> Later (fun _ -> cbool true) in
  (* let _ = Array.iteri (fun i x -> Printf.printf "%d %a: %a\n%!" i print_formula x print_cell (eval_future_cell 0 (mem x))) f_vec in *)
  (reindex f, f_vec, Array.map mem f_vec)

let progress (f_vec, m) (delta, ev) a =
  let n = Array.length f_vec in
  let b = Array.make n (fcbool false) in
  let curr = mk_fcell (fun i -> b.(i)) in
  let prev = mk_fcell (fun i -> a.(i)) in
  let prev f = subst_cell_future b (eval_future_cell delta (prev f)) in
  let next = mk_cell (cvar true) in
  let getF = map_future_cell (fun i ->
    try if i < 0 then curr f_vec.(- 1 - i) else Now (next f_vec.(i))
    with Invalid_argument _ -> fcbool false) in
  let getP = map_cell_future (fun i ->
    try if i < 0 then curr f_vec.(- 1 - i) else prev f_vec.(i)
    with Invalid_argument _ -> fcbool false) in
  for i = 0 to n - 1 do
    b.(i) <- match f_vec.(i) with
    | P (_, x) -> fcbool (SS.mem x ev)
    | PossiblyF (j, _, i, r, f) -> fcdisj
        (if mem_I 0 i then fcconj (fnullable curr r) (curr f) else fcbool false)
        (fcconj (Later (fun delta' -> cbool (case_I (fun i -> delta' <= right_BI i) (fun _ -> true) i)))
          (getF m.(j)))
    | PossiblyP (j, _, i, f, r) -> fcdisj
        (if mem_I 0 i then fcconj (fnullable curr r) (curr f) else fcbool false)
        (if case_I (fun i -> delta > right_BI i) (fun _ -> false) i
          then fcbool false
          else getP (eval_future_cell delta m.(j)))
    | _ -> failwith "not a temporal formula"
  done;
  b

end

module Monitor_MDL(C : Cell) = Monitor.Make(MDL(C))
