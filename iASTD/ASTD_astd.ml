type astd_name = string;;

type path = astd_name list


type t = 
    | Automata of astd_name * ASTD_attribute.t list * ASTD_action.t option * t list * ASTD_arrow.t list * astd_name list * astd_name list * astd_name
    | Sequence of  astd_name * ASTD_attribute.t list * ASTD_action.t option * t * t
    | Choice of astd_name * ASTD_attribute.t list * ASTD_action.t option * t * t 
    | Kleene of astd_name * ASTD_attribute.t list * ASTD_action.t option * t
    | Synchronisation of astd_name * ASTD_label.t list * ASTD_attribute.t list * ASTD_action.t option * t * t
    | ParallelComposition of astd_name * ASTD_attribute.t list * ASTD_action.t option * t * t
    | QChoice of astd_name * ASTD_variable.t * ASTD_constant.domain * ASTD_attribute.t list * ASTD_action.t option * ASTD_optimisation.dependency list * t
    | QSynchronisation of astd_name * ASTD_variable.t * ASTD_constant.domain * ASTD_label.t list * ASTD_attribute.t list * ASTD_action.t option * ASTD_optimisation.optimisation list * t 
    | QParallelComposition of astd_name * ASTD_variable.t * ASTD_constant.domain * ASTD_attribute.t list * ASTD_action.t option * ASTD_optimisation.optimisation list * t 
    | Guard of astd_name * ASTD_attribute.t list * ASTD_action.t option * ASTD_guard.t list * t
    | Call of astd_name * astd_name * (ASTD_variable.name *ASTD_term.t) list 
    | Elem of astd_name


let val_debug = ref false;;
let debug m = if (!val_debug) 
                        then (print_endline m )
                        else begin end;;
let debug_on () = (val_debug := true);;




let give_name=
  let n= ref 0 
      in function () -> 
                n:=!n+1;
                "gen_astd_"^(string_of_int !n)
;;


let automata_of name attributes_l optional_code astd_l arrow_l shallow_final_states deep_final_states init  = Automata (name, attributes_l, optional_code, astd_l, arrow_l, shallow_final_states, deep_final_states, init)

let sequence_of name attributes_l optional_code astd_l astd_r = Sequence (name, attributes_l, optional_code, astd_l, astd_r)

let choice_of name attributes_l optional_code astd1 astd2 = Choice (name, attributes_l, optional_code, astd1, astd2)

let kleene_of name attributes_l optional_code a = Kleene (name, attributes_l, optional_code, a)

let synchronisation_of name transition_list attributes_l optional_code a1 a2 = Synchronisation (name, transition_list, attributes_l, optional_code, a1, a2)

let parallelcomposition_of name attributes_l optional_code a1 a2 = ParallelComposition (name, attributes_l, optional_code, a1, a2)

let qchoice_of name var val_list attributes_l optional_code dep a  = QChoice (name, var, val_list, attributes_l, optional_code, dep, a)

let qsynchronisation_of name var val_list transition_list attributes_l optional_code opt a   = 
                                          QSynchronisation (name, var, val_list, transition_list, attributes_l, optional_code, opt, a)

let qparallelcomposition_of name var val_list attributes_l optional_code opt a   = 
                                          QParallelComposition (name, var, val_list, attributes_l, optional_code, opt, a)

let guard_of name attributes_l optional_code guards a = Guard(name, attributes_l, optional_code, guards, a)

let call_of name called_name fct_vect = Call(name, called_name, fct_vect)

let elem_of name = Elem (name)





let get_name a = match a with
  | Automata (name, _,_,_,_,_,_,_) -> name 
  | Sequence (name, _,_,_,_) -> name
  | Choice (name, _,_,_,_) -> name
  | Kleene (name, _,_,_) -> name
  | Synchronisation (name, _,_,_,_,_) -> name
  | ParallelComposition (name, _,_,_,_) -> name
  | QChoice (name, _,_,_,_,_,_) -> name
  | QSynchronisation (name, _,_,_,_,_,_,_) -> name  
  | QParallelComposition (name, _,_,_,_,_,_) -> name  
  | Guard (name, _,_,_,_) -> name
  | Call  (name,_,_) -> name
  | Elem (name) -> name

