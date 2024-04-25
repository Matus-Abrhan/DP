
type parameter =
  | Term of ASTD_term.t
  | Captured_variable of ASTD_variable.t

type t = Transition of ASTD_label.t * parameter list

type capture = ASTD_variable.t * ASTD_constant.t

let transition label parameters = Transition (label,parameters)

let get_label (Transition (label, _)) = label

let get_params (Transition(_, parameters)) = parameters

let parameter_from_term term : parameter =
  Term (term)

let parameter_from_capture variable : parameter =
  Captured_variable (variable)

let is_parameter_a_term param =
  match param with Term (term) -> true | _ -> false

let is_parameter_a_capture param =
  match param with Captured_variable (variable) -> true | _ -> false

let term_from_parameter parameter =
  match parameter with
  | Term term -> term
  | _ -> failwith "Parameter is not a term"

let captured_variable_from_parameter parameter =
  match parameter with
  | Captured_variable variable -> variable
  | _ -> failwith "Parameter is not a variable"

let rec is_included label trans_list =
  match trans_list with
  | a::q -> (label = get_label a) || (is_included label q)
  | [] -> false

let compare_parameter_with_const_from_event env parameter const =
  if is_parameter_a_term parameter then 
    ASTD_environment.compare_term_with_const_in2 env (term_from_parameter parameter) const
  else
    let variable = captured_variable_from_parameter parameter in
      ASTD_constant.get_type_name const = ASTD_variable.get_type variable

let compare_action_with_event2 env transition event  = 
  (get_label transition) = ASTD_event.get_label event
  && 
  List.for_all2 (compare_parameter_with_const_from_event env) (get_params transition) (ASTD_event.get_const event)

(** Basic validations of a transition for an event: Checks that label and params count match. *)
let is_transition_valid_for_event event transition = 
  let transition_label = get_label transition in
  let event_label = ASTD_event.get_label event in
  let transition_nb_of_params = List.length (get_params transition) in
  let event_nb_of_params = List.length (ASTD_event.get_const event) in
    transition_label = event_label && transition_nb_of_params = event_nb_of_params

let get_var_names_in_parameters parameters =
  let params_which_are_terms = List.filter is_parameter_a_term parameters in
  let terms = List.map term_from_parameter params_which_are_terms in
  let terms_which_are_variables = List.filter ASTD_term.is_term_a_variable terms in
  let variable_names = List.map ASTD_term.variable_name_of_term terms_which_are_variables in
    variable_names

let get_var_names_in_parameters_of_transition transition =
  let parameters = get_params transition in 
    get_var_names_in_parameters parameters

let is_variable_name_in_params variable_name parameters =
  List.mem variable_name (get_var_names_in_parameters parameters)

let capture_of variable constant : capture =
  (variable, constant)

let get_captured_variables_from_transition transition = 
  let paramaters_which_are_captured_variables = List.filter is_parameter_a_capture (get_params transition) in
    List.map captured_variable_from_parameter paramaters_which_are_captured_variables

let get_captures_from_transition_and_event transition event =
  let transition_parameters = get_params transition in
  let event_constants = ASTD_event.get_const event in 
  let optional_captures =
    List.map2
    (
      fun parameter constant ->
        if is_parameter_a_capture parameter then
          Some (capture_of (captured_variable_from_parameter parameter) constant)
        else
          None
    )
    transition_parameters
    event_constants
  in
    ASTD_functions.get_values_of_all_valid_optionals optional_captures 

let get_captured_variable capture =
  let variable, constant = capture in variable

let get_captured_constant capture =
  let variable, constant = capture in constant
