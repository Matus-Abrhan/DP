type key = ASTD_variable.t
module Bindings = Map.Make(struct type t = key let compare = ASTD_variable.compare end)

type binding = key * ASTD_term.t
type t = ASTD_term.t Bindings.t

exception ASTD_type_mismatch 
exception Variable_not_found of string

let iter fct env = Bindings.iter fct env
let fold = Bindings.fold

let find_value_of environment variable =
  try
    Bindings.find variable environment
  with Not_found -> raise (Variable_not_found (ASTD_variable.get_name variable))

let find_value_from_variable_name environment variable_name = find_value_of environment (ASTD_variable.of_strings variable_name "")

let find_complete_key_infos environment variable_name =
  let key_value_pairs = Bindings.bindings environment in 
  let comparable_variable = (ASTD_variable.of_strings variable_name "") in
  let correct_key_value_pair = List.find (fun (variable, term) -> 0 = ASTD_variable.compare variable comparable_variable) key_value_pairs in
  let key, value = correct_key_value_pair in
    key 

let rec reduce e term = match term with 
    | ASTD_term.Var var_name -> (
        try reduce e (find_value_from_variable_name e var_name)
        with Variable_not_found var_name -> term
      )
    | ASTD_term.Const c -> term
    | ASTD_term.Addition (t1,t2) -> add_terms (reduce e t1) (reduce e t2) 
    | ASTD_term.Multiplication (t1,t2) -> multiply_terms (reduce e t1) (reduce e t2) 
    | ASTD_term.Substraction (t1,t2) -> substract_terms (reduce e t1) (reduce e t2) 
(* not included in mli *)
and apply_binary_operator_between_integer op t1 t2 = 
    let c1 = ASTD_term.extract_constant_from_term t1
    and c2 = ASTD_term.extract_constant_from_term t2
    in match (c1,c2) with
       | (ASTD_constant.Integer i1, ASTD_constant.Integer i2) 
         -> ASTD_term.Const (ASTD_constant.of_int (op i1 i2))
       | _ -> raise ASTD_type_mismatch 
(* not included in mli *)
and add_terms t1 t2 = try apply_binary_operator_between_integer ( + ) t1 t2 
                      with _ -> ASTD_term.Addition (t1,t2)
(* not included in mli *)
and multiply_terms t1 t2 = try apply_binary_operator_between_integer ( * ) t1 t2
                           with _ -> ASTD_term.Multiplication (t1,t2)
(* not included in mli *)
and substract_terms t1 t2 = try apply_binary_operator_between_integer ( - ) t1 t2
                            with _ -> ASTD_term.Substraction (t1,t2)

let rec evaluate e term = ASTD_term.extract_constant_from_term (reduce e term)

let bind v t : binding = (v,t) 
and bind_var v v0 : binding = (v, ASTD_term.Var v0) 
and bind_const v c : binding = (v, ASTD_term.Const c) 

let get_var binding = fst binding
and get_value = snd

let empty : t = Bindings.empty

let add_binding b e =
    let v = get_var b in
    let t = get_value b in
        Bindings.add v (reduce e t) e

let add_all_bindings bindings e =
  List.fold_right add_binding bindings e

let remove variable env =
    Bindings.remove variable env

let remove_all variables env =
  List.fold_right remove variables env

let of_binding b = add_binding b empty

let of_list_of_binding a_list = add_all_bindings a_list empty

let (+>) = add_binding 

let associate_vars_with_params = 
    let associate e v t = add_binding (bind v t) e
    in try List.fold_left2 associate empty 
       with Invalid_argument s -> print_endline "ASTD_environment.associate_vars_with_params" ; 
                                  raise (Invalid_argument ("ASTD_term" ^ s))


let rec increase_call env fct_list = match fct_list with
   |(a,b)::q -> let binding=bind a b in increase_call (add_binding binding env) q
   |[] -> env

(** Creates an environment for the called astd by assigning its parameters from the assignations in the call astd.
  Parameters
    assignations : a list of pairs of (ASTD_variable.name * ASTD_term.t) that contains all the assignations from the call astd's declaration
    env : the current environment
    var_dom_list : a list of pairs of (ASTD_variable.t * ASTD_contant.domain) which contains all the expected parameters of the called astd
  Returns
    new_env : a new environment containing only the parameters of the called astd
 *)
let get_call_env assignations env var_dom_list = 
  let create_binding =
    (fun (variable, domain) -> 
      let assigned_variable_term = List.assoc (ASTD_variable.get_name variable) assignations in 
      let assigned_variable_value = reduce env assigned_variable_term in
        bind variable assigned_variable_value
    ) 
  in
  let bindings = List.map create_binding var_dom_list in
    of_list_of_binding bindings