let get_attributes a = match a with
  | Automata (_,attributes,_,_,_,_,_,_) -> attributes
  | Sequence (_,attributes,_,_,_) -> attributes
  | Choice (_,attributes,_,_,_) -> attributes
  | Kleene (_,attributes,_,_) -> attributes
  | Synchronisation (_,_,attributes,_,_,_) -> attributes
  | QChoice (_,_,_,attributes,_,_,_) -> attributes
  | QSynchronisation (_,_,_,_,attributes,_,_,_) -> attributes  
  | Guard (_,attributes,_,_,_) -> attributes
  | _ -> failwith "unappropriate request get_attributes"

let get_optional_code a = match a with
  | Automata (_,_,optional_code,_,_,_,_,_) -> optional_code
  | Sequence (_,_,optional_code,_,_) -> optional_code
  | Choice (_,_,optional_code,_,_) -> optional_code
  | Kleene (_,_,optional_code,_) -> optional_code
  | Synchronisation (_,_,_,optional_code,_,_) -> optional_code
  | QChoice (_,_,_,_,optional_code,_,_) -> optional_code
  | QSynchronisation (_,_,_,_,_,optional_code,_,_) -> optional_code  
  | Guard (_,_,optional_code,_,_) -> optional_code
  | _ -> failwith "unappropriate request get_optional_code"

let get_sub a = match a with
  |Automata (_,_,_,l,_,_,_,_) -> l
  | _ -> failwith "unappropriate request aut sub"
;;


let get_arrows a = match a with
  |Automata (_,_,_,_,arrows,_,_,_) -> arrows 
  | _ -> failwith "unappropriate request get_arrows"
;;

let get_deep_final a = match a with
  |Automata (_,_,_,_,_,_,final,_) -> final
  | _ -> failwith "unappropriate request get_final"
;;

let get_shallow_final a = match a with
  |Automata (_,_,_,_,_,final,_,_) -> final
  | _ -> failwith "unappropriate request get_final"
;;

let get_init a = match a with
  |Automata (_,_,_,_,_,_,_,init) -> init
  | _ -> failwith "unappropriate request get_init"
;;



let get_seq_l a = match a with
  |Sequence (_,_,_,l,_) -> l
  | _ -> failwith "unappropriate request seq_l"
;;

let get_seq_r a = match a with
  |Sequence (_,_,_,_,r) -> r
  | _ -> failwith "unappropriate request seq_r"
;;

let get_choice1 a = match a with
  |Choice (_,_,_,un,_) -> un
  | _ -> failwith "unappropriate request choice1"
;;

let get_choice2 a = match a with
  |Choice (_,_,_,_,deux) -> deux
  | _ -> failwith "unappropriate request choice2"
;;


let get_astd_kleene a = match a with
  |Kleene (_,_,_,astd) -> astd
  | _ -> failwith "unappropriate request astd_kleene"
;;


let get_trans_synchronised a = match a with
  |Synchronisation (_,trans_list,_,_,_,_) -> trans_list
  |QSynchronisation (_,_,_,trans_list,_,_,_,_) -> trans_list
  | _ -> failwith "unappropriate request trans_synchronised"
;;


let get_synchro_astd1 a = match a with
  |Synchronisation (_,_,_,_,astd1,_) -> astd1
  | _ -> failwith "unappropriate request synchro_astd1"
;;


let get_synchro_astd2 a = match a with
  |Synchronisation (_,_,_,_,_,astd2) -> astd2
  | _ -> failwith "unappropriate request synchro_astd2"
;;


let get_qvar a = match a with
  |QChoice (_,v,_,_,_,_,_) -> v
  |QSynchronisation (_,v,_,_,_,_,_,_) -> v
  | _ -> failwith "unappropriate request get_qvar"
;;

let get_qvalues_c a = match a with
  |QChoice (_,_,val_list,_,_,_,_) -> val_list
  | _ -> failwith "unappropriate request get_qvalues_c"
;;

let get_qvalues_s a = match a with
  |QSynchronisation (_,_,val_list,_,_,_,_,_) -> val_list
  | _ -> failwith "unappropriate request get_qvalues_s"
;;



let get_qastd a = begin debug (" get sub qastd "^(get_name a));
 match a with
  |QChoice (_,_,_,_,_,_,astd) -> astd
  |QSynchronisation (_,_,_,_,_,_,_,astd) -> astd
  | _ -> failwith "unappropriate request get_qastd" end

