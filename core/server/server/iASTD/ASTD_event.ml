
type t = Event of ASTD_label.t * ASTD_constant.t list 

(* Event *)

let event label consts = Event (label,consts)

let string_of_event (Event (label,consts)) = 
  (ASTD_label.string_of label) ^ (ASTD_constant.string_of_list consts)

let get_const (Event (label,consts)) = consts
 
let get_data (Event (label,consts)) = (label,consts)

let get_label (Event (label,consts)) = label

let set_label new_label (Event (label,consts)) = Event (new_label, consts)

let set_consts new_consts (Event (label,consts)) = Event (label, new_consts)

let print_event e = print_string (string_of_event e)

let print_event_ln e = print_endline (string_of_event e)
