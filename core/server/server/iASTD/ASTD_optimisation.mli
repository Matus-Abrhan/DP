type astd_name = string;;

type path = astd_name list

type dependency = (path * ASTD_variable.name list * ASTD_variable.name * ASTD_label.t list * ASTD_label.t list) 

type dep_path = Dep_path of (ASTD_variable.name * dependency * dep_path list)

type optimisation = (ASTD_label.t * path * ASTD_variable.name *dep_path)


val debug_on : unit -> unit


val register_kappa : dependency -> ASTD_term.t list -> ASTD_term.t ->unit 


val get_kappa : dependency -> ASTD_term.t list -> ASTD_term.t





val automatic_gestion_of_kappa_values : ASTD_environment.t ->ASTD_label.t -> dependency list-> ASTD_term.t ->((dependency*(ASTD_term.t list))*ASTD_term.t*bool) list



val apply_each_mod : ((dependency*(ASTD_term.t list))*ASTD_term.t*bool) list->unit

