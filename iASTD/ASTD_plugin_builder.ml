(** Register action globally. Used by each action in the actions wrapper to register itself. *)
let register_action id action = 
  ASTD_astd.register_action id action

(** Register guard globally. Used by each guard in the guards wrapper to register itself. *)
let register_guard id guard = 
  ASTD_astd.register_guard id guard

let imports_list = ref []

(** Add import to the current list of imports. *)
let add_import (import : string) = 
  imports_list:= import :: !imports_list

(** Load the given file and link it with the running program with Dynlink. 
    @raise Dynlink errors. *)
let load_plugin plugin_file_name = 
  if Sys.file_exists plugin_file_name then
		try
			Dynlink.loadfile plugin_file_name
		with 
    | Dynlink.Error e -> print_endline ("Error while loading plugin " ^ plugin_file_name ^ " : " ^ Dynlink.error_message e)
	else 
		failwith ("Plugin file does not exist : " ^ plugin_file_name)

let build_dir = "_build"

(** Compile the client code in the client build directory if its not already compiled.
    Otherwise, copy the already compiled files to the client build directory.
    Compiler : 
    Bytcode -> ocamlc   -c      (produce a .cmo file).
    Native  -> ocamlopt -shared (produce a .cmxs file). 
    @raise Copy and compilation errors. *)
let compile_plugin file_path = 
  let client_build_dir = ASTD_wrapper_generator.client_build_dir in
  let file_path_without_ext = Filename.remove_extension file_path in
  let file_name = Filename.basename file_path in
  let compiled_ext = if Dynlink.is_native then ".cmxs" else ".cmo" in
  let compiled_file_name = ASTD_functions.replace_file_name_ext_with file_name compiled_ext in
  let compiled_file_path = Filename.concat client_build_dir compiled_file_name in

    if (Filename.extension file_name) = ".ml" then ( (* Not compiled client code *) 
      (* 1. Copy the client code to the client build directory *)
      if Filename.dirname file_path <> client_build_dir then 
        ASTD_functions.raise_copy file_path client_build_dir;
      
      (* 2. Compile the client code *)
      let build_command = if Dynlink.is_native then "ocamlopt -shared" else "ocamlc -c" in
      let compile_command = build_command ^ " -g -o " ^ compiled_file_name ^ " " ^ file_name ^ " -I "^ (Filename.concat ".." build_dir) in
      
      Sys.chdir client_build_dir;
      if Sys.command compile_command <> 0 then failwith ("Error : Compilation of " ^ file_path ^ " failed.");
      Sys.chdir("..");

    ) else ( (* Already compiled client code *)
      (* Note : 
       In native mode, we need .mli .cmxs and .cmx files to load the compiled code properly with dynlink.
       In bytecode mode, we need .mli and .cmo files to load the compiled code properly with dynlink.
      *)
      (* 1. Copy the compiled client code to the client build directory *)
      if Dynlink.is_native then
        ASTD_functions.raise_copy (file_path_without_ext ^ ".cmx") client_build_dir;
      ASTD_functions.raise_copy (file_path_without_ext ^ ".cmi") client_build_dir;
      ASTD_functions.raise_copy (file_path_without_ext ^ compiled_ext) client_build_dir;
    );

    compiled_file_path

(** Build (compile & load) all client code dynamically. *)
let build_all spec_path = 
  (* Build client code *)
  List.iter (fun import_path -> 
    let aboslute_path = if (Filename.is_relative import_path) then (Filename.concat spec_path import_path) else import_path in
      load_plugin (compile_plugin aboslute_path)
  )
  (List.rev !imports_list);

  (* Build the actions wrapper *)
  if Sys.file_exists ASTD_wrapper_generator.actions_wrapper_output_path then
    load_plugin (compile_plugin ASTD_wrapper_generator.actions_wrapper_output_path);

  (* Build the guards wrapper *)
  if Sys.file_exists ASTD_wrapper_generator.guards_wrapper_output_path then
    load_plugin (compile_plugin ASTD_wrapper_generator.guards_wrapper_output_path)