;;

let get_guard_pred a =match a with
  |Guard (_,_,_,pred,_) -> pred
  | _ -> failwith "unappropriate request get_guard_pred"
;;
  

let get_guard_astd a =match a with
  |Guard (_,_,_,_,astd) -> astd
  | _ -> failwith "unappropriate request get_guard_astd"
;;

let get_called_name a = match a with
  |Call (_,called,_) -> called
  | _ -> failwith "unappropriate request get_called_name"
;;

let get_called_values a = match a with 
  |Call (_,_,var_val_list) -> var_val_list 
  | _ -> failwith "unappropriate request get_called_values"
;;



let rename_astd astd_to_rename namebis = match astd_to_rename with
   |Automata (a,b,c,d,e,f,g,h) -> Automata (namebis,b,c,d,e,f,g,h)
   |Sequence (a,b,c,d,e) -> Sequence (namebis,b,c,d,e)
   |Choice (a,b,c,d,e) -> Choice (namebis,b,c,d,e)
   |Kleene (a,b,c,d) -> Kleene (namebis,b,c,d)
   |Synchronisation (a,b,c,d,e,f) -> Synchronisation (namebis,b,c,d,e,f)
   |ParallelComposition (a,b,c,d,e) -> ParallelComposition (namebis,b,c,d,e)
   |QChoice (a,b,c,d,e,f,g) -> QChoice (namebis,b,c,d,e,f,g)
   |QSynchronisation (a,b,c,d,e,f,g,h) -> QSynchronisation (namebis,b,c,d,e,f,g,h)
   |QParallelComposition (a,b,c,d,e,f,g) -> QParallelComposition (namebis,b,c,d,e,f,g)
   |Guard (a,b,c,d,e) -> Guard (namebis,b,c,d,e)
   |Call (a,b,c) -> Call (namebis,b,c)
   |Elem(_) -> Elem(namebis)
;;




let is_elem a = match a with
  | Elem(_) -> true
  | _ -> false
;;

let is_synchro a = match a with
  | Synchronisation(_) -> true
  | _ -> false
;;
let is_qsynchro a = match a with
  | QSynchronisation(_) ->true
  | _ -> false
;;
let is_qchoice a = match a with
  | QChoice(_) ->true
  | _ -> false
;;
let is_automata a = match a with
  | Automata(_) ->true
  | _ -> false
;;

let rec find_subastd name astd_list = match astd_list with
  |(a::tail) ->begin debug ("find in sub astd "^name^" compare with "^(get_name a));
            if (get_name a)=name
                    then a
                    else begin (find_subastd name tail )  end  
            end
   |[]->failwith ("sub-astd : not found "^name) 
;;



let rec test_var_dom env var_dom_list = match var_dom_list with
  |(var,dom)::tail-> if (ASTD_constant.is_included (ASTD_term.extract_constant_from_term(ASTD_environment.find_value_of env var)) dom)
        then test_var_dom env tail
        else false
  |[]->true


let actions_table = Hashtbl.create 5

let register_action id action = 
  Hashtbl.add actions_table id action
 
let get_action id : (module ASTD_plugin_interfaces.Action_interface) option = 
  try
    Some (Hashtbl.find actions_table id)
  with Not_found -> None

let guards_table = Hashtbl.create 5

let register_guard id guard = 
  Hashtbl.add guards_table id guard
 
let get_guard id : (module  ASTD_plugin_interfaces.Guard_interface) option  = 
  try
    Some (Hashtbl.find guards_table id)
  with Not_found -> None

(** Gets the modules of the guards which were successfully loaded.
  Parameters
    guards : guards to get the modules associated
  Returns 
    guard_modules : a list of modules of type ASTD_plugin_interfaces.Guard_interface
  *)
let get_guard_modules guards = 
  let optional_guard_modules = List.map (fun guard -> (get_guard (ASTD_guard.get_id guard))) guards in
    ASTD_functions.get_values_of_all_valid_optionals optional_guard_modules

let _ASTD_astd_table_ = Hashtbl.create 5 
;;


let _ASTD_astd_call_table_ = Hashtbl.create 5 
;;


let _ASTD_astd_dom_table_ = Hashtbl.create 5 
;;

let register a = Hashtbl.add _ASTD_astd_table_ (get_name a) a  
;;

