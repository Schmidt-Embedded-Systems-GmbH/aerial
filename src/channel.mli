open Util

type input_channel = 
  | Input of in_channel 
  | InputMock of string list

type output_channel = 
  | Output of out_channel 
  | OutputMock of string list


val input_string: input_channel -> string * input_channel
val input_event: input_channel -> (SS.t * int) * input_channel
val output_event: output_channel -> string -> output_channel 
val output_verdict: output_channel -> (timestamp * int) * bool -> output_channel
val output_eq: output_channel -> (timestamp * int) * (timestamp * int) -> output_channel
val print_interval: output_channel -> interval -> output_channel
