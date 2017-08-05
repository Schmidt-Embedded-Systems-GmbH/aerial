open Util 

type input_type =
  | Event of (SS.t * int)
  | Noise of string

type input_channel = 
  | Input of in_channel 
  | InputMock of input_type list

type output_type = 
  | BoolVerdict of (timestamp * int) * bool
  | EqVerdict of (timestamp * int) * (timestamp * int)
  | Info of string

type output_channel = 
  | Output of out_channel 
  | OutputMock of output_type list


let parse_line s =
  match String.split_on_char ' ' (String.sub s 1 (String.length s - 1)) with
  | [] -> None
  | raw_t :: preds ->
    try Some (SS.of_list (List.filter (fun x -> x <> "()") preds), int_of_string raw_t)
    with Failure _ -> None

(* let input_string log =
  match log with 
  | Input x -> (input_line x, Input x)
  | InputMock x -> match x with 
    | [] -> raise End_of_file 
    | a::ax -> (a, InputMock ax) *)


let rec parse_lines line ch =  
  match ch with 
  | Input x -> (match parse_line line with 
    | Some s -> (s,ch)
    | None -> parse_lines (input_line x) ch)
  | InputMock x -> (match parse_line line with 
    | Some x -> (x,ch)
    | None -> match x with 
      | [] -> raise End_of_file
      | a::ax -> match a with 
          | Event ev -> (ev, InputMock ax)
          | Noise str -> parse_lines str (InputMock ax))


let input_event log = 
  match log with 
  | Input x ->  parse_lines (input_line x) log 
  | InputMock x -> match x with
    | [] -> raise End_of_file
    | a::ax -> match a with 
      | Event ev -> (ev, InputMock ax)
      | Noise s -> parse_lines s (InputMock ax)



let output_event log event =
  match log with 
  | Output x -> Printf.fprintf x "%s" event; log
  | OutputMock x -> OutputMock(x@[Info event])


let output_verdict fmt ((t, i), b) =
  match fmt with 
  | Output x -> Printf.fprintf x "%d:%d %B\n" t i b; fmt
  | OutputMock x -> OutputMock(x@[BoolVerdict ((t, i), b)])

let output_eq fmt ((t, i), (t', j)) = 
  match fmt with 
  | Output x -> Printf.fprintf x "%d:%d = %d:%d\n" t i t' j; fmt
  | OutputMock x -> OutputMock(x@[EqVerdict ((t, i), (t', j))])

let print_interval out i = output_event out (interval_to_string i)