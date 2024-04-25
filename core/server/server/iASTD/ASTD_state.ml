type step = Fst | Snd
type side = Undef | Left | Right
type qchoice = Val of ASTD_term.t | ChoiceNotMade
type astd_name = string
type called_path = astd_name list

type t = 
  | Automata_s of astd_name * (astd_name * t) list * t * ASTD_attribute.instance list
  | Sequence_s of step * t * ASTD_attribute.instance list
  | Choice_s of side * t * ASTD_attribute.instance list
  | Kleene_s of bool * t * ASTD_attribute.instance list
  | Synchronisation_s of t * t * ASTD_attribute.instance list
  | QChoice_s of qchoice * ASTD_constant.domain * ASTD_constant.domain * t * ASTD_attribute.instance list
  | QSynchronisation_s  of ASTD_constant.domain * ASTD_constant.domain * ASTD_constant.domain * t * ASTD_attribute.instance list
  | Guard_s of bool * t * ASTD_attribute.instance list
  | Call_s of bool * t
  | NotDefined
  | Elem



let val_debug = ref false
let debug m = if !val_debug then print_endline m
let debug_on () = val_debug := true
let val_debug_hash = false
let debug_hash m = if val_debug_hash then print_endline m


let automata_s_of pos hist current attributes_instances = Automata_s (pos,hist,current,attributes_instances);;
let sequence_s_of step current attributes_instances = Sequence_s (step,current,attributes_instances);;
let choice_s_of side current attributes_instances = Choice_s (side,current,attributes_instances);;
let kleene_s_of started current attributes_instances = Kleene_s (started,current,attributes_instances);;
let synchronisation_s_of first second attributes_instances = Synchronisation_s (first,second,attributes_instances);;
let qchoice_s_of choice final_dom unknown_dom current attributes_instances = QChoice_s (choice,final_dom,unknown_dom,current,attributes_instances);;
let qsynchronisation_s_of not_fin_dom unknown_dom init_dom init attributes_instances =  QSynchronisation_s (not_fin_dom,unknown_dom,init_dom,init,attributes_instances);;
let guard_s_of condition current attributes_instances = Guard_s (condition,current,attributes_instances);;
let call_s_of called current = Call_s (called,current);;
let not_defined_state () = NotDefined;;
let elem_state () = Elem;;

let undef_choice_of () = Undef;;
let left_choice_of () = Left;;
let right_choice_of () = Right;;

let first_sequence_of () = Fst;;
let second_sequence_of () = Snd;;

let qchoice_notmade_of () = ChoiceNotMade

let get_attributes state =
  match state with
  | Automata_s (pos,hist,current,attributes_instances) -> attributes_instances
  | Sequence_s (step,current,attributes_instances) -> attributes_instances
  | Choice_s (side,current,attributes_instances) -> attributes_instances
  | Kleene_s (started,current,attributes_instances) -> attributes_instances
  | Synchronisation_s (first,second,attributes_instances) -> attributes_instances
  | QChoice_s (choice,final_dom,unknown_dom,current,attributes_instances) -> attributes_instances
  | QSynchronisation_s (not_fin_dom,unknown_dom,init_dom,init,attributes_instances) -> attributes_instances
  | Guard_s (condition,current,attributes_instances) -> attributes_instances
  | _ -> print_endline "!!!!!!!!!!!!!!!!!!!!!!!!!! get attributes on call astd";failwith "invalid state for get_attributes"

let get_pos state = match state with
  | Automata_s (a,b,c,_) -> a
  | _ -> failwith "not an automata"


let is_automata state = match state with
  | Automata_s (_,_,_,_) -> true
  | _ -> false


let is_qsynchro state = match state with
  | QSynchronisation_s(_) -> true
  | _ -> false


let get_data_from_qsynchro state = match state with
  | QSynchronisation_s(p,q,r,s,t) -> (p,q,r,s,t)
  | _ -> failwith "not appropriate use of get_data_from_qsynchro" 

let get_data_automata_s state = match state with
  | Automata_s(a,b,c,d) -> (a,b,c,d)
  | _ -> failwith "not an automata in get_data_automata_s" 

let get_val choice = match choice with
  | Val(a) -> a 
  | ChoiceNotMade -> failwith "not a value"


let val_of a = Val (a)

let rec get_labels arrows = match arrows with
  | (h1, h2)::t -> h1::(get_labels t)
  | [] -> []

let set_attributes_instances state updated_attributes_instances =
  match state with
  | Automata_s (pos,hist,current,attributes_instances) -> Automata_s (pos,hist,current,updated_attributes_instances)
  | Sequence_s (step,current,attributes_instances) -> Sequence_s (step,current,updated_attributes_instances)
  | Choice_s (side,current,attributes_instances) -> Choice_s (side,current,updated_attributes_instances)
  | Kleene_s (started,current,attributes_instances) -> Kleene_s (started,current,updated_attributes_instances)
  | Synchronisation_s (first,second,attributes_instances) -> Synchronisation_s (first,second,updated_attributes_instances)
  | QChoice_s (choice,final_dom,unknown_dom,current,attributes_instances) -> QChoice_s (choice,final_dom,unknown_dom,current,updated_attributes_instances)
  | QSynchronisation_s (not_fin_dom,unknown_dom,init_dom,init,attributes_instances) -> QSynchronisation_s (not_fin_dom,unknown_dom,init_dom,init,updated_attributes_instances)
  | Guard_s (condition,current,attributes_instances) -> Guard_s (condition,current,updated_attributes_instances)
  | Call_s (called,current) -> Call_s (called,current)
  | _ -> failwith "invalid state for update_attributes_instances"



let _ASTD_synch_table_ = Hashtbl.create 5 

let rec remove_all key const =
  if Hashtbl.mem _ASTD_synch_table_ (key, const) then (
    debug_hash ("remove all at" ^ key ^ " " ^ (ASTD_constant.string_of const));
    Hashtbl.remove _ASTD_synch_table_ (key, const);
    remove_all key const
  )

let register_synch key const state =
  debug_hash ("HASH register at " ^ key ^ " " ^ (ASTD_constant.string_of const));
  remove_all key const;
  Hashtbl.add _ASTD_synch_table_ (key, const) state


let get_synch key const =
  debug_hash ("HASH extract at " ^ key ^ " " ^ (ASTD_constant.string_of const));
  Hashtbl.find _ASTD_synch_table_ (key, const) 
                        
let get_synch_state not_init_dom init key const =
  debug_hash ("extract at "^key^ " " ^ (ASTD_constant.string_of const) ^" or init");
  if ASTD_constant.is_included const not_init_dom then
    Hashtbl.find _ASTD_synch_table_ (key, const)
  else (
    debug "Not included in domain, returns init";
    init
  )


let rec save_data to_save =
  match to_save with
  | ((key, const), state)::t -> 
      register_synch key const state;
      save_data t
  | [] -> ()

let string_of_bool a = if a then "true" else "false"

let string_of_seq a = match a with
  | Fst -> "First"
  | Snd -> "Second"

let string_of_choice a = match a with
  | Left -> "First"
  | Right -> "Second"
  | Undef -> "Choice not made yet"

let string_of_qchoice a = match a with
  | Val(v) -> ASTD_term.string_of v
  | ChoiceNotMade -> "Choice not made yet"
