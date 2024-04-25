
type name = string
type var_type = string

type t = name * var_type * bool

(** {2 Constructor} *)

val variable_of : name -> var_type -> bool -> t
val of_strings : name -> var_type -> t
val variable_name_of_string : string -> name

(** {2 Accessors} *)
val get_name : t -> name
val get_type : t -> var_type
val is_readonly : t -> bool

(** {2 Setters} *)
val set_readonly : t -> bool -> t

(** {2 Comparor} *)
val compare : t -> t -> int