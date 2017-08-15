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

type channel = 
  | IC of input_channel 
  | OC of output_channel

exception End_of_mock of output_channel

(* val input_string: input_channel -> string * input_channel *)
val input_event: input_channel -> output_channel -> (SS.t * int) * input_channel
val output_event: output_channel -> string -> output_channel 

val channel_to_string: channel -> string
val verdicts: output_channel -> output_channel

val eliminate_eq_verdicts: output_channel -> output_channel  
val sort: output_channel -> output_channel  

val output_verdict: output_channel -> (timestamp * int) * bool -> output_channel
val output_eq: output_channel -> (timestamp * int) * (timestamp * int) -> output_channel
val print_interval: output_channel -> interval -> output_channel