let register_call_astd a b= Hashtbl.add _ASTD_astd_call_table_ (get_name a) (a,b)  
;;

let update_call_astd astd b =
  let astd_name = get_name astd in 
    Hashtbl.remove _ASTD_astd_call_table_ astd_name;
    register_call_astd astd b

let get_astd name = Hashtbl.find _ASTD_astd_table_ name 
;;

let get_call_astd name = Hashtbl.find _ASTD_astd_call_table_ name 

let call_astd name env= let (astd,var_dom_list)= get_call_astd name
      in if (test_var_dom env var_dom_list )
        then astd
        else failwith "call impossible"
;;

let rec replace_sub_astd sub_astd name astd_list = match astd_list with 
  |astd::tail->if (get_name astd)=name
      then sub_astd::tail
      else astd::(replace_sub_astd sub_astd name tail)
  |[]->failwith "replace impossible: doesn't exist"

(** Recursively go through the entire hierarchy of astd to get the sub transitions of the current astd.
  Note : When going through call astds, we may get the same transition multiple times. This is a current limitation and should be refactored.
  See issue #75
  *)
let rec get_sub_transitions_internal call_path astd  = match astd with

   |Automata (_,_,_,sub_astds,arrows,_,_,_) -> begin let sub_astds_transitions= List.map (get_sub_transitions_internal call_path) sub_astds
        in (List.map (ASTD_arrow.get_transition) arrows)@(List.concat sub_astds_transitions)
      end

   |Sequence (_,_,_,astd_fst,astd_snd) -> (get_sub_transitions_internal call_path astd_fst)@(get_sub_transitions_internal call_path astd_snd)

   |Choice (_,_,_,astd_fst,astd_snd) -> (get_sub_transitions_internal call_path astd_fst)@(get_sub_transitions_internal call_path astd_snd)

   |Kleene (_,_,_,sub_astd) -> (get_sub_transitions_internal call_path sub_astd)

   |Synchronisation (_,_,_,_,astd_fst,astd_snd) -> (get_sub_transitions_internal call_path astd_fst)@(get_sub_transitions_internal call_path astd_snd)

   |Guard (_,_,_,_,sub_astd) -> (get_sub_transitions_internal call_path sub_astd)

   |QChoice (_,_,_,_,_,_,sub_astd) -> (get_sub_transitions_internal call_path sub_astd)

   |QSynchronisation (_,_,_,_,_,_,_,sub_astd)-> (get_sub_transitions_internal call_path sub_astd)
                                   
   |Call (name,targeted_astd_name,_) -> if (List.mem name call_path) then [] else (get_sub_transitions_internal (name::call_path) (get_astd targeted_astd_name))

   |Elem (_) -> []

   | _ -> failwith "Invalid ASTD"
;;

let get_sub_transitions astd  = 
  get_sub_transitions_internal [] astd
;;


let rec get_sub_names call_path astd = match astd with
   |Automata (name,_,_,sub_astds,_,_,_,_) -> name::(List.concat (List.map (get_sub_names call_path) sub_astds))

   |Sequence (name,_,_,astd_fst,astd_snd) -> name::((get_sub_names call_path astd_fst)@(get_sub_names call_path astd_snd))

   |Choice (name,_,_,astd_fst,astd_snd) -> name::((get_sub_names call_path astd_fst)@(get_sub_names call_path astd_snd))

   |Kleene (name,_,_,sub_astd) -> name::(get_sub_names call_path sub_astd)

   |Synchronisation (name,_,_,_,astd_fst,astd_snd) -> name::((get_sub_names call_path astd_fst)@(get_sub_names call_path astd_snd))

   |Guard (name,_,_,_,sub_astd) -> name::(get_sub_names call_path sub_astd)

   |QChoice (name,_,_,_,_,_,sub_astd) -> name::(get_sub_names call_path sub_astd)

   |QSynchronisation (name,_,_,_,_,_,_,sub_astd)-> name::(get_sub_names call_path sub_astd)
                                   
   |Call (name,targeted_astd_name,_) -> if (List.mem name call_path) then [] else name::(get_sub_names (name::call_path) (get_astd targeted_astd_name))

   |Elem (name) -> [name]

   | _ -> failwith "Invalid ASTD"
;;



