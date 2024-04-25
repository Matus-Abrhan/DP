
type name = string
type var_type = string

type t = name * var_type * bool

let variable_of name var_type readonly = 
  name, var_type, readonly

let of_strings name var_type : t = variable_of name var_type true (* By default, variables are readonly *)

let get_name variable = let (name, var_type, readonly) = variable in name

let get_type variable = let (name, var_type, readonly) = variable in var_type

let is_readonly variable = let (name, var_type, readonly) = variable in readonly

let set_readonly variable new_readonly =
  let (name, var_type, readonly) = variable in
    variable_of name var_type new_readonly

let variable_name_of_string name : name = name

let compare var1 var2 =
  compare (get_name var1) (get_name var2)