module Html = Dom_html
module Json = Yojson.Basic
open Json.Util

let (>>=) = Lwt.bind

(*type kind = F | S
type example = {name: string; filename: string; kind: kind; preprocess: string -> string}*)

let formula = ref (None : Mtl.formula option)
let examples =
  [ "publish/approve", "ex1"
  ; "request/response", "ex2"
  ; "start/between/end", "ex3"
  ]

let http_get url =
  XmlHttpRequest.get url >>= fun r ->
  let cod = r.XmlHttpRequest.code in
  let msg = r.XmlHttpRequest.content in
  if cod = 0 || cod = 200
  then Lwt.return msg
  else fst (Lwt.wait ())

let getfile f =
  try
    Lwt.return (Sys_js.file_content f)
  with Not_found ->
    http_get f

let onload _ =
  let d = Html.document in
  let body = Js.Opt.get (d##getElementById (Js.string "aerial")) (fun () -> assert false) in

  let title = Html.createH1 d in
  title##.innerHTML := Js.string "Aerial <font size=3>Almost Event-Rate Independent Monitoring of Metric Temporal Properties</font>";
  
  let formulaDiv = Html.createDiv d in
  let ed_name = "*edited*" in
  let ex_names = List.map fst examples in

  let append_text e s = Dom.appendChild e (d##createTextNode (Js.string s)) in

  append_text formulaDiv "Select example ";
  let select = Html.createSelect d in
  List.iter
    (fun text ->
       let option = Html.createOption d in
       append_text option text;
       Dom.appendChild select option)
    (ed_name :: ex_names);
  Dom.appendChild formulaDiv select;
  append_text formulaDiv ", edit, or load formula file ";
  
  let formulain = Html.createInput ?_type:(Some (Js.string "file")) d in
  Dom.appendChild formulaDiv formulain;

  Dom.appendChild formulaDiv (Html.createP d);

  let formulaframe = Html.createTextarea d in
  formulaframe##.style##.border := Js.string "2px green solid";
  formulaframe##.rows := 4;
  formulaframe##.id := Js.string "formula";
  Dom.appendChild formulaDiv formulaframe;

  Dom.appendChild formulaDiv (Html.createBr d);

  append_text formulaDiv "Syntax: ";

  let append_hover e s h =
    let span = Html.createSpan d in
    span##.style##.font := Js.string "Courier New, Courier, monospace";
    span##.style##.fontSize := Js.string "20px";
    span##.textContent := Js.some (Js.string s);
    span##.title := Js.string h;
    Dom.appendChild e span;
    let span = Html.createSpan d in
    span##.style##.display := Js.string "inline-block";
    span##.style##.width := Js.string "5pt";
    Dom.appendChild e span; in
  append_hover formulaDiv "p" "atomic predicate: almost any string starting with a-zA-Z";
  append_hover formulaDiv "⊥" "false";
  append_hover formulaDiv "⊤" "true";
  append_hover formulaDiv "¬" "!";
  append_hover formulaDiv "∧" "&";
  append_hover formulaDiv "∨" "|";
  append_hover formulaDiv "→" "->";
  append_hover formulaDiv "↔" "<->";
  append_hover formulaDiv "○" "NEXT";
  append_hover formulaDiv "□" "ALWAYS";
  append_hover formulaDiv "◊" "EVENTUALLY";
  append_hover formulaDiv "U" "UNTIL";
  append_hover formulaDiv "R" "RELEASE";
  append_hover formulaDiv "W" "WEAK_UNTIL";
  append_hover formulaDiv "●" "PREV";
  append_hover formulaDiv "■" "HISTORICALLY";
  append_hover formulaDiv "⧫" "ONCE";
  append_hover formulaDiv "S" "SINCE";
  append_hover formulaDiv "T" "TRIGGER";
  append_hover formulaDiv "∞" "INFINITY";
 
  (*let tab = Html.createTable d in
  let tr1 = Html.createTr d in
  let tdl1 = Html.createTd d in
  let tdr1 = Html.createTd d in
  let tr2 = Html.createTr d in
  let tdl2 = Html.createTd d in
  let tdr2 = Html.createTd d in
  let tr4 = Html.createTr d in
  let tdl4 = Html.createTd d in
  let tr5 = Html.createTr d in
  let tdl5 = Html.createTd d in
  let tr6 = Html.createTr d in
  let tdl6 = Html.createTd d in*)
  
  (*tdl1##.vAlign := Js.string "top";
  tdr1##.vAlign := Js.string "top";
  tdl2##.vAlign := Js.string "top";
  tdr2##.vAlign := Js.string "top";
  tdr2##.rowSpan := 5;
  tdl4##.vAlign := Js.string "top";
  tdl5##.vAlign := Js.string "top";
  tdl6##.vAlign := Js.string "top";*)
  
  (*let logtext = Html.createB d in
  logtext##.innerHTML := Js.string "Log ";
  let login = Html.createInput ?_type:(Some (Js.string "file")) d in
  let logframe = Html.createTextarea d in
  logframe##.style##.border := Js.string "2px green solid";
  logframe##.rows := 35;
  logframe##.id  := Js.string "log";

  let restext = Html.createB d in
  restext##.innerHTML := Js.string "Violations ";
  let resframe = Html.createTextarea d in
  resframe##.style##.border := Js.string "2px red solid";
  resframe##.style##.backgroundColor := Js.string "lightgrey";
  resframe##.rows := 3;
  resframe##.id  := Js.string "res";
  resframe##.disabled  := Js._true;*)

  Dom.appendChild body title;
  Dom.appendChild body formulaDiv;
  Dom.appendChild body (Html.createHr d);

  let wiki = new%js EventSource.eventSource (Js.string "https://stream.wikimedia.org/v2/stream/recentchange") in
  wiki##.onmessage := Dom.handler(fun msg ->
     Format.eprintf "%a" (Json.pretty_print ~std:false)
       (member "timestamp" (Json.from_string (Js.to_string (msg##.data))));
     Js._false);
  (*Dom.appendChild tdr1 logtext;
  Dom.appendChild tdr1 login;
  Dom.appendChild tdr2 logframe;
  Dom.appendChild tdl5 restext;
  Dom.appendChild tdl6 resframe;
  Dom.appendChild tr1 tdl1;
  Dom.appendChild tr1 tdr1;
  Dom.appendChild tr2 tdl2;
  Dom.appendChild tr2 tdr2;
  Dom.appendChild tr4 tdl4;
  Dom.appendChild tr5 tdl5;
  Dom.appendChild tr6 tdl6;
  Dom.appendChild tab tr1;
  Dom.appendChild tab tr2;
  Dom.appendChild tab tr4;
  Dom.appendChild tab tr5;
  Dom.appendChild tab tr6;
  Dom.appendChild body tab;*)

  (*let append_res s =
    resframe##.value := Js.string (Js.to_string (resframe##.value) ^ s) in*)

  let append_err err s =
    err##.title := Js.string (Js.to_string (err##.title) ^ s) in

  (*Sys_js.set_channel_flusher stdout append_res;*)

  let color_frame border deact xframe =
    xframe##.style##.border := Js.string border;
    xframe##.style##.backgroundColor :=
      Js.string (if deact then "lightgrey" else "white");
    xframe##.style##.backgroundImage := Js.string "none";
    xframe##.disabled := Js.bool deact in

  let deactivate = color_frame "2px grey solid" true in
  let error = color_frame "2px red solid" false in
  let warn = color_frame "2px yellow solid" false in
  let ok = color_frame "2px green solid" false in

  (*let visibility_res vis = 
    resframe##.style##.display := Js.string vis;
    restext##.style##.display := Js.string vis in
  
  let hide_res () = visibility_res "none" in
  let show_res () = visibility_res "inline" in*)

  let register xin xframe xcheck =
    xframe##.oninput := Html.handler (fun _ ->
      xcheck ();
      select##.value := Js.string ed_name;
      xin##.value := Js.string "";
      Js._true);
    xin##.onchange := Html.handler (fun _ ->
      Js.Optdef.iter (xin##.files) (fun fs ->
        Js.Opt.iter (fs##item(0)) (fun file ->
          ignore (File.readAsText file >>= (fun text ->
	    xframe##.value := text;
	    xcheck ();
	    select##.value := Js.string ed_name;
	    Lwt.return_unit));
	  ()));
      Js._true) in

  let reset_errs () =
    formulaframe##.title := Js.string "";
    (*logframe##.title := Js.string ""*) in

  (*let check_log () =
    logframe##.style##.border := Js.string "2px green solid";
    match !formula with
    | None -> ()
    | Some f ->
       try
	 resframe##.value := Js.string "";
	 reset_errs ();
	 Sys_js.set_channel_flusher stderr (append_err logframe);
	 logframe##.style##.backgroundImage := Js.string "none";
	 (*Algorithm.monitor_string (Js.to_string (logframe##.value) ^ "\n") f;*)
	 if Js.to_string (resframe##.value) = ""
	 then
	   (ok logframe; hide_res ();
	   logframe##.style##.backgroundImage := Js.string "url(\"check.png\")")
	 else
	   (warn logframe; show_res ())
       with e ->
	 error logframe; hide_res ()
    in*)
  
  let check_formula () =
    (try
      reset_errs ();
      Sys_js.set_channel_flusher stderr (append_err formulaframe);
      formula := Some (Parser.formula Lexer.token (Lexing.from_string (Js.to_string (formulaframe##.value))));
      ok formulaframe;
      (*deactivate logframe;
      hide_res ();*)
    with e ->
      formula := None;
      error formulaframe;
      (*deactivate logframe;
      hide_res ()*)) in

  register formulain formulaframe check_formula;
  (*register login logframe check_log;*)

  let load name xending xframe =
    ignore (getfile ("examples/" ^ List.assoc name examples ^ xending) >>=
      (fun s -> Lwt.return (xframe##.value := Js.string s))) in
  let load_ex name =
    load name ".mtl" formulaframe;
    (*load name ".log" logframe;*) in
  select##.onchange := Html.handler
    (fun _ ->
      let i = select##.selectedIndex - 1 in
      if i >= 0 && i < List.length ex_names then
         load_ex (List.nth ex_names i);
      Js._false);
  let default = List.nth ex_names 0 in
  select##.value := Js.string default;
  load_ex default;
  
  Js._false

let _ = Html.window##.onload := Html.handler onload

