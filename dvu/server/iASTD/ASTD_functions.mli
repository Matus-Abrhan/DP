(** General functions module *)

val compose : ('b -> 'c) -> ('a -> 'b) -> 'a -> 'c

val switch_args : ('a -> 'b -> 'c) -> ('b -> 'a -> 'c)

val gen_int_list : int -> int list

val filter_not : 'a list -> ('a -> bool) -> 'a list

val print_space : int -> unit

(** {2 Print container} *)

val create_print_container : 
  (('a -> 'b) -> 'c -> 'd) -> 
  ('a -> 'b) -> string -> string -> string -> 'c -> unit

val create_print_set : (('a -> 'b) -> 'c -> 'd) -> ('a -> 'b) -> 'c -> unit

val create_print_list : ('a -> unit) -> 'a list -> unit

(** {2 String of container} *)

val create_string_of_container :
  (('a -> string -> string) -> 'b -> string -> string) -> 
  ('a -> string) -> string -> string -> string -> 'b -> string

val create_string_of_set :
  (('a -> string -> string) -> 'b -> string -> string) ->
  ('a -> string) -> 'b -> string

val create_string_of_list : ('a -> string) -> 'a list -> string

val remove_duplicates_from_left : 'a list -> 'a list

val optional_has_value : 'a option -> bool

val get_optional_value : 'a option -> 'a

val get_values_of_all_valid_optionals : 'a option list -> 'a list

val is_list_empty : 'a list -> bool

val find_opt : ('a -> bool) -> 'a list -> 'a option

val get_unique_id : unit -> int 

val intersection : 'a list -> 'a list -> 'a list

val replace_file_name_ext_with : string -> string -> string

(** {2 Sys Commands} *)
val read_lines_from_file : string -> string list

val append_to_file : string -> string -> unit

val create_new_dir_if_not_exist : string -> unit 

val copy : string -> string -> int

val raise_copy : string -> string -> unit

val remove_all_files_from_dir : string -> int
