(** ASTD environment module *)

type key = ASTD_variable.t
module Bindings : Map.S with type key = key

type binding = key * ASTD_term.t
type t = ASTD_term.t Bindings.t

exception Variable_not_found of string

(** {2 Bindings} *)

val symbol_of_binding : string

(** {3 Constructor} *)

val bind : key -> ASTD_term.t -> binding
val bind_var : key -> ASTD_variable.name -> binding
val bind_const : key -> ASTD_constant.t -> binding

(** {2 Environments} *)

(** {3 Constructors} *)

val empty : t
val add_binding : binding -> t -> t
val add_all_bindings : binding list -> t -> t
val remove : key -> t -> t
val remove_all : key list -> t -> t
val of_binding : binding -> t
val of_list_of_binding : binding list -> t
val ( +> ) : binding -> t -> t
val associate_vars_with_params : key list -> ASTD_term.params -> t
val increase_call : t -> (key * ASTD_term.t) list -> t  
val get_call_env : (ASTD_variable.name * ASTD_term.t) list -> ASTD_term.t Bindings.t -> (ASTD_variable.t * ASTD_constant.domain) list -> t

val iter : (Bindings.key -> ASTD_term.t -> unit) -> t -> unit
val find_value_from_variable_name : t -> ASTD_variable.name -> ASTD_term.t
(** {!ASTD_environment}[.find_value_of env var] find the {!ASTD_term}
    of the variable [var] in the environment [env].
    Raise {!Not_found} if there is no value associated with [var]
    in the environment [env].
    *)
val find_value_of : t -> key -> ASTD_term.t
val find_complete_key_infos : t -> ASTD_variable.name -> key


(** {3 Predicates} *)

val is_empty : t -> bool
val is_not_empty : t -> bool

(** {2 Interaction with terms and parameters} *)
val merge : t -> t -> t

(** {3 Evaluation of a term in an environment} *)

val reduce : t -> ASTD_term.t -> ASTD_term.t
val evaluate : t -> ASTD_term.t -> ASTD_constant.t

(** {3 Comparison of terms and parameters in an environment} *)

val compare_term_with_const_in2 : 
    t -> ASTD_term.t -> ASTD_constant.t -> bool

val compare_params_with_consts_in2 : 
    t -> ASTD_term.params -> ASTD_constant.t list -> bool

val extract_attributes_from_env : ASTD_attribute.instance list -> ASTD_term.t Bindings.t -> ASTD_attribute.instance list * ASTD_term.t Bindings.t

val add_attributes_to_env : ASTD_attribute.instance list -> ASTD_term.t Bindings.t -> ASTD_term.t Bindings.t

class environment_accessor : t -> object
  val mutable env : t
  method get_int : string -> int
  method update_int : string -> int -> unit
  method get_string : string -> string
  method update_string : string -> string -> unit
  method get_env : t
end