let split s = 
  print_endline ("Splitting " ^ !s);
  let s_list = Str.split (Str.regexp " ") !s in
    List.iter print_endline s_list

let () = 
  print_endline "ModuleSplitter starded!"