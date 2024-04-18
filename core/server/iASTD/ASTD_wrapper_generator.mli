val client_build_dir : string
val actions_wrapper_output_path : string
val guards_wrapper_output_path : string
val generate_action : ASTD_action.t -> unit
val generate_guard : ASTD_guard.t -> ASTD_variable.t list -> string -> unit