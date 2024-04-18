
val register_action : int -> (module ASTD_plugin_interfaces.Action_interface) -> unit
val register_guard : int -> (module ASTD_plugin_interfaces.Guard_interface) -> unit
val add_import : string -> unit
val build_all : string -> unit