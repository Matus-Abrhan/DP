let read filename = 
  print_endline ("Reading json from " ^ !filename);
  let json = Yojson.Basic.from_string "{\"title\": \"Real World OCaml\"}" in
    print_endline (Yojson.Basic.pretty_to_string json)

let () = 
  print_endline "ModuleJsonReader starded!"