let increment count = 
  count := !count + 1;
  print_endline ("count = " ^ (string_of_int !count))