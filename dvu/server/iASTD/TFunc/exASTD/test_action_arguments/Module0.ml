
let print_hello () = 
  print_endline "Hello!"

let set_to_zero any_var = 
  print_endline ("Set " ^ string_of_int !any_var ^ " to 0");
  any_var := 0

let inc_by_one any_var = 
  print_endline ("Increment by one : " ^ string_of_int !any_var);
  any_var := !any_var + 1

let inc_by_ten any_var = 
  print_endline ("Increment by ten : " ^ string_of_int !any_var);
  any_var := !any_var + 10

let inc_by_ten_if_five any_var = 
  if !any_var = 5 
  then (
    print_endline ("Increment by ten : " ^ string_of_int !any_var);
    any_var := !any_var + 10 
  )
  else print_endline ("The var is not equal to 5 : " ^ string_of_int !any_var)


let inc_if_zero any_var = 
  if !any_var = 0 
  then inc_by_one any_var
  else print_endline ("The var is not equal to 0 : " ^ string_of_int !any_var)

let inc_if_two any_var = 
  if !any_var = 2
  then inc_by_one any_var
  else print_endline ("The var is not equal to 2 : " ^ string_of_int !any_var)

let inc_if_four any_var = 
  if !any_var = 4
  then inc_by_one any_var
  else print_endline ("The var is not equal to 4 : " ^ string_of_int !any_var)

let execute () = 
  print_endline "START Execute from Code0 ! END"

let print_string_val string_val = 
  print_endline !string_val

let request string_val1 ref_string_val2 =
  print_string_val (ref string_val1);
  print_string_val ref_string_val2;
  ref_string_val2 := "response"

let print_args int_value ref_int_value =
  print_endline (string_of_int int_value);
  print_endline (string_of_int !ref_int_value)

let action_test (a : int) (a_ref : int ref) (x : int) (p : int) (p_ref : int ref) : unit =
  ()
