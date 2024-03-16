
(** Variable name of the attribute and its initial value (as a typed constant) *)
type value = ASTD_constant.t

type t = ASTD_variable.t * value

(** Attribute and its value *)
type instance = t * value

val attribute_of : ASTD_variable.t -> value -> t

val init : t -> instance

val init_all : t list -> instance list 

val attribute_of_instance : instance -> t

val variable_of_attribute : t -> ASTD_variable.t

val variable_of_instance : instance -> ASTD_variable.t

val value_of_instance : instance -> value

val init_value_of_instance : instance -> value

val init_value_of_attribute : t -> value

val update_instance_value : instance -> value -> instance