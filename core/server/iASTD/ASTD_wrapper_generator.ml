let client_build_dir = "_build_client"
let _ = ASTD_functions.create_new_dir_if_not_exist client_build_dir
let actions_wrapper_output_path = Filename.concat client_build_dir "actions_wrapper.ml"
let guards_wrapper_output_path = Filename.concat client_build_dir "guards_wrapper.ml"

(** Generate unique names for the function names to avoid duplicates. *)
let get_unique_name_generator () =
  let init_unique_name_generator first_index = (
    let index = ref first_index in
      let generate_unique_name base_name = index := !index + 1; base_name ^ "_" ^ (string_of_int !index) in
        generate_unique_name
  ) in init_unique_name_generator 0
    
(** Generate getter for the environment accessor depending on the type of the variable. *)
let generate_getter_function_for_type type_name = 
  match type_name with
  | "int" -> "get_int"
  | "string" -> "get_string"
  | _ -> failwith ("No getter function for type : " ^ type_name)

(** Generate setter for the environment accessor depending on the type of the variable. *)
let generate_setter_function_for_type type_name = 
  match type_name with
  | "int" -> "update_int"
  | "string" -> "update_string"
  | _ -> failwith ("No setter function for type : " ^ type_name)

(** Generate code to get argument (variables used in actions or guards) in the environment. 
    @note The variable is passed in ref only if its not read-only AND not force pass by value. *)
let generate_var unique_name_generator arg = 
  let var_name = ASTD_action.get_variable_name_from_arg arg in
  let var_type = ASTD_action.get_variable_type_from_arg arg in
  let var_is_readonly = ASTD_action.is_readonly_from_arg arg in
  let var_is_force_pass_by_value = ASTD_action.is_force_pass_by_value_from_arg arg in
  let unique_var_name = unique_name_generator var_name in

  let getter = generate_getter_function_for_type var_type in

  if var_is_readonly || var_is_force_pass_by_value
  then "  let " ^ unique_var_name ^ " = env_acc#" ^ getter ^ " \"" ^ var_name ^ "\" in \n"
  else "  let " ^ unique_var_name ^ " = ref(env_acc#" ^ getter ^ " \"" ^ var_name ^ "\") in \n"

(** Generate code to get all arguments (variables used in actions or guards) in the environment. *)
let generate_vars args unique_name_generator =
  String.concat "" (List.map (generate_var unique_name_generator) args)

(** Generate code to update the environment variable with the environment accessor. 
    @note The variable is only updated if its not read-only AND not force pass by value. *)
let generate_var_update unique_name_generator arg =
  let var_name = ASTD_action.get_variable_name_from_arg arg in
  let var_type = ASTD_action.get_variable_type_from_arg arg in
  let var_is_read_only = ASTD_action.is_readonly_from_arg arg in
  let var_is_force_pass_by_value = ASTD_action.is_force_pass_by_value_from_arg arg in
  let unique_var_name = unique_name_generator var_name in

  let setter = generate_setter_function_for_type var_type in

  if var_is_read_only || var_is_force_pass_by_value
  then ""
  else "    env_acc#" ^ setter ^ " \"" ^ var_name ^ "\" !" ^ unique_var_name ^ "; \n"

(** Generate code to update all environment variables. *)
let generate_vars_update args unique_name_generator = 
  String.concat "" (List.map (generate_var_update unique_name_generator) args)

(* ACTIONS *)

(** Generate code to call the client function.
    @return Formatted string of the function call. *)
let generate_client_function_call fct_name args unique_name_generator =
  let arguments = List.map ASTD_action.get_variable_name_from_arg args in
  let uniquely_names_arguments = List.map unique_name_generator arguments in
  let arguments_string = if (List.length args) <> 0 then String.concat " " uniquely_names_arguments else "()" in
    "    ignore(" ^ fct_name ^ " " ^ arguments_string ^ ");\n"

(** Generate code for the specified action and append the content to the `actions_wrapper.ml` file. *)
let generate_action action = 
  let id = string_of_int (ASTD_action.get_id action) in
  let fct_name = ASTD_action.get_fct_name action in
  let args = ASTD_action.get_args action in
  let content =
    "module M" ^ id ^ " : ASTD_plugin_interfaces.Action_interface = \n" ^
    "struct \n" ^
    "let execute_action (env_acc : ASTD_environment.environment_accessor) : ASTD_environment.environment_accessor = \n" ^
    generate_vars args (get_unique_name_generator ()) ^
    generate_client_function_call fct_name args (get_unique_name_generator ()) ^
    generate_vars_update args (get_unique_name_generator ()) ^
    "    env_acc \n" ^
    "end \n" ^ 
    "let () = ASTD_plugin_builder.register_action " ^ id ^ " (module M" ^ id ^ ") \n\n" in

    ASTD_functions.append_to_file actions_wrapper_output_path content

(* GUARDS *)

(** Get the content of the specified guard.
    @return Formatted content of the guard. *)
let generate_guard_call guard_file_path = 
  "    " ^ (String.concat "\n    " (ASTD_functions.read_lines_from_file guard_file_path)) ^ "\n"

(** Generate code for the specified guard with vars and append the content to the `guards_wrapper.ml` file. *)
let generate_guard guard vars spec_path = 
  let ro_vars = List.map (fun var -> ASTD_variable.set_readonly var true) vars in
  let args = List.map ASTD_action.arg_of_variable ro_vars in
  let id = string_of_int(ASTD_guard.get_id guard) in
  let guard_file_name = ASTD_guard.get_file_name guard in
  let content = 
    "module G" ^ id ^ " : ASTD_plugin_interfaces.Guard_interface = \n" ^
    "struct \n" ^
    "let [@ocaml.warning \"-26\"] execute_guard (env_acc : ASTD_environment.environment_accessor) : bool = \n" ^
    generate_vars args (fun x -> x) ^
    generate_guard_call (Filename.concat spec_path guard_file_name) ^
    "end \n" ^
    "let () = ASTD_plugin_builder.register_guard " ^ id ^ " (module G" ^ id ^ ") \n\n" in

    ASTD_functions.append_to_file guards_wrapper_output_path content