open OUnit2

let test_action_of_string_with_args test_ctx =
  let action = 
    match ASTD_action.action_of_string "M1.F1(x, y)" with
    | Some a -> a
    | None -> raise (Failure "test failed") in
  let fct_name = ASTD_action. get_fct_name action in
  let args = ASTD_action.get_args action in
  let arg1 = ASTD_action.get_variable_name_from_arg (List.nth args 0) in
  let arg2 = ASTD_action.get_variable_name_from_arg (List.nth args 1) in
  
  assert_equal fct_name "M1.F1";
  assert_equal arg1 "x";
  assert_equal arg2 "y"

let test_action_of_string_with_invalid_var_name test_ctx =
  try
    ignore(ASTD_action.action_of_string "M1.F1(x, 124y)");
    assert_failure "Action argument should not accept variable name beginning with digits"
  with _ -> ()

  

let test_action_of_string_with_unref_args test_ctx =
  let action = 
    match ASTD_action.action_of_string "M1.F1(!x, !y)" with
    | Some a -> a
    | None -> raise (Failure "test failed") in
  let fct_name = ASTD_action. get_fct_name action in
  let args = ASTD_action.get_args action in
  let arg1 = List.nth args 0 in
  let arg2 = List.nth args 1 in
  let var_name1 = ASTD_action.get_variable_name_from_arg arg1 in
  let var_name2 = ASTD_action.get_variable_name_from_arg arg2 in
  let arg1_force_pass_by_value = ASTD_action.is_force_pass_by_value_from_arg arg1 in 
  let arg2_force_pass_by_value = ASTD_action.is_force_pass_by_value_from_arg arg2 in 
  
  assert_equal fct_name "M1.F1";
  assert_equal var_name1 "x";
  assert_equal var_name2 "y";
  assert_equal arg1_force_pass_by_value true;
  assert_equal arg2_force_pass_by_value true

let test_action_of_string_with_some_unref_args test_ctx =
  let action = 
    match ASTD_action.action_of_string "M1.F1(!x, y)" with
    | Some a -> a
    | None -> raise (Failure "test failed") in
  let fct_name = ASTD_action. get_fct_name action in
  let args = ASTD_action.get_args action in
  let arg1 = List.nth args 0 in
  let arg2 = List.nth args 1 in
  let var_name1 = ASTD_action.get_variable_name_from_arg arg1 in
  let var_name2 = ASTD_action.get_variable_name_from_arg arg2 in
  let arg1_force_pass_by_value = ASTD_action.is_force_pass_by_value_from_arg arg1 in 
  let arg2_force_pass_by_value = ASTD_action.is_force_pass_by_value_from_arg arg2 in 
  
  assert_equal fct_name "M1.F1";
  assert_equal var_name1 "x";
  assert_equal var_name2 "y";
  assert_equal arg1_force_pass_by_value true;
  assert_equal arg2_force_pass_by_value false

let test_action_of_string_without_args test_ctx =
  let action = 
    match ASTD_action.action_of_string "M1.F1()" with
    | Some a -> a
    | None -> raise (Failure "test failed") in
  let fct_name = ASTD_action. get_fct_name action in
  let args = ASTD_action.get_args action in
  
  assert_equal fct_name "M1.F1";
  assert_equal (List.length args) 0

  let test_action_of_string_empty test_ctx =
    match ASTD_action.action_of_string "" with
    | Some a -> assert_failure "The action is not None"
    | None -> ()

let test_action_of_string_without_args_nor_parenthesis test_ctx =
  let action = 
    match ASTD_action.action_of_string "M1.F1" with
    | Some a -> a
    | None -> raise (Failure "test failed") in
  let fct_name = ASTD_action. get_fct_name action in
  let args = ASTD_action.get_args action in
  
  assert_equal fct_name "M1.F1";
  assert_equal (List.length args) 0

  let test_action_of_string_empty test_ctx =
    match ASTD_action.action_of_string "" with
    | Some a -> assert_failure "The action is not None"
    | None -> ()

let suite = "Test_ASTD_action" >:::
[
  "test_action_of_string_with_args" >:: test_action_of_string_with_args;
  "test_action_of_string_without_args" >:: test_action_of_string_without_args;
  "test_action_of_string_empty" >:: test_action_of_string_empty;
  "test_action_of_string_without_args_nor_parenthesis" >:: test_action_of_string_without_args_nor_parenthesis;
  "test_action_of_string_with_unref_args" >:: test_action_of_string_with_unref_args;
  "test_action_of_string_with_some_unref_args" >:: test_action_of_string_with_some_unref_args;
  "test_action_of_string_with_invalid_var_name" >:: test_action_of_string_with_invalid_var_name
]

let _ =
  run_test_tt_main suite