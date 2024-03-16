
type value = ASTD_constant.t
type t = ASTD_variable.t * value

type instance = t * value

let attribute_of variable constant : t = (variable, constant)

let init (attribute : t) : instance =
  let (variable, constant) = attribute in
    (attribute, constant)

let init_all (attributes : t list) : instance list = 
  List.map init attributes

let attribute_of_instance (attribute, value_constant) = attribute

let variable_of_attribute (variable, init_constant) = variable

let variable_of_instance instance =
  variable_of_attribute (attribute_of_instance instance)

let value_of_instance (attribute, value_constant) = value_constant

let init_value_of_attribute (variable, init_constant) = init_constant

let init_value_of_instance instance = init_value_of_attribute (attribute_of_instance instance)

let update_instance_value instance new_value = ((attribute_of_instance instance), new_value)