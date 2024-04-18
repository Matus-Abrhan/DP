(** Main - Execute an ASTD with an input list and display statistics related to the execution *)

(** Verbose level *)
let raffichage = ref 1
(** Indicates if the ASTD should be kappa optimized indirectly *)
let rkappa_indirect = ref true
(** Indicated if the final state of the ASTD should be printed *)
let rprint_final = ref false
(** File path to the ASTD's specification *)
let rsFile = ref ""
(** File path to the input file *)
let riFile = ref ""
(** Pcap file name **)
let pcapFile = ref ""
(** Indicates if the plugins should be compiled in native code (false) or bytecode (true) **)
let rdebug = ref false
(** Name of the main astd **)
let rmain_astd_name = ref "MAIN" (*default value = MAIN*)

(** Set the value of a ref and ignore the warnings. Takes a third unit argument to delay the execution of the function. *)
let set_to_ref refInt value () = ignore ( refInt := value )

(** List the command line options *)
let arg_spec = [
  "-m", Arg.Set_string rmain_astd_name, "Name of main astd";
  "-i", Arg.Set_string riFile, "Input action list to execute";
  "-pcap", Arg.Set_string pcapFile, "Input pcap file to execute";
  "-s", Arg.Set_string rsFile, "Input specification";
  "-nokappa", Arg.Clear rkappa_indirect, "Desactivates kappa indirect optimization";
  "-final", Arg.Set rprint_final, "Prints final state";
  "-v", Arg.Unit (set_to_ref raffichage 1), "Regular verbose level";
  "-vv", Arg.Unit (set_to_ref raffichage 2), "Intermediate verbose level";
  "-vvv", Arg.Unit (set_to_ref raffichage 3), "Maximum verbose level";  
  "-debug", Arg.Set rdebug , "Activate debug compilation (bytecode)";
]

let usage_msg = "xASTD: An intrusion detection tool \n"

let usage _ = Arg.usage arg_spec usage_msg; exit 1 

(** Loads the structure in the given file *)
let load_structure_from_file filepath =
  try
    print_endline ("Loading from " ^ filepath);
    ASTD_parser.get_structure_from filepath;
    print_endline "Loading finished"
  with Sys_error s ->
  begin
    print_endline s;
    print_endline "Loading from stdin." ;
    ASTD_parser.get_structure_from_stdin ();
    print_endline "Loading finished"
  end

(** Loads a structure from a file choosen with stdin *)
let load_structure () = 
  print_endline "Enter file path of the structure : " ; 
  let name = input_line stdin in 
    load_structure_from_file name

(** Execute the raw_action on the ASTD (structure) and update its state (ref_state) *)
let execute_next_action raw_action ref_state ref_cpt affichage structure = (
  let raw_act = Lexing.from_string raw_action in
  let small_list= ASTD_parser_rules.apply_event ASTD_lexer_rules.token raw_act in (
    ref_state := ASTD_exec_first_hash.execute_event_list affichage !ref_state structure small_list;
    ref_cpt := !ref_cpt + 1
  )
)

(** Apply Kappa analysis and time it.
    Returns the kappa-optimized ASTD (analysed_struct) *)
    let apply_kappa_analysis structure chrono =
      let (kappa_opt_list,dep_used_list)=ASTD_static_kappa_indirect.static_analysis structure in
      let analysed_struct = chrono#measure (fun () -> ASTD_static_kappa_indirect.register_static kappa_opt_list dep_used_list structure) in
        print_endline "========================================" ;
        print_float (float_of_int (List.length kappa_opt_list));
        print_endline "optimisations found" ;
        print_endline "========================================" ;
        analysed_struct
    
    (** Chrono class to calculate the time spent between two intervals *)
    class ['a, 'b] chrono = object (chrono)
        val mutable time_accumulated = 0.0
        val mutable last_time_stamp = 0.0
    
        (** Starts the timer *)
        method start =
          last_time_stamp <- Unix.gettimeofday ()
    
        (** Stops the timer *)
        method stop =
          let time_spent_in_seconds = Unix.gettimeofday () -. last_time_stamp  in
            time_accumulated <- time_accumulated +. time_spent_in_seconds
    
        (** Measure the time spent executing a function
            Returns the result of the function *)
        method measure (f : unit -> 'a) =
          chrono#start;
          let result = f () in
            chrono#stop;
            result
    
        (** Ignore the time spent executing a function
            Returns the result of the function *)
        method ignore (f : unit -> 'b) = 
          chrono#stop;
          let result = f () in
            chrono#start;
            result
    
        (** Getter for the time accumulated *)
        method get_time = 
          time_accumulated
      end
    
    (** Get the astd from the loaded astds in memory.
      Returns
        optional_astd : an optional astd, None if the astd was not in the memory
      *)
    let get_astd_from_memory astd_name =
      try
        Some (ASTD_astd.get_astd astd_name)
      with Not_found -> None
    
    (** Reads an ASTD and load it into memory
        Returns the ASTD (structure) *)
    let read_astd sFile main_astd_name = 
      (if sFile = "" then
        load_structure ()
      else
        load_structure_from_file sFile);
      
      let optional_main_astd = get_astd_from_memory main_astd_name in
        if ASTD_functions.optional_has_value optional_main_astd then (
          let main_astd = ASTD_functions.get_optional_value optional_main_astd in
          let exit_code = ASTD_functions.remove_all_files_from_dir ASTD_wrapper_generator.client_build_dir in
          let spec_path = Filename.dirname !rsFile in
          let updated_astd = ASTD_astd.apply_post_processing_on_loaded_astd main_astd spec_path  in
            if exit_code <> 0 then 
              failwith ("Could not removed all files from dir : " ^ ASTD_wrapper_generator.client_build_dir) 
            else
              ASTD_plugin_builder.build_all spec_path;
              updated_astd
        ) else (
          failwith ("No astd with specified name was found : " ^ main_astd_name)
        )
        

(** Execute all inputed actions on the ASTD (structure)
    Returns the number of action sent to the ASTD *)
let execute_astd pFile iFile sFile main_astd_name kappa_indirect kappa_indirect_chrono affichage print_final chrono =
  let structure = ref (read_astd sFile main_astd_name) in
  let spec_types = ref (ASTD_parser.get_def_spec_types()) in
      (*ASTD_astd.print !structure "" ;*)
      (*print_endline "========================================" ;
        print_endline "Main structure : " ;
        ASTD_astd.print structure "" ;
        print_newline ();
        print_endline "========================================" ;*)
  let structure_to_execute = if kappa_indirect then apply_kappa_analysis !structure kappa_indirect_chrono else !structure in
  (*let initial_state = (ASTD_exec_first_hash.init structure) in
    print_endline "========================================" ;
    print_endline "Starting state";
    ASTD_exec_first_hash.print initial_state structure "" "Main";
    print_endline "========================================" ;*)
    let is_reading_input_streaming = (pFile = "") in
    let is_reading_input_from_console = (iFile = "") in
    let input_channel = if is_reading_input_from_console then stdin else open_in iFile in
    (*let input_prompt_function = if is_reading_input_from_console then fun () -> print_endline "Enter action : " else fun () -> () in*)
    let cpt = ref 0 in
    let last_update_time = ref ((Unix.stat sFile).st_mtime) in
    let temp_state = ref (ASTD_exec_first_hash.init !structure) in
      (
        try
          while true do
              (*input_prompt_function ();*)
              let cap = "sudo python cap_server.py "^(!spec_types) in
              let action_list_from_traffic = if is_reading_input_streaming then ASTD_parser.syscall cap else ASTD_parser.syscall ("python session_parser.py "^pFile) in
              let raw_action = chrono#ignore (fun () -> if is_reading_input_from_console then action_list_from_traffic else input_line input_channel) in
              (*print_endline raw_action;*)
              if (String.trim raw_action) <> "" then (
                 execute_next_action raw_action temp_state cpt affichage !structure;
              );
              if is_reading_input_from_console then (
                (*raise End_of_file*)
              );
              if !last_update_time <> ((Unix.stat sFile).st_mtime) then (
                structure := (read_astd sFile main_astd_name);
                let structure_to_execute = if kappa_indirect then apply_kappa_analysis !structure kappa_indirect_chrono else !structure in
                temp_state := (ASTD_exec_first_hash.init !structure);
                spec_types := ASTD_parser.get_def_spec_types();
                last_update_time := ((Unix.stat sFile).st_mtime)
              )
          done
        with
        | Parsing.Parse_error -> print_endline "an event was not parsed correctly"
        | End_of_file -> print_endline "no more event to execute"
        | exn -> print_endline (Printexc.to_string exn); raise exn
      );

      close_in input_channel ;
      if print_final then (
        print_endline "========================================" ;
        print_endline "Final state";
        ASTD_exec_first_hash.print !temp_state !structure "" "Main";
        print_endline "========================================" 
      );
      !cpt
  

let _ = 
  Arg.parse arg_spec usage usage_msg;
  print_endline "========================================" ;
  print_newline () ;
  let total_execution_chrono = new chrono in
  let reading_chrono = new chrono in
  let kappa_indirect_chrono = new chrono in
  let affichage = !raffichage in
  let kappa_indirect = !rkappa_indirect in
  let print_final = !rprint_final in
  let sFile = !rsFile in
  let iFile = !riFile in
  let pFile = !pcapFile in
  let main_astd_name = !rmain_astd_name in
  let number_of_events = ref 0 in
    total_execution_chrono#measure (fun () ->
          (* Execute the astd *)
          number_of_events := execute_astd pFile iFile sFile main_astd_name kappa_indirect kappa_indirect_chrono affichage print_final total_execution_chrono
    );
    
    print_newline ();
    print_float reading_chrono#get_time;
    print_endline " seconds of READING";
    if kappa_indirect then (
      print_float kappa_indirect_chrono#get_time;
      print_endline " seconds of Kappa indirect static analysis";
    );
    print_float total_execution_chrono#get_time;
    print_endline " seconds of EXECUTION";
    print_endline ("for " ^ (string_of_int !number_of_events) ^ " events");
    print_float (total_execution_chrono#get_time /. (float_of_int !number_of_events));
    print_endline " seconds of treatement per instruction";
    print_newline ()