let is_empty = Bindings.is_empty

let is_not_empty e = not (is_empty e)

let symbol_of_binding = ":=" 

(* let print_binding b = print_string (get_var b); 
                      print_string symbol_of_binding ; 
                      ASTD_term.print (get_value b) *)

(*let print = 
    create_print_container iter print_binding "([" "])" ";"*)

(* let string_of_binding b = 
    let string_of_var = get_var b
    and string_of_value = ASTD_term.string_of (get_value b)
    in string_of_var ^ symbol_of_binding ^ string_of_value *)

(*let string_of = 
    create_string_of_container fold string_of_binding "([" "])" ";"*)

let compare_term_with_const_in2 env term constant = 
  constant = ASTD_constant.FreeConst
  ||
  (
    match term with
    | ASTD_term.Var (a) -> ASTD_term.compare_term_with_const (reduce env term) constant
    | ASTD_term.Const (a) ->
        a = ASTD_constant.FreeConst
        ||
        ASTD_term.compare_term_with_const term constant
    | _ -> failwith "addition, multiplication, .... not implemented"
  )

let compare_params_with_consts_in2 env t_list c_list =
    try ASTD_term.for_all2 (compare_term_with_const_in2 env) t_list c_list
    with Invalid_argument _ -> false

(** Updates env1 to add or update all its bindings to match those in env2.
    Note : All non-conflincting bindings will be present in the resulting env. The conflicting bindings will have the values they have in env2 *)
let merge env1 env2 =
  Bindings.merge 
  (fun var optional_term_in_env1 optional_term_in_env2 ->
    match optional_term_in_env2 with
    | Some term -> optional_term_in_env2
    | None -> optional_term_in_env1
  )
  env1
  env2

(** Removes the attributes from the environment and return their values
  Params:
    instances : list of attribute instances that should be removed from the environment and from which we want the new values
    env : environment that contains the bindings of the instances

  Returns:
    updated_instances : list of attribute instances whose values comes from the environment
    env_without_attributes : environment with attribute instances' bindings removed
  *)
let rec extract_attributes_from_env (instances : ASTD_attribute.instance list) env =
  match instances with
  | instance::remaining_instances -> 
      let variable = ASTD_attribute.variable_of_instance instance in
      let new_value_of_attribute = ASTD_term.extract_constant_from_term (find_value_of env variable) in
      let updated_instance = ASTD_attribute.update_instance_value instance new_value_of_attribute in
      let new_env = remove variable env in
      let (updated_instances, env_without_attributes) = extract_attributes_from_env remaining_instances new_env in
        (updated_instance :: updated_instances, env_without_attributes)
  | [] -> ([], env)

(** Add attribute instances to the environment *)
let add_attributes_to_env (instances : ASTD_attribute.instance list) env =
  List.fold_right 
    (fun (instance : ASTD_attribute.instance) env -> 
      let variable = ASTD_attribute.variable_of_instance instance in
      let value_constant = ASTD_attribute.value_of_instance instance in
      let bind_env = bind variable (ASTD_term.const_of value_constant) in
      add_binding bind_env env
    )
    instances
    env

(** Class that handles typed interaction with the environment knowing the variable name.
  Used in context where knowledge of the environment is limited, like the client code wrapper that needs values from environment's variables.
  Changes to this accessor should be done very carefully. Method names are hard-coded as strings in other files and need to remain valid. *)
class environment_accessor (p_env : t) = object
  val mutable env = p_env

  method get_int (variable_name : string) : int =
    let term = find_value_from_variable_name env variable_name in
    let constant = ASTD_term.extract_constant_from_term term in
      ASTD_constant.int_of constant
  
  method update_int (variable_name : string) (new_value : int) : unit =
    let constant = ASTD_constant.of_int new_value in
    let binding = bind_const (ASTD_variable.variable_of variable_name "int" false) constant in
      env <- add_binding binding env

  method get_string (variable_name : string) : string =
    let term = find_value_from_variable_name env variable_name in
    let constant = ASTD_term.extract_constant_from_term term in
      ASTD_constant.string_of constant
  
  method update_string (variable_name : string) (new_value : string) : unit =
    let constant = ASTD_constant.of_string new_value in
    let binding = bind_const (ASTD_variable.variable_of variable_name "string" false) constant in
      env <- add_binding binding env
      
  method get_env =
    env
end
