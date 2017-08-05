(*******************************************************************)
(*     This is part of Aerial, it is distributed under the         *)
(*  terms of the GNU Lesser General Public License version 3       *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2017:                                                *)
(*  Dmitriy Traytel (ETH Zürich)                                   *)
(*******************************************************************)

(* This is an example test file
   Whenever you want to test a module
   from src folder, create a new .ml file 
   in the test folder, open the module, 
   bind some function from the module to 
   a new name, and write the tests in the
   special comments above each method 
   (as shown in examples below).

   Special comment has the following syntax
   (*<test type> <header>
      <statement>
      ... 
    *)

   There are couple of types of tests: simple ($T),
   equality ($=), quickcheck ($Q) and raw ($R) oUnit
   tests.

   <header> references the function(s) under test

   <statement> must be a boolean OCaml expression
   involving the function(s) from the header

   Once the tests are written invoke
    $ make test
   from the project root
   
*)

(* Simple test cases *)

(*$T foo
  foo  0 ( + ) [1;2;3] = 6
  foo  0 ( * ) [1;2;3] = 0
  foo  1 ( * ) [4;5]   = 20
  foo 12 ( + ) []      = 12
*)

(* Equality test cases
  They are simple test cases that also report the values
  of the left-hand side and the right-hand side of the 
  boolean expressions, if they differ.
  To pretty print them one needs to also include in the 
  header printing function of type 'a -> string, where 
  'a is the type of the expressions.
 *)

(*$= foo & ~printer:string_of_int
  (foo 1 ( * ) [4;5]) (foo 2 ( * ) [1;5;2])
*)


(* Quickcheck test cases 
  The Quickcheck module is accessible simply as Q 
  within inline tests. Tests are of the form: 
  (*$Q <header>
    <generator> (fun <generated value> -> <statement>)
    ...
  *)
  Available Generators:

  - Simple generators:
  unit, bool, float, pos_float, neg_float, int, pos_int, small_int, neg_int, char, printable_char, numeral_char, string, printable_string, numeral_string
  - Structure generators:
  list and array. They take one generator as their argument. For instance (Q.list Q.neg_int) is a generator of lists of (uniformly taken) negative integers.
  - Tuples generators:
  pair and triple are respectively binary and ternary. See above for an example of pair.
  - Size-directed generators:
  string, numeral_string, printable_string, list and array all have *_of_size variants that take the size of the structure as their first argument.
*)

(*$Q foo
  Q.small_int (fun i -> foo i (+) [1;2;3] = i+6)
  (Q.pair Q.small_int (Q.list Q.small_int)) (fun (i,l) -> foo i (+) l = List.fold_left (+) i l)
*)

let rec foo x0 f = function
  [] -> x0 | x::xs -> f x (foo x0 f xs)
  