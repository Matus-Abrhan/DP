
type t =   Var of ASTD_variable.name
         | Const of ASTD_constant.t
         | Addition of t*t
         | Multiplication of t*t
         | Substraction of t*t

type params = t list

exception ASTD_not_a_constant of t

(* Iterators over params *)
let foldl f b p = List.fold_left (f:'a -> t -> 'a) b (p:params)
and foldr f p b = List.fold_right (f:t -> 'a -> 'a) (p:params) b
and map = List.map 
and find = List.find
(* --- *)

(* params scanning *)
let exists = List.exists 
and for_all = List.for_all
and for_all2 = List.for_all2

let rec compare_syntax = (=)

let compare_term_with_const t c =
    match t with
    | Const c0 -> c = c0
    | _ -> false

let compare_syntax_of_params p1 p2 =
    try for_all2 compare_syntax p1 p2
    with Invalid_argument _ 
         -> print_endline "ASTD_term.compare_params" ; false 

let compare_params_with_consts p list_of_constants =
    try for_all2 compare_term_with_const p list_of_constants
    with Invalid_argument _ 
         -> print_endline "ASTD_term.compare_params_with_consts" ; false

let is_term_a_variable term = match term with Var var -> true | _ -> false

let term_of_variable_name var_name = Var var_name

let term_of_variable var = term_of_variable_name (ASTD_variable.get_name var)

let variable_name_of_term term = match term with Var var_name -> var_name | _ -> failwith "term is not a variable"

let is_variable_name_in_params variable_name params =
    let params_that_are_variables = List.filter is_term_a_variable params in
    let variables_names_of_params = List.map variable_name_of_term params_that_are_variables in 
        List.mem variable_name variables_names_of_params

let parameters_of_variable_names var_names : params = 
    List.map term_of_variable_name var_names

let parameters_of_variables vars : params = 
    List.map term_of_variable vars

let const_of constant =
    Const constant

let parameters_of_constants constants = 
    List.map const_of constants

let extract_constant_from_term =
    function
    | (Const c) -> c
    | _ as t    -> raise (ASTD_not_a_constant t) 

let extract_constants_from_params =
    map extract_constant_from_term

let check_constants_from = 
    let check_one = function
        | (Const c) -> true
        | _         -> false
    in for_all check_one  

let rec string_of = function 
    | Var var_name -> var_name
    | Const c -> ASTD_constant.string_of c
    | Addition(t1,t2) -> string_of_binary_complex_term " + " t1 t2
    | Multiplication(t1,t2) -> string_of_binary_complex_term " * " t1 t2 
    | Substraction(t1,t2) -> string_of_binary_complex_term " - " t1 t2 
and string_of_binary_complex_term operator_string t1 t2 = 
    "(" ^ (string_of t1) ^ operator_string ^ (string_of t2) ^ ")"

let string_of_params = ASTD_functions.create_string_of_list string_of

let print t = print_string (string_of t)

let print_params = ASTD_functions.create_print_list print



