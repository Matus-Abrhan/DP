type from_state = string
type to_state = string
type through_state = string
type from_final_state = bool


type t = Local of from_state * to_state * ASTD_transition.t * ASTD_guard.t list * from_final_state * ASTD_action.t option
       | From_sub of from_state * to_state * through_state * ASTD_transition.t * ASTD_guard.t list * from_final_state * ASTD_action.t option
       | To_sub of from_state * to_state * through_state * ASTD_transition.t * ASTD_guard.t list * from_final_state * ASTD_action.t option


let local_arrow from_state to_state transition guards from_final_state optional_action =           
  Local (from_state, to_state, transition, guards, from_final_state, optional_action)
let fsub_arrow from_state to_state through_state transition guards from_final_state optional_action =           
  From_sub (from_state, to_state, through_state, transition, guards, from_final_state, optional_action)
let tsub_arrow from_state to_state through_state transition guards from_final_state optional_action =           
  To_sub (from_state, to_state, through_state, transition, guards, from_final_state, optional_action)


let is_from_sub a = match a with
  | From_sub(_) -> true
  | _ -> false
let is_to_sub a = match a with
  | To_sub(_) -> true
  | _ -> false
let is_local a = match a with
  | Local(_) -> true
  | _ -> false




let get_from arrow = match arrow with
     | Local ( from,_,_,_,_,_) -> from
     | From_sub ( from,_,_,_,_,_,_) -> from
     | To_sub ( from,_,_,_,_,_,_) -> from
let get_to arrow = match arrow with
     | Local ( _,dest,_,_,_,_) -> dest
     | From_sub ( _,dest,_,_,_,_,_) -> dest
     | To_sub ( _,dest,_,_,_,_,_) -> dest
let get_through arrow = match arrow with
     | From_sub ( _,_,through,_,_,_,_) -> through
     | To_sub ( _,_,through,_,_,_,_) -> through
     | _ -> failwith "no throught for local transitions"
let get_transition arrow = match arrow with
     | Local ( _,_,transitions,_,_,_) -> transitions
     | From_sub ( _,_,_,transitions,_,_,_) -> transitions
     | To_sub ( _,_,_,transitions,_,_,_) -> transitions
let get_guards arrow = match arrow with
     | Local ( _,_,_,guards,_,_) -> guards
     | From_sub ( _,_,_,_,guards,_,_) -> guards
     | To_sub ( _,_,_,_,guards,_,_) -> guards
let get_from_final_state arrow = match arrow with
     | Local ( _,_,_,_,should_be_final,_) -> should_be_final
     | From_sub ( _,_,_,_,_,should_be_final,_) -> should_be_final
     | To_sub ( _,_,_,_,_,should_be_final,_) -> should_be_final
let get_label_transition arrow =   ASTD_transition.get_label(get_transition arrow)

let get_optional_action arrow = match arrow with
  | Local (_,_,_,_,_, action) -> action
  | From_sub (_,_,_,_,_,_,action) -> action
  | To_sub (_,_,_,_,_,_,action) -> action

let set_optional_action arrow new_optional_action = 
  match arrow with
  | Local (from_state, to_state, transition, guards, from_final_state, optional_action) -> 
      Local (from_state, to_state, transition, guards, from_final_state, new_optional_action)
  | From_sub (from_state, to_state, through_state, transition, guards, from_final_state, optional_action) -> 
      From_sub (from_state, to_state, through_state, transition, guards, from_final_state, new_optional_action)
  | To_sub (from_state, to_state, through_state, transition, guards, from_final_state, optional_action) ->
      To_sub (from_state, to_state, through_state, transition, guards, from_final_state, new_optional_action)

(** Evaluates a guard list using the environment.
  If the list is empty, the guard is considered to evaluate to true. 
  All guard modules must evaluate to true, otherwise we consider the guard false 
  Parameters
    env : environment
    guard_modules : list of guard modules to evaluate
  Returns
    success : true if all the guard modules evaluated to true, false otherwise
  *)
let evaluate_guard env (guard_modules : (module ASTD_plugin_interfaces.Guard_interface) list) = 
  List.for_all (fun guard_module -> ASTD_guard.evaluate guard_module env) guard_modules

let valid_arrow event env arrow (guards_module : (module ASTD_plugin_interfaces.Guard_interface) list) = 
  (ASTD_transition.compare_action_with_event2 env (get_transition arrow) event)
  && 
  (evaluate_guard env guards_module)
