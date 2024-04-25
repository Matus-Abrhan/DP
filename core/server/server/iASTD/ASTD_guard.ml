type t = int * string

let guard_of id file_name : t =
  id, file_name

let guard_of_auto_id file_name : t =
  guard_of (ASTD_functions.get_unique_id ()) file_name

let get_id guard =
  let id, fct_name = guard in id

let get_file_name guard =
  let id, file_name = guard in file_name

let guard_of_string file_name =
  guard_of_auto_id file_name

let evaluate guard_module env =
  let module M = (val guard_module : ASTD_plugin_interfaces.Guard_interface) in
  let env_acc = new ASTD_environment.environment_accessor env in
    try
      M.execute_guard env_acc
    with exn -> print_endline; (*print_endline ("Error evaluating guard : " ^ (Printexc.to_string exn))*) false