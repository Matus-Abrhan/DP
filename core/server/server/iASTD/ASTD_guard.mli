type t = int * string

val guard_of : int -> string -> t

val guard_of_auto_id : string -> t

val get_id : t -> int

val get_file_name : t -> string

val guard_of_string : string -> t

val evaluate : (module ASTD_plugin_interfaces.Guard_interface) -> ASTD_environment.t -> bool