let rec get_sub_arrows call_path astd  = match astd with

   |Automata (_,_,_,sub_astds,arrows,_,_,_) -> begin let l= List.map (get_sub_arrows call_path) sub_astds
        in  arrows@(List.concat l)
      end

   |Sequence (_,_,_,astd_fst,astd_snd) -> (get_sub_arrows call_path astd_fst)@(get_sub_arrows call_path astd_snd)

   |Choice (_,_,_,astd_fst,astd_snd) -> (get_sub_arrows call_path astd_fst)@(get_sub_arrows call_path astd_snd)

   |Kleene (_,_,_,sub_astd) -> (get_sub_arrows call_path sub_astd)

   |Synchronisation (_,_,_,_,astd_fst,astd_snd) -> (get_sub_arrows call_path astd_fst)@(get_sub_arrows call_path astd_snd)

   |Guard (_,_,_,_,sub_astd) -> (get_sub_arrows call_path sub_astd)

   |QChoice (_,_,_,_,_,dep,sub_astd) -> (get_sub_arrows call_path sub_astd)

   |QSynchronisation (_,_,_,_,_,_,opt,sub_astd) -> (get_sub_arrows call_path sub_astd)
                                   
   |Call (name,targeted_astd_name,_) -> if (List.mem name call_path) then [] else (get_sub_arrows (name::call_path) (get_astd targeted_astd_name))

   |Elem (_) -> []

   | _ -> failwith "Invalid ASTD"
;;

