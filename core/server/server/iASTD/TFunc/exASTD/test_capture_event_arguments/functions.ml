
let test (my_var : int) (a : int ref) : unit =
  print_endline ("value of my_var : " ^ (string_of_int my_var));
  a := my_var
