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

exception End_of_file of output_channel

let parse_line s =
  match String.split_on_char ' ' (String.sub s 1 (String.length s - 1)) with
  | [] -> None
  | raw_t :: preds ->
    try Some (SS.of_list (List.filter (fun x -> x <> "()") preds), int_of_string raw_t)
    with Failure _ -> None


let rec parse_lines line ch out =  
  match ch with 
  | Input x -> (match parse_line line with 
    | Some s -> (s,ch)
    | None -> parse_lines (input_line x) ch out)
  | InputMock x -> (match parse_line line with 
    | Some x -> (x,ch)
    | None -> match x with 
      | [] -> raise (End_of_file out)
      | a::ax -> match a with 
          | Event ev -> (ev, InputMock ax)
          | Noise str -> parse_lines str (InputMock ax) out)


let input_event log out = 
  match log with 
  | Input x ->  parse_lines (input_line x) log out
  | InputMock x -> match x with
    | [] -> raise (End_of_file out)
    | a::ax -> match a with 
      | Event ev -> (ev, InputMock ax)
      | Noise s -> parse_lines s (InputMock ax) out



let output_event log event =
  match log with 
  | Output x -> Printf.fprintf x "%s" event; log
  | OutputMock x -> OutputMock(x@[Info event])


let channel_to_string log = match log with 
  | Output _ -> ""
  | OutputMock ls -> List.fold_left (fun a x -> a ^ (match x with 
      | BoolVerdict ((t, i), b) -> Printf.sprintf "%d:%d %B\n" t i b
      | EqVerdict ((t, i), (t', j)) -> Printf.sprintf "%d:%d = %d:%d\n" t i t' j
      | Info s -> s)
  ) "" ls


let output_verdict fmt ((t, i), b) =
  match fmt with 
  | Output x -> Printf.fprintf x "%d:%d %B\n" t i b; fmt
  | OutputMock x -> OutputMock(x@[BoolVerdict ((t, i), b)]) 


let output_eq fmt ((t, i), (t', j)) = 
  match fmt with 
  | Output x -> Printf.fprintf x "%d:%d = %d:%d\n" t i t' j; fmt
  | OutputMock x -> OutputMock(x@[EqVerdict ((t, i), (t', j))])

let print_interval out i = output_event out (interval_to_string i)