let rec is_init_final astd call_path = match astd with
   |Automata (name,attributes,optional_code,sub_astd,trans,sf,df,init) -> 
    begin if List.mem init sf
      then "true"
      else if List.mem init df
        then is_init_final (find_subastd init sub_astd) call_path
        else "false"
    end

   |Sequence (name,attributes,optional_code,l,r) -> 
    let final_l = is_init_final l call_path
    in if (final_l)="true"
      then is_init_final r call_path
      else final_l

   |Choice (name,attributes,optional_code,l,r) -> 
    let final_l = is_init_final l call_path
    in if (final_l)="true"
      then final_l
      else if final_l = "false"
        then is_init_final r call_path
        else let final_r=is_init_final r call_path
          in if final_r="true"
            then "true"
            else "unknown"

   |Kleene (name,attributes,optional_code,sub_astd) -> "true"

   |Synchronisation (name,synch_trans,attributes,optional_code,l,r) -> 
    let final_l = is_init_final l call_path
    in if (final_l)="true"
      then is_init_final r call_path
      else if final_l = "false"
        then "false"
        else if is_init_final r call_path="false"
          then "false"
          else "unknown"

   |Guard (a,attributes,optional_code,b,c) -> "unknown"   (*peut etre amélioré pour être utilisé avec l'environnement au moment de l'appel => cad avec un try bla with et si l'environnement est pas suffisant, echec = unknown sinon, sa valeur*)

   |QChoice (name,var,dom,attributes,optional_code,dep,sub_astd) -> is_init_final sub_astd call_path

   |QSynchronisation (name,var,dom,synch_trans,attributes,optional_code,opt,sub_astd)-> is_init_final sub_astd call_path
                                   
   |Call (name,called_name,fct_vec) -> 
    if List.mem called_name call_path 
      then "false"
      else is_init_final (get_astd called_name) (called_name::call_path)

   |Elem (a) -> "true"

   | _ -> failwith "Invalid ASTD"
;;




let get_data_automata astd = match astd with
  |Automata(name,attributes,optional_code,sub_astd,trans,sf,df,init) -> (name,attributes,optional_code,sub_astd,trans,sf,df,init)
  |_-> failwith "not appropriate data automata"


let get_data_sequence astd = match astd with
  |Sequence (name,attributes,optional_code,l,r) -> (name,attributes,optional_code,l,r)
  |_-> failwith "not appropriate data seq "

let get_data_choice astd = match astd with
  |Choice(name,attributes,optional_code,l,r) -> (name,attributes,optional_code,l,r)
  |_-> failwith "not appropriate data choice"

let get_data_kleene astd = debug ("get_data_kleene : "^get_name astd) ; match astd with
  |Kleene(name,attributes,optional_code,sub_astd) -> (name,attributes,optional_code,sub_astd)
  |_-> failwith "not appropriate data kleene"

let get_data_synchronisation astd = match astd with
  |Synchronisation(name,synch_trans,attributes,optional_code,l,r) -> (name,synch_trans,attributes,optional_code,l,r)
  |_-> failwith "not appropriate data synch"

let get_data_guard astd = match astd with
  |Guard(a,attributes,optional_code,b,c) -> (a,attributes,optional_code,b,c)
  |_-> failwith "not appropriate data guard"

let get_data_qchoice astd = match astd with
  |QChoice(name,var,dom,attributes,optional_code,dep,sub_astd) -> (name,var,dom,attributes,optional_code,dep,sub_astd)
  |_-> failwith "not appropriate data qchoice"

let get_data_qsynchronisation astd = match astd with
  |QSynchronisation(name,var,dom,synch_trans,attributes,optional_code,opt,sub_astd) -> (name,var,dom,synch_trans,attributes,optional_code,opt,sub_astd)
  |_-> failwith "not appropriate data qsynch"

let get_data_call astd = match astd with
  |Call(name,called_name,fct_vec) -> (name,called_name,fct_vec)
  |_-> failwith "not appropriate data call"




let string_of name = name 
;;


let global_save_astd a b = (register a);(register_call_astd a b)
;;


let rec string_of_sons sons_list = match sons_list with
 |h::t -> let name = string_of(get_name h) in name^" "^(string_of_sons t) 
 |[] ->""
;;


let rec print astd st = match astd with
   |Automata (a,_,_,b,c,d,e,f) -> let s=string_of_sons b in print_endline (st^" Automata ; Name : "^a^"; Sons : "^s  );print_newline(); 
                                print_sons b st;

   |Sequence (a,_,_,b,c) -> print_endline (st^" Sequence ; Name : "^a^"; Son 1 : "^(string_of(get_name b))^"; Son 2 : "^(string_of(get_name c)));print_newline();print b (st^"   "); print c (st^"   ")

   |Choice (a,_,_,b,c) -> print_endline (st^"Choice ; Name : "^a^"; Son 1 : "^(string_of(get_name b))^"; Son 2 : "^(string_of(get_name c)));print_newline(); print b (st^"   ");print c (st^"   ")

   |Kleene (a,_,_,b) -> print_endline (st^"Kleene ; Name : "^a^"; Son : "^(string_of(get_name b)));print_newline();print b (st^"   ")

   |Synchronisation (a,b,_,_,c,d) -> print_endline (st^"Synchronisation ; Name : "^a^"; Son 1 : "^(string_of(get_name c))^"; Son 2 : "^(string_of(get_name d)));print_newline(); print c (st^"   ") ; print d (st^"   ")

   |Guard (a,_,_,b,c) -> print_endline (st^"Guard ; Name : "^a^"; Son : "^(string_of(get_name c)));print_newline();print c (st^"   ")

   |QChoice (a,b,c,_,_,dep,d) -> print_endline (st^"QChoice ; Name : "^a^"; Var : "^ASTD_variable.get_name(b)^"; Son : "^(string_of(get_name d)));print_newline(); print d (st^"   ") 

   |QSynchronisation (a,b,c,d,_,_,opt,e)-> print_endline (st^"QSynchronisation ; Name : "^a^"; Var : "^ASTD_variable.get_name(b)^"; Son : "^(string_of(get_name e)));print_newline(); print e (st^"   ") 

   |Call (a,b,c) -> print_endline (st^"Call ; Name : "^(string_of a)^"; Called : "^(string_of b));print_newline()

   |Elem (a) -> print_endline (st^"Elem ; Name : "^(string_of a));print_newline()

   | _ -> failwith "Invalid ASTD"



and print_sons astd_list start= match astd_list with
    |h::q -> print h (start^"   ");print_sons q start 
    |[]-> print_newline()
;;

(** Initialize the arg received with the variable
  Parameters 
    variables : list of correctly initialized variables
    arg : partially initialized argument
  Returns 
    initialized_arg = initialized argument 
 *) 
let initialize_arg variables arg =  
  let compare_variables current_var = 0 == (ASTD_variable.compare current_var (ASTD_action.variable_of_arg arg)) in 
  let associated_variable = ASTD_functions.find_opt compare_variables variables in 
    if ASTD_functions.optional_has_value associated_variable then 
      ASTD_action.update_variable_of_arg arg (ASTD_functions.get_optional_value associated_variable)
    else 
      failwith ("variable in action does not exist : " ^ ASTD_action.get_variable_name_from_arg arg) 

(** Initialize the action's arguments 
  Parameters 
    variables : all variables instances available
    action : arrow for which to initialize its action's arguments 
  Returns  
    initialized_action optional : optional initialized action 
 *) 
let initialize_action variables optional_action = 
  if ASTD_functions.optional_has_value optional_action then (
    let action = ASTD_functions.get_optional_value optional_action in
    let initialized_args = List.map (initialize_arg variables) (ASTD_action.get_args action) in
    let initialized_action = ASTD_action.update_args_of_action action initialized_args in
      ASTD_wrapper_generator.generate_action initialized_action;
      Some initialized_action
  ) else (
    None
  )

(** Initialize a guard
  Parameters
    variables : list of initialized variables
    guards : list of guards
  Returns
    Nothing
  *)
let initialize_guards variables guards spec_path =
  if not (ASTD_functions.is_list_empty guards) then (
    let guard = List.hd guards in 
      ASTD_wrapper_generator.generate_guard guard variables spec_path
  )

(** Initialize an arrow's action and guard
  We also need to get the local variables of the transition to use them during the initialization of the action and the guard

  Parameters
    variables : list of initialized variables
    arrow : arrow to initialize
  Returns
    initialized_arrow : arrow with action and guard initialized
  *)
let initialize_arrow arrow variables spec_path = 
  let captured_variables = ASTD_transition.get_captured_variables_from_transition (ASTD_arrow.get_transition arrow) in
  let all_local_variables = captured_variables@variables in
  let optional_action = ASTD_arrow.get_optional_action arrow in 
  let initialized_action = initialize_action all_local_variables optional_action in
  let initialized_arrow = ASTD_arrow.set_optional_action arrow initialized_action in
  let guards = ASTD_arrow.get_guards arrow in
    initialize_guards all_local_variables guards spec_path;
    initialized_arrow

(** Recursively go through the entire hierarchy of astd to initialize actions and guards 
  Parameters 
    astd : root astd 
    variables : list of initialized variables
  Returns
    initialized_astd : astd with initialized arrows and guards
  *)
let rec initalize_actions_and_guards astd variables spec_path =
    match astd with 
  | Automata (name, attributes, optional_code, sub_astds, arrows, sf, df, init) -> 
      let attributes_variables = List.map ASTD_attribute.variable_of_attribute attributes in 
      let merged_variables = attributes_variables@variables in 
      let initialized_arrows = List.map (fun arrow -> initialize_arrow arrow merged_variables spec_path) arrows  in
      let initialized_sub_astds = List.map (fun sub_astd -> initalize_actions_and_guards sub_astd merged_variables spec_path) sub_astds in
        ignore(initialize_action merged_variables optional_code); 
        automata_of name attributes optional_code initialized_sub_astds initialized_arrows sf df init
      
  | Sequence (name, attributes, optional_code, l, r) -> 
      let attributes_variables = List.map ASTD_attribute.variable_of_attribute attributes in 
      let merged_variables = attributes_variables@variables in 
      let initialized_left_astd = initalize_actions_and_guards l merged_variables spec_path in
      let initialized_right_astd = initalize_actions_and_guards r merged_variables spec_path in
        ignore(initialize_action merged_variables optional_code); 
        sequence_of name attributes optional_code initialized_left_astd initialized_right_astd

  | Choice (name, attributes, optional_code, l, r) -> 
      let attributes_variables = List.map ASTD_attribute.variable_of_attribute attributes in 
      let merged_variables = attributes_variables@variables in 
      let initialized_left_astd = initalize_actions_and_guards l merged_variables spec_path in
      let initialized_right_astd = initalize_actions_and_guards r merged_variables spec_path in
        ignore(initialize_action merged_variables optional_code); 
        choice_of name attributes optional_code initialized_left_astd initialized_right_astd

  | Kleene (name, attributes, optional_code, sub_astd) -> 
      let attributes_variables = List.map ASTD_attribute.variable_of_attribute attributes in 
      let merged_variables = attributes_variables@variables in 
      let initialized_sub_astd = initalize_actions_and_guards sub_astd merged_variables spec_path in
        ignore(initialize_action merged_variables optional_code); 
        kleene_of name attributes optional_code initialized_sub_astd
      
  | Synchronisation (name, synch_trans, attributes, optional_code, l, r) -> 
      let attributes_variables = List.map ASTD_attribute.variable_of_attribute attributes in 
      let merged_variables = attributes_variables@variables in 
      let initialized_left_astd = initalize_actions_and_guards l merged_variables spec_path in
      let initialized_right_astd = initalize_actions_and_guards r merged_variables spec_path in
        ignore(initialize_action merged_variables optional_code); 
        synchronisation_of name synch_trans attributes optional_code initialized_left_astd initialized_right_astd

  | ParallelComposition (name, attributes, optional_code, l, r) -> 
    let attributes_variables = List.map ASTD_attribute.variable_of_attribute attributes in 
    let merged_variables = attributes_variables@variables in 
    let initialized_left_astd = initalize_actions_and_guards l merged_variables spec_path in
    let initialized_right_astd = initalize_actions_and_guards r merged_variables spec_path in
    let left_transitions = get_sub_transitions initialized_left_astd in
    let right_transitions = get_sub_transitions initialized_right_astd in
    let left_labels = List.map ASTD_transition.get_label left_transitions in
    let right_labels = List.map ASTD_transition.get_label right_transitions in
    let common_labels = ASTD_functions.intersection left_labels right_labels in
      ignore(initialize_action merged_variables optional_code); 
      synchronisation_of name common_labels attributes optional_code initialized_left_astd initialized_right_astd

  | Guard (name, attributes, optional_code, guards, sub_astd) -> 
      let attributes_variables = List.map ASTD_attribute.variable_of_attribute attributes in 
      let merged_variables = attributes_variables@variables in 
      let initialized_sub_astd = initalize_actions_and_guards sub_astd merged_variables spec_path in
        ignore(initialize_action merged_variables optional_code); 
        initialize_guards merged_variables guards spec_path;
        guard_of name attributes optional_code guards initialized_sub_astd

  | QChoice (name, var, dom, attributes, optional_code, dep, sub_astd) -> 
      let attributes_variables = List.map ASTD_attribute.variable_of_attribute attributes in 
      let merged_variables = var::(attributes_variables@variables) in 
      let initialized_sub_astd = initalize_actions_and_guards sub_astd merged_variables spec_path in
        ignore(initialize_action merged_variables optional_code); 
        qchoice_of name var dom attributes optional_code dep initialized_sub_astd

  | QSynchronisation (name, var, dom, synch_trans, attributes, optional_code, opt, sub_astd) -> 
      let attributes_variables = List.map ASTD_attribute.variable_of_attribute attributes in 
      let merged_variables = var::(attributes_variables@variables) in 
      let initialized_sub_astd = initalize_actions_and_guards sub_astd merged_variables spec_path in
        ignore(initialize_action merged_variables optional_code); 
        qsynchronisation_of name var dom synch_trans attributes optional_code opt initialized_sub_astd

  | QParallelComposition (name, var, dom, attributes, optional_code, opt, sub_astd) -> 
    let attributes_variables = List.map ASTD_attribute.variable_of_attribute attributes in 
    let merged_variables = var::(attributes_variables@variables) in 
    let initialized_sub_astd = initalize_actions_and_guards sub_astd merged_variables spec_path in
    let transitions = get_sub_transitions initialized_sub_astd in
    let labels = List.map ASTD_transition.get_label transitions in
      ignore(initialize_action merged_variables optional_code); 
      qsynchronisation_of name var dom labels attributes optional_code opt initialized_sub_astd
                      
  | Call (name, called_name, fct_vec) -> 
      let sub_astd, var_dom_link = get_call_astd called_name in
      let current_parameters_variables = List.map (fun (variable, domain) -> variable) var_dom_link in
      let new_sub_astd = initalize_actions_and_guards sub_astd current_parameters_variables spec_path in  
        update_call_astd new_sub_astd var_dom_link; 
        astd (* Nothing was changed in this call astd, but the called sub astd was updated globally *) 

  | Elem (a) -> astd

(** Apply post processing of an astd loaded from a spec file
  Parameters
    astd : uninitialized astd
  Returns
    initialized_astd
 *)
let apply_post_processing_on_loaded_astd astd spec_path = 
  initalize_actions_and_guards astd [] spec_path

