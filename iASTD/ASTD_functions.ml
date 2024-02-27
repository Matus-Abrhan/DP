
let compose f g = function x -> f (g x)

let switch_args f = (fun x -> fun y -> f y x)

let gen_int_list n = 
    let rec aux n l = if (n = 0)
                      then l
                      else aux (n-1) (n::l)
    in aux n []

let print_space n = print_newline () ; for j=1 to n do print_string " " done

let rec filter_not liste predicat = 
    let not_pred x = not (predicat x)
    in List.filter not_pred liste 

let create_print_container container_iter print_element left right sep = 
    function container ->
        let first = ref true
        in let print_each e = if (!first) 
                              then first := false
                              else print_string sep ;
                              print_element e
        in begin
           print_string left;
           container_iter print_each container ;
           print_string right 
           end

let create_print_set iter print_element = 
    create_print_container iter print_element "{" "}" ","

let create_print_list print_element = 
    create_print_container List.iter print_element "(" ")" ","

let create_string_of_container container_fold string_of_element left right sep = 
    function container ->
        let first = ref true in 
        let add_after_first sep  = if !first then (first := false ; "") else sep in
        let string_of_one_element e = (add_after_first sep) ^ (string_of_element e) in 
        let add_one_elt_after e s = s ^ (string_of_one_element e) in
        let all_elements = container_fold add_one_elt_after container ""
        in left ^ all_elements ^ right

let create_string_of_set fold string_of_element = 
    create_string_of_container fold string_of_element "{" "}" ","

let create_string_of_list string_of_element = 
    let list_fold f l b = List.fold_left (fun x -> fun y -> f y x) b l
    in
        create_string_of_container list_fold string_of_element "(" ")" ","

(** Removes duplicated elements from a list, starting from the left (so deleting the following occurences) *)
let remove_duplicates_from_left xs = 
  let cons_uniq xs x = if List.mem x xs then xs else x :: xs in
    List.rev (List.fold_left cons_uniq [] xs)

(** Checks if the optional has a value *)
let optional_has_value optional =
  match optional with
  | Some x -> true
  | None -> false

(** Gets the value of the optional *)
let get_optional_value optional =
  match optional with
  | Some x -> x
  | None -> failwith "optional has no value"

(** Returns a list of the values of the optionals which have values in them. *)
let get_values_of_all_valid_optionals optionals =
  List.map get_optional_value (List.filter optional_has_value optionals)

(** Checks if a list is empty in O(1) *)
let is_list_empty list =
  try ignore(List.hd list); false with _ -> true

(** Find optional from List.find_opt *)
let rec find_opt f list =
  if is_list_empty list then
    None
  else if f (List.hd list) then
    Some (List.hd list)
  else 
    find_opt f (List.tl list)

(** Unique id generator.
    @return The next unique id. *)
let get_unique_id = 
    let next_id = ref 0 in
        fun () -> let given_id = !next_id in next_id := given_id + 1; given_id

(** Intersect elements of the first list with the elements of the second list.
    @return A list of common elements from the two specified lists *)
let intersection l1 l2 = 
    List.fold_left 
        (fun common_elements elem -> if List.mem elem l2 then (elem::common_elements) else common_elements) 
        [] 
        l1

(** Replace specified filename extension with the new one specified. 
    @return The filename with the new extension. *)
let replace_file_name_ext_with file_name new_ext = 
    (Filename.remove_extension file_name) ^ new_ext

(* Sys commands *)

(** Read all lines from the specified file. 
    @return List of all lines in the file. *)
let read_lines_from_file file_path = 
    let lines = ref [] in
    let chan = open_in file_path in
    try
        while true; do
        lines := input_line chan :: !lines
        done; !lines
    with End_of_file ->
        close_in chan;
        List.rev !lines

(** Append content to the end of the specified file.
    @note The file will be created if it does not exist. *)
let append_to_file file_name content =
    let channel = open_out_gen [Open_creat; Open_append] 0o777 file_name in
    output_string channel content;
    close_out channel

(** Create a new directory with the specified name if it does not exist. *)
let create_new_dir_if_not_exist dir_name = 
    if not(Sys.file_exists dir_name) then
        Unix.mkdir dir_name 0o777

(** Copy the content to the destination. 
    @return Exit code. *)
let copy from dest = 
    Sys.command ("cp " ^ from ^ " " ^ dest)

(** Copy the content to the destination. 
    @raise If the copy fail. *)
let raise_copy from dest = 
    let exit_code = Sys.command ("cp " ^ from ^ " " ^ dest) in
    if exit_code <> 0 then
        failwith ("Copy of " ^ from ^ " to " ^ dest ^ " failed.")

(** Remove all files from specified directory. 
    @return Exit code. *)
let remove_all_files_from_dir dir_path = 
    Sys.command ("rm -rf " ^ Filename.concat dir_path "*")
