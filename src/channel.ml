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
  | OutputFlushed of out_channel
  | OutputMock of output_type list

type channel = 
  | IC of input_channel 
  | OC of output_channel

exception End_of_mock of output_channel

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
      | [] -> raise (End_of_mock out)
      | a::ax -> match a with 
          | Event ev -> (ev, InputMock ax)
          | Noise str -> parse_lines str (InputMock ax) out)


let input_event log out = 
  match log with 
  | Input x ->  parse_lines (input_line x) log out
  | InputMock x -> match x with
    | [] -> raise (End_of_mock out)
    | a::ax -> match a with 
      | Event ev -> (ev, InputMock ax)
      | Noise s -> parse_lines s (InputMock ax) out



let output_event log event =
  match log with 
  | Output x -> Printf.fprintf x "%s" event; log
  | OutputFlushed x -> Printf.fprintf x "%s%!" event; log
  | OutputMock x -> OutputMock(x@[Info event])


let channel_to_string log = match log with 
| OC c -> (match c with
  | Output _ | OutputFlushed _ -> ""
  | OutputMock ls -> List.fold_left (fun a x -> a ^ (match x with 
      | BoolVerdict ((t, i), b) -> Printf.sprintf "%d:%d %B\n" t i b
      | EqVerdict ((t, i), (t', j)) -> Printf.sprintf "%d:%d = %d:%d\n" t i t' j
      | Info s -> s)
  ) "" ls)
 | IC c -> (match c with 
   | Input _ -> ""
   | InputMock ls -> List.fold_left (fun a x -> a ^ "\n" ^ (match x with 
      | Event (atoms,ts) -> Printf.sprintf "@%d %s" ts (Util.SS.fold (fun a x -> a ^ " " ^ x ) atoms "")
      | Noise s -> s) 
) "" ls)

  let verdicts log = match log with 
  | Output _ | OutputFlushed _ -> log
  | OutputMock ls -> OutputMock (List.filter (fun x -> match x with 
      | BoolVerdict _ | EqVerdict _ -> true
      | _ -> false
  ) ls )

let (<) a b = match a,b with 
  | BoolVerdict((t,i),_), BoolVerdict((t',i'),_) | BoolVerdict((t,i),_), EqVerdict((t',i'),_) | EqVerdict((t,i),_), BoolVerdict((t',i'),_) | EqVerdict((t,i),_), EqVerdict((t',i'),_) -> t<t' || (t=t' && i<i')
  | _,_ -> false

let sort ch = match ch with 
  | OutputMock c -> OutputMock (List.sort (fun a b -> if a<b then -1 else 1) c)
  | _ -> ch
  
let output_verdict fmt ((t, i), b) =
  match fmt with 
  | Output x -> Printf.fprintf x "%d:%d %B\n" t i b; fmt
  | OutputFlushed x -> Printf.fprintf x "%d:%d %B\n%!" t i b; fmt
  | OutputMock x -> OutputMock(x@[BoolVerdict ((t, i), b)]) 

let eliminate_eq_verdicts ch = 
  let rec eliminate_eq_verdicts_rec ls feqs res = 
  match ls with
  | [] -> res
  | l::lss -> (match l with 
    | BoolVerdict ((f,g),h) -> 
      let neweqs = fun x -> match x with | (a,b) when a=f && b=g  -> [] | _ -> feqs x in 
      let verdicts = List.map (fun x -> BoolVerdict (x,h)) (feqs (f,g)) in 
      eliminate_eq_verdicts_rec lss neweqs (verdicts@(BoolVerdict ((f,g),h)::res))
    | EqVerdict (a,b) -> eliminate_eq_verdicts_rec lss (fun x -> match x with z when z=b -> a::(feqs x) | _ -> feqs x ) res 
    | Info _ -> eliminate_eq_verdicts_rec lss feqs res) in
  match ch with 
  | Output _ | OutputFlushed _ -> ch
  | OutputMock ls -> sort (OutputMock (List.rev (eliminate_eq_verdicts_rec ls (fun x -> []) [])))
  
 
let output_eq fmt ((t, i), (t', j)) = 
  match fmt with 
  | Output x -> Printf.fprintf x "%d:%d = %d:%d\n" t i t' j; fmt
  | OutputFlushed x -> Printf.fprintf x "%d:%d = %d:%d\n%!" t i t' j; fmt
  | OutputMock x -> OutputMock(x@[EqVerdict ((t, i), (t', j))])

let print_interval out i = output_event out (interval_to_string i)