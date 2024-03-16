
type parameter

(**The {!ASTD_transition.t} type refers to the function indicated on each arrow.
  It contains a label and a list of parameters that can be constants ,variables, a joker or a captured variable*)
type t

type capture

val transition : ASTD_label.t -> parameter list -> t

val get_label : t -> ASTD_label.t

val get_params : t -> parameter list

val parameter_from_term : ASTD_term.t -> parameter

val parameter_from_capture : ASTD_variable.t -> parameter

val is_included : ASTD_label.t -> t list -> bool

val compare_action_with_event2 : ASTD_environment.t -> t -> ASTD_event.t -> bool

val is_parameter_a_term : parameter -> bool

val term_from_parameter : parameter -> ASTD_term.t

val is_transition_valid_for_event : ASTD_event.t -> t -> bool

val get_var_names_in_parameters : parameter list -> ASTD_variable.name list

val get_var_names_in_parameters_of_transition : t -> ASTD_variable.name list

val is_variable_name_in_params : ASTD_variable.name -> parameter list -> bool

val get_captured_variables_from_transition : t -> ASTD_variable.t list

val get_captures_from_transition_and_event : t -> ASTD_event.t -> capture list

val get_captured_variable : capture -> ASTD_variable.t

val get_captured_constant : capture -> ASTD_constant.t
