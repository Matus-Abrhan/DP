exception ASTD_parsing_exception of string

type 'a parser_rule = (Lexing.lexbuf -> ASTD_parser_rules.token) -> Lexing.lexbuf -> 'a

let def_spec_types=ref ""

let syscall cmd =
    let ic, oc = Unix.open_process cmd in
    let buf = Buffer.create 16 in
    (try
       while true do
         Buffer.add_channel buf ic 1
       done
     with End_of_file -> ());
    let _ = Unix.close_process (ic, oc) in
    (Buffer.contents buf)

let contains s1 s2 =
    let re = Str.regexp s2
    in
        try ignore (Str.search_forward re s1 0); true
        with Not_found -> false

let get_from fname from parser_entry_rules =
    let trans_raw = (syscall ("python spectransform.py "^fname))
    in
    (print_endline trans_raw);
    if contains trans_raw "primitive type" then
       begin
           let raw = let s = ref ""
                  in try while true do s := (!s ^ (input_line from) ^ "\n") done ; ""
                     with End_of_file -> !s
           in let raw_spec = Lexing.from_string raw 
           in parser_entry_rules ASTD_lexer_rules.token raw_spec
       end
    else
       begin
           let trans_spec = let split = Str.split (Str.regexp "&") in
                                split trans_raw
           in
           print_endline (List.nth trans_spec 1);
           let raw_spec = Lexing.from_string (List.nth trans_spec 1) in
               begin
                    def_spec_types := (List.nth trans_spec 0);
                    parser_entry_rules ASTD_lexer_rules.token raw_spec
               end
       end

let get_def_spec_types() = !def_spec_types

let get_from_stdin rule = get_from "" stdin rule

let get_from_file file_name rule =
  let ic = open_in file_name in
  let result = get_from file_name ic rule in
    close_in ic ;
    result

let get_structure_from iname =
  let getter = if iname = "stdin"
               then get_from_stdin
               else get_from_file iname in
  getter ASTD_parser_rules.structure

let get_structure_from_stdin () = get_structure_from "stdin"

let get_event_list_from iname =
  let getter = if iname = "stdin"
                then get_from_stdin
                else get_from_file iname in
    getter ASTD_parser_rules.apply_event

let get_event_list_from_stdin () = get_event_list_from "stdin"
