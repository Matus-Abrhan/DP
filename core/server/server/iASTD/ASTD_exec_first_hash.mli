
val debug_on : unit -> unit

(** {2 Main Functions} *)

(**Returns the initial state of an ASTD*)
val init : ASTD_astd.t -> ASTD_state.t

(**Executes an event list*)
val execute_event_list: int->ASTD_state.t -> ASTD_astd.t -> ASTD_event.t list -> ASTD_state.t

(** {3 Printers} *)
val print : ASTD_state.t -> ASTD_astd.t -> string -> string-> unit
