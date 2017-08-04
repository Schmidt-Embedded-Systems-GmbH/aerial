open Util 


type input_channel = 
  | Input of in_channel 
  | InputMock of string list

type output_channel = 
  | Output of out_channel 
  | OutputMock of string list


let parse_line s =
  match String.split_on_char ' ' (String.sub s 1 (String.length s - 1)) with
  | [] -> None
  | raw_t :: preds ->
    try Some (SS.of_list (List.filter (fun x -> x <> "()") preds), int_of_string raw_t)
    with Failure _ -> None

let input_string log =
  match log with 
  | Input x -> (input_line x, Input x)
  | InputMock x -> match x with 
    | [] -> raise End_of_file 
    | a::ax -> (a, InputMock ax)

let rec input_event log = 
  let (line, ch) = input_string log in
  match parse_line line with None -> input_event ch | Some x -> (x,ch)

let output_event log event =
  match log with 
  | Output x -> Printf.fprintf x "%s" event; log
  | OutputMock x -> OutputMock(x@[event])


let output_verdict fmt ((t, i), b) = output_event fmt (Printf.sprintf "%d:%d %B\n" t i b)
let output_eq fmt ((t, i), (t', j)) = output_event fmt (Printf.sprintf "%d:%d = %d:%d\n" t i t' j)

let print_interval out i = output_event out (interval_to_string i)