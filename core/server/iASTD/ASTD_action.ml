
type force_pass_by_value = bool
type arg = ASTD_variable.t * force_pass_by_value

type t = int * string * arg list

let action_of id fct_name args : t =
  id, fct_name, args

let action_of_auto_id fct_name args : t =
  action_of (ASTD_functions.get_unique_id ()) fct_name args

let partially_initialized_arg_of variable_name : arg =
  (ASTD_variable.variable_of variable_name "" true, false)

let arg_of_variable variable : arg =
  variable, false

let get_id action =
  let id, fct_name, args = action in id

let get_fct_name action =
  let id, fct_name, args = action in fct_name

let get_args action =
  let id, fct_name, args = action in args

let variable_of_arg (arg : arg) : ASTD_variable.t =
  let variable, force_pass_by_value = arg in variable

let variables_of_args (args : arg list) : ASTD_variable.t list =
  List.map variable_of_arg args

let is_readonly_from_arg arg =
  ASTD_variable.is_readonly (variable_of_arg arg)

let get_variable_name_from_arg arg =
  ASTD_variable.get_name (variable_of_arg arg)

let get_variable_type_from_arg arg =
  ASTD_variable.get_type (variable_of_arg arg)

let is_force_pass_by_value_from_arg arg =
  let variable, force_pass_by_value = arg in force_pass_by_value 

let update_args_of_action action new_args : t = 
  let id, fct_name, args = action in
    id, fct_name, new_args

let update_variable_of_arg arg new_variable =
  let variable, force_pass_by_value = arg in
    new_variable, force_pass_by_value

let update_force_pass_by_value_of_arg arg new_force_pass_by_value =
  let variable, force_pass_by_value = arg in
    variable, new_force_pass_by_value

let parse_variable variable_string = 
  if String.length variable_string = 0 then
    failwith "Failed to parse empty variable string"
  else
    let regex_for_letters = Str.regexp "[A-Za-z]" in
    let first_letter = String.sub variable_string 0 1 in 
    if first_letter = "!" then
      let variable_name = String.sub variable_string 1 ((String.length variable_string) - 1) in
      let arg = partially_initialized_arg_of variable_name in
        update_force_pass_by_value_of_arg arg true
    else if Str.string_match regex_for_letters variable_string 0 then
      partially_initialized_arg_of variable_string
    else
      failwith ("Invalid variable name in action parameter : " ^ variable_string)

let action_of_string action_string =
  try
    if String.length action_string == 0 then 
      None
    else if not (String.contains action_string '(') then
      Some (action_of_auto_id action_string [])
    else
      let separated_by_opening_parenthesis = String.split_on_char '(' action_string in
      let function_name = List.nth separated_by_opening_parenthesis 0 in
      let args_string_with_closing_parenthesis = List.nth separated_by_opening_parenthesis 1 in
      let args_string = List.hd (String.split_on_char ')' args_string_with_closing_parenthesis) in
      let variable_string_list = 
        if String.length args_string == 0 
        then [] 
        else List.map String.trim (String.split_on_char ',' args_string) in 
      let args = List.map parse_variable variable_string_list in
        Some (action_of_auto_id function_name args)
  with exn -> failwith ("Action not properly formatted. Action : " ^ action_string ^ " **** Exception in code : " ^ (Printexc.to_string exn))


