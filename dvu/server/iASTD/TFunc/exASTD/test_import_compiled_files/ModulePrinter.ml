
let print n1 n2 = 
  print_endline ("(" ^ string_of_int !n1 ^ ", " ^ string_of_int !n2 ^ ") from ModulePrinter")

let () = 
  print_endline "ModulePrinter starded!"