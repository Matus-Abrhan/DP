(** ASTD arrow module *)

type from_state = string
type to_state = string
type through_state = string
type from_final_state = bool


(** The type {!ASTD_arrow.t} represents the arrows of the automata structure. *)
type t = Local of from_state * to_state * ASTD_transition.t * ASTD_guard.t list * from_final_state * ASTD_action.t option
(**Local arrows*)

|From_sub of from_state * to_state * through_state * ASTD_transition.t * ASTD_guard.t list * from_final_state * ASTD_action.t option
(**Arrows from superior astd, with through_state representing the name of the superior astd of the current one.*)

|To_sub of from_state * to_state * through_state * ASTD_transition.t * ASTD_guard.t list * from_final_state * ASTD_action.t option
(**Arrows to an inferior astd, with through_state representing the name of the astd on the same level as the current state.*)



(** {3 Constructor} *)

val local_arrow :from_state -> to_state-> ASTD_transition.t -> ASTD_guard.t list -> from_final_state -> ASTD_action.t option -> t
val fsub_arrow :from_state -> to_state -> through_state -> ASTD_transition.t -> ASTD_guard.t list -> from_final_state -> ASTD_action.t option ->  t
val tsub_arrow :from_state -> to_state -> through_state -> ASTD_transition.t -> ASTD_guard.t list -> from_final_state -> ASTD_action.t option ->  t



(** {3 Accessors} *)

val get_from : t -> from_state
val get_to : t -> to_state
val get_through : t -> through_state
val get_transition : t -> ASTD_transition.t
val get_guards : t-> ASTD_guard.t list
val get_from_final_state : t-> from_final_state
val get_label_transition : t -> ASTD_label.t
val get_optional_action : t -> ASTD_action.t option

val is_from_sub : t-> bool
val is_to_sub : t-> bool
val is_local : t-> bool

(** {3 Setters} *)
val set_optional_action : t -> ASTD_action.t option -> t

(** {3 Main Functions} *)

(** Evaluates a guard list using the environment. *)
val evaluate_guard : ASTD_environment.t -> (module ASTD_plugin_interfaces.Guard_interface) list -> bool

(** Evaluate the guards on the arrow and compare the event with the transition. *)
val valid_arrow : ASTD_event.t -> ASTD_environment.t -> t -> (module ASTD_plugin_interfaces.Guard_interface) list -> bool


