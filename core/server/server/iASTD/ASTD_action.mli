
type force_pass_by_value = bool
type arg = ASTD_variable.t * force_pass_by_value

type t = int * string * arg list

val action_of : int -> string -> arg list -> t

val action_of_auto_id : string -> arg list -> t

val arg_of_variable : ASTD_variable.t -> arg

val get_id : t -> int

val get_fct_name : t -> string

val get_args : t -> arg list

val get_variable_name_from_arg : arg -> ASTD_variable.name

val get_variable_type_from_arg : arg -> ASTD_variable.var_type

val is_force_pass_by_value_from_arg : arg -> force_pass_by_value

val is_readonly_from_arg : arg -> bool

val variable_of_arg : arg -> ASTD_variable.t

val variables_of_args : arg list -> ASTD_variable.t list

val update_args_of_action : t -> arg list -> t

val update_variable_of_arg : arg -> ASTD_variable.t -> arg

val update_force_pass_by_value_of_arg : arg -> force_pass_by_value -> arg

val action_of_string : string -> t option