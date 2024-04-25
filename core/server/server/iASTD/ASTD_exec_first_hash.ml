let val_debug = ref false
let debug m = if !val_debug then print_endline m
let debug_on () = val_debug := true

let get_bdd key const = ASTD_state.get_synch key const
let register_bdd key const state =  ASTD_state.register_synch key const state
let save_synch_data to_save = ASTD_state.save_data to_save 
let get_synch_bdd not_init_dom init_state key const = ASTD_state.get_synch_state not_init_dom init_state key const

(**Init*)
let rec init astd = match astd with
   |ASTD_astd.Automata (a,attributes,optional_code,b,c,d,e,f) -> ASTD_state.automata_s_of f (init_history b) (init (ASTD_astd.find_subastd f b)) (ASTD_attribute.init_all attributes)

   |ASTD_astd.Sequence (a,attributes,optional_code,b,c) -> ASTD_state.sequence_s_of ASTD_state.Fst (init b) (ASTD_attribute.init_all attributes)

   |ASTD_astd.Choice (a,attributes,optional_code,b,c) -> ASTD_state.choice_s_of (ASTD_state.undef_choice_of()) (ASTD_state.not_defined_state()) (ASTD_attribute.init_all attributes)

   |ASTD_astd.Kleene (a,attributes,optional_code,b) -> ASTD_state.kleene_s_of false (init b) (ASTD_attribute.init_all attributes)
    
   |ASTD_astd.Synchronisation (a,b,attributes,optional_code,c,d) -> ASTD_state.synchronisation_s_of  (init c)  (init d) (ASTD_attribute.init_all attributes)

   |ASTD_astd.Guard (a,attributes,optional_code,b,c) -> ASTD_state.guard_s_of false (init c) (ASTD_attribute.init_all attributes)

   |ASTD_astd.QChoice (a,b,val_list,attributes,optional_code,dep,d) ->
  let boxable = ASTD_astd.is_init_final d []
  in if boxable = "true"
    then ASTD_state.qchoice_s_of ASTD_state.ChoiceNotMade (val_list) (ASTD_constant.empty_dom) (init d) (ASTD_attribute.init_all attributes)
    else if boxable = "false"
      then ASTD_state.qchoice_s_of ASTD_state.ChoiceNotMade (ASTD_constant.empty_dom) (ASTD_constant.empty_dom) (init d) (ASTD_attribute.init_all attributes)
      else ASTD_state.qchoice_s_of ASTD_state.ChoiceNotMade (ASTD_constant.empty_dom) (val_list) (init d) (ASTD_attribute.init_all attributes)


   |ASTD_astd.QSynchronisation (a,b,val_list,d,attributes,optional_code,opt,e)-> 
  let boxable = ASTD_astd.is_init_final e []
  in if boxable = "true"
    then ASTD_state.qsynchronisation_s_of (ASTD_constant.empty_dom) (ASTD_constant.empty_dom) (ASTD_constant.empty_dom) (init e) (ASTD_attribute.init_all attributes)
    else if boxable = "false"
      then ASTD_state.qsynchronisation_s_of (val_list) (ASTD_constant.empty_dom) (ASTD_constant.empty_dom) (init e) (ASTD_attribute.init_all attributes)
      else ASTD_state.qsynchronisation_s_of (ASTD_constant.empty_dom) (val_list) (ASTD_constant.empty_dom) (init e) (ASTD_attribute.init_all attributes)

   |ASTD_astd.Call (a,b,c) -> ASTD_state.call_s_of false ASTD_state.NotDefined

   |ASTD_astd.Elem (a) -> ASTD_state.Elem

   | _ -> failwith "Invalid ASTD"


and init_history astd_list =
  match astd_list with
  | (ASTD_astd.Elem (_))::q -> init_history q
  | astd::q -> (ASTD_astd.get_name astd, init astd)::(init_history q )
  | [] -> []

(**Final states
  le problème est celui de qsynch: domain=Finaux U nonFinaux U inconnu  => on a besoin de réduire le plus tôt possible toutes les valeurs
  inconnues vu qu'elles devront être recalculées lors de l'évaluation de l'état final => on utilise is_init_final(astd) dans l'initialisation pour le savoir et oui -> final / non -> non final / ?-> inconnu
  depuis vu que les trois ensembles forment une partition du domain, il suffit de non final et inconnu pour les représenter (on prends non final et inconnu car quand ils sont vides, l'état est final)
  le dernier point est que l'évaluation des inconnus ne doit pas être perdue => il faut l'enregistrer => il faut propager les états modifiés

  attention la garde : ca semble intéressant de faire pareil en passant started à true mais le peut on ?
  *)
let rec is_final astd state env call_path current_key = 
  match state with
  | ASTD_state.Automata_s (position,hist,sub_state,attributes_instances) -> 
    let (name,attributes,optional_code,sub_astds,arrows,shallow_final,deep_final,init)=ASTD_astd.get_data_automata astd in
      if List.mem position shallow_final then (
        debug ("shallow final "^name);
        (state,true)
      ) else if List.mem position deep_final then (
        debug ("in deep "^name);
        let current_sub_astd = ASTD_astd.find_subastd position sub_astds in 
        let (new_state,final)=is_final current_sub_astd sub_state env call_path (current_key^"/"^position) in
          (ASTD_state.Automata_s (position,hist,new_state,attributes_instances) , final)
      ) else (
        debug ("not final in "^name^" the position "^position);
        (state,false)
      )

  | ASTD_state.Sequence_s (step, sub_state,attributes_instances) -> 
    let (name,attributes,optional_code,first,second) = ASTD_astd.get_data_sequence astd in
      if step = ASTD_state.Fst then
        let (new_state, final1) = (is_final first sub_state env call_path (current_key^"/"^(ASTD_astd.get_name first))) in
        let (_, final2)=(is_final second (init second) env call_path (current_key^"/"^(ASTD_astd.get_name second))) in
          (ASTD_state.Sequence_s (step, new_state,attributes_instances), final1 && final2)
      else
        let (new_state,final)=(is_final second sub_state env call_path (current_key^"/"^(ASTD_astd.get_name second))) in
          (ASTD_state.Sequence_s (step, new_state,attributes_instances), final)

  | ASTD_state.Choice_s (side,sub_state,attributes_instances) -> 
    let (name,attributes,optional_code,left_astd,right_astd) = ASTD_astd.get_data_choice astd in
      if side = ASTD_state.Right then
        let (new_state,final)=(is_final right_astd sub_state env call_path (current_key^"/"^(ASTD_astd.get_name right_astd))) in
          (ASTD_state.Choice_s (ASTD_state.Right,new_state,attributes_instances),final)
      else if side = ASTD_state.Left then
        let (new_state, final)=(is_final left_astd sub_state env call_path (current_key^"/"^(ASTD_astd.get_name left_astd))) in
          (ASTD_state.Choice_s (ASTD_state.Left,new_state,attributes_instances),final)
      else
        let (_, final1) = (is_final left_astd (init left_astd) env call_path (current_key^"/"^(ASTD_astd.get_name left_astd))) in
        let (_, final2) = (is_final right_astd (init right_astd) env call_path (current_key^"/"^(ASTD_astd.get_name right_astd))) in 
          (state, final1 || final2)

  | ASTD_state.Kleene_s (started, sub_state, attributes_instances) -> 
    let (name, attributes,optional_code, sub_astd) = ASTD_astd.get_data_kleene astd in
      if started then (
        debug "kleene is started";
        let (new_state, final) = (is_final sub_astd sub_state env call_path (current_key^"/"^(ASTD_astd.get_name sub_astd))) in
          if final then debug ("is final "^name) else debug ("isn't final "^name);
          (ASTD_state.Kleene_s (started,new_state,attributes_instances), final)
      )
      else (
        debug "kleene is not started, so is final";
        (state, true)
      )

  | ASTD_state.Synchronisation_s (sub_state1, sub_state2, attributes_instances) -> 
    let (name, synchro, attributes,optional_code, sub_astd1, sub_astd2) = ASTD_astd.get_data_synchronisation astd in
    let (new_state1, final1) = (is_final sub_astd1 sub_state1 env call_path (current_key^"/"^(ASTD_astd.get_name sub_astd1))) in
    let (new_state2, final2) = (is_final sub_astd2 sub_state2 env call_path (current_key^"/"^(ASTD_astd.get_name sub_astd2))) in
      (ASTD_state.Synchronisation_s (new_state1, new_state2, attributes_instances), final1 && final2)

  | ASTD_state.QChoice_s (qchoice, final_dom, unknown_dom, sub_state, attributes_instances) ->
    let (name, var, dom, attributes,optional_code, dep, sub_astd) = ASTD_astd.get_data_qchoice astd in
      if qchoice = ASTD_state.ChoiceNotMade then (
        let final = ref final_dom in
        let unknown = ref unknown_dom in
          while !final = ASTD_constant.empty_dom && !unknown <> ASTD_constant.empty_dom do
            let (head_val, tail_val) = ASTD_constant.head_tail !unknown in
              unknown := tail_val;
              let bind_env = ASTD_environment.bind_const var head_val in
              let env2 = (ASTD_environment.add_binding bind_env env) in
              let (_, sub_final) = is_final sub_astd (init sub_astd) env2 call_path (current_key^":"^(ASTD_constant.string_of head_val)^"/"^(ASTD_astd.get_name sub_astd)) in
                if sub_final then
                  final := ASTD_constant.insert (ASTD_constant.value_of head_val) !final
          done;
          (ASTD_state.QChoice_s (qchoice, !final, !unknown, ASTD_state.NotDefined, attributes_instances), !final <> ASTD_constant.empty_dom)
      ) else (
        let bind_env = ASTD_environment.bind var (ASTD_state.get_val qchoice) in
        let env2 = (ASTD_environment.add_binding bind_env env) in
        let (new_state, sub_final) = is_final sub_astd sub_state env2 call_path (current_key^":"^(ASTD_constant.string_of (ASTD_term.extract_constant_from_term (ASTD_state.get_val qchoice)))^"/"^(ASTD_astd.get_name sub_astd)) in
          if sub_final then debug ("is final "^name) else debug ("isn't final "^name);
          (ASTD_state.QChoice_s (qchoice, ASTD_constant.empty_dom, ASTD_constant.empty_dom, new_state, attributes_instances), sub_final)
      )
          


  | ASTD_state.QSynchronisation_s (not_final_domain, unknown_domain, not_init_domain, init_state, attributes_instances) ->
    let (name, var, dom, synchro, attributes,optional_code, dep, sub_astd) = ASTD_astd.get_data_qsynchronisation astd in
    let not_final = ref not_final_domain in
    let unknown = ref unknown_domain in
    while !not_final = ASTD_constant.empty_dom && !unknown <> ASTD_constant.empty_dom do
      let (head_val, tail_val) = ASTD_constant.head_tail !unknown in
        unknown:=tail_val;
        let bind_env = ASTD_environment.bind_const var head_val in
        let env2 = (ASTD_environment.add_binding bind_env env) in
          if (ASTD_constant.is_included head_val not_init_domain) then
            let sub_state = get_bdd current_key head_val in
            let (new_state, sub_final) = is_final sub_astd sub_state env2 call_path (current_key^":"^(ASTD_constant.string_of head_val)^"/"^(ASTD_astd.get_name sub_astd)) in
              if sub_final then (
                debug ("value final : "^(ASTD_constant.string_of head_val));
                register_bdd current_key head_val new_state
              ) else (
                debug ("value not final : "^(ASTD_constant.string_of head_val));
                not_final := ASTD_constant.insert (ASTD_constant.value_of head_val) !not_final ; 
                register_bdd current_key head_val new_state 
              )
          else
            let (_, sub_final) = is_final sub_astd init_state env2 call_path (current_key^":"^(ASTD_constant.string_of head_val)^"/"^(ASTD_astd.get_name sub_astd)) in
              if not sub_final then
                (not_final := ASTD_constant.insert (ASTD_constant.value_of head_val) !not_final)
    done;
    (ASTD_state.QSynchronisation_s  (!not_final,!unknown,not_init_domain,init_state,attributes_instances),!not_final =ASTD_constant.empty_dom)
      

  | ASTD_state.Guard_s (started, sub_state, attributes_instances) ->
    let (name, attributes,optional_code, guards, sub_astd) = ASTD_astd.get_data_guard astd in
    let (new_state, final) = is_final sub_astd sub_state env call_path (current_key^"/"^(ASTD_astd.get_name sub_astd)) in
    let guard_modules = ASTD_astd.get_guard_modules guards in
      if started then
        (ASTD_state.Guard_s (started,new_state,attributes_instances), final)
      else
        (ASTD_state.Guard_s (started, new_state, attributes_instances), (ASTD_arrow.evaluate_guard env guard_modules) && final)

  | ASTD_state.Call_s (called, sub_state) ->
    let (name, called_name, fct_vec) = ASTD_astd.get_data_call astd in
    let (called_astd, var_dom_list) = ASTD_astd.get_call_astd called_name in
    let call_env = ASTD_environment.get_call_env fct_vec env var_dom_list in
    let sub_astd = (ASTD_astd.call_astd called_name call_env) in
      if List.mem called_name call_path then
        (ASTD_state.Call_s (called,sub_state),false)
      else 
        if called then
          let (new_state, final) = is_final sub_astd sub_state call_env (called_name::call_path) (current_key^"/"^called_name) in
            (ASTD_state.Call_s (called, new_state), final)
        else
          let (_, final) = is_final sub_astd (init sub_astd) call_env (name::call_path) (current_key^"/"^called_name) in
            (state, final)

  | ASTD_state.Elem -> (ASTD_state.Elem, true)
  | ASTD_state.NotDefined -> (ASTD_state.NotDefined, false)






let rec modify_h hist name new_state =
  match hist with
  | (a, b)::q ->
    if a = name then
      (name,new_state)::q
    else
      (a, b)::(modify_h q name new_state)
  | [] -> failwith "history state not found"


let get_history_state h_list name : ASTD_state.t =
  try List.assoc name h_list
  with _ -> failwith "impossible history"

let goto_automata astd name h_list =
  match astd with
  | ASTD_astd.Automata (n,attributes,optional_code,astd_list,_,_,_,_) -> 
      if name = "H1" then
        let historic_state = get_history_state h_list n in
        let (historic_position, historic_history, historic_current_sub_state, historic_attributes_instances) = ASTD_state.get_data_automata_s historic_state in
          ASTD_state.automata_s_of
            historic_position
            (init_history astd_list)
            (init (ASTD_astd.find_subastd historic_position astd_list))
            (ASTD_attribute.init_all attributes)
      else if name = "H2" then
        get_history_state h_list n
      else (* Not an history state, we should go to the sub-astd with the name received in paremeters *)
        let new_s = init (ASTD_astd.find_subastd name astd_list) in
          ASTD_state.automata_s_of 
            name
            (init_history astd_list)
            new_s
            (ASTD_attribute.init_all attributes)
  | _ -> failwith "impossible transition "


(** Contatenates a modification with initial values
  Parameters
    current_key : id of current astd (contains the values of quantified variables from parent astds)
    modif : modification to add
    initial_values
      not_fin_dom : ?????
      unknown_dom : ????
      not_init_dom : ????
      to_save : updates to the qsync table
      kappa : ?????
  
  Returns
    modified_values
      updated_not_fin_dom : ????
      updated_unknown_dom : ????
      updated_not_init_dom : ????
      updated_to_save : updated to the qsync table
      updated_kappa : ????
  *)
let merge_modification current_key modif (not_fin_dom, unknown_dom, not_init_dom, to_save, kappa) =
  let (const, mod_state, returned_to_save, returned_kappa, is_final_state) = modif in
  let updated_not_fin_dom = (if is_final_state then ASTD_constant.remove (ASTD_constant.value_of const) not_fin_dom else ASTD_constant.insert (ASTD_constant.value_of const) not_fin_dom) in
  let updated_unknown_dom = (ASTD_constant.remove (ASTD_constant.value_of const) unknown_dom) in 
  let updated_not_init_dom = (ASTD_constant.insert (ASTD_constant.value_of const) not_init_dom) in 
  let updated_to_save = ((current_key, const), mod_state)::(returned_to_save@to_save) in 
  let updated_kappa = (returned_kappa@kappa) in
    (
      updated_not_fin_dom,
      updated_unknown_dom,
      updated_not_init_dom,
      updated_to_save,
      updated_kappa
    )
(** Contatenates all the modifications with initial values
  Parameters
    modifs : list of modifications
    not_fin_dom : ?????
    unknown_dom : ????
    not_init_dom : ????
    to_save : updates to the qsync table
    kappa : ?????
    current_key : id of current astd (contains the values of quantified variables from parent astds)

  Returns
    modified_values
      updated_not_fin_dom : ????
      updated_unknown_dom : ????
      updated_not_init_dom : ????
      updated_to_save : updated to the qsync table
      updated_kappa : ????
  *)
let merge_all_modifications modifs not_fin_dom unknown_dom not_init_dom to_save kappa current_key =
  List.fold_right
    (merge_modification current_key)
    modifs
    (not_fin_dom, unknown_dom, not_init_dom, to_save, kappa)
    
(** For each captured variable in the transition's parameters, it creates a binding with the corresponding event's constant and add it to the environment.
  Parameters
    env : current env
    transition : transition which may contain captured variables
    event : event received
  Returns
    local_transition_env : Environement with the bindings coming from the transition's captured variables
  *)
let add_local_transition_captured_constant_to_env env transition event =
  let captures = ASTD_transition.get_captures_from_transition_and_event transition event in 
  let bindings = 
    List.map 
    (fun capture -> 
      ASTD_environment.bind_const (ASTD_transition.get_captured_variable capture) (ASTD_transition.get_captured_constant capture))
    captures 
  in
  let local_transition_env = ASTD_environment.add_all_bindings bindings env in
    local_transition_env

let remove_local_transition_captured_constant_from_env env transition =
  let captured_variables = ASTD_transition.get_captured_variables_from_transition transition in 
    ASTD_environment.remove_all captured_variables env

(** Validates an arrow for the event against the environment
  Parameters
    event : event received
    env : environment
    arrow : arrow to evaluate
  Returns
    is_arrow_valid : a boolean indicating whether the arrow is valid or not for the event
  *)
let is_valid_arrow event env arrow = 
  let local_transition_env = add_local_transition_captured_constant_to_env env (ASTD_arrow.get_transition arrow) event in
  let guard_modules = ASTD_astd.get_guard_modules (ASTD_arrow.get_guards arrow) in
    ASTD_arrow.valid_arrow event local_transition_env arrow guard_modules
  
(** Finds an arrow (transition) that can accept the event received
  Params :
    arrow_list : List of arrows in which to look for a valid arrow
    event : event received
    current_state_name : name of the current state of the automata astd (considered the from state of the arrow)
    sub_state : current sub state of the automata
    sub_astd : current sub astd of the automata
    env : environment containing quantification variables
    current_key : id of current astd (contains the values of quantified variables from parent astds)
  Returns :
    Optional
      arrow : ASTD_arrow found
      state : new state pointed by arrow
 *)
let rec find_arrow_internal arrow_list event current_state_name sub_state sub_astd env current_key =
  match arrow_list with
  | ASTD_arrow.Local ( from,to_state,transition,guards,final,optional_action)::tail -> 
    if (current_state_name = from) && ((ASTD_event.get_label event) = (ASTD_transition.get_label transition)) then
      if final then
        let (new_state, final) = (is_final sub_astd sub_state env [] current_key) in
          if final then
            if is_valid_arrow event env (List.hd arrow_list) then
              Some (ASTD_arrow.Local ( from,to_state,transition,guards,final,optional_action), new_state)
            else
              find_arrow_internal tail event current_state_name new_state sub_astd env current_key
          else
            find_arrow_internal tail event current_state_name new_state sub_astd env current_key
      else
        if is_valid_arrow event env (List.hd arrow_list) then
          Some (ASTD_arrow.Local ( from,to_state,transition,guards,final,optional_action), sub_state)
        else
          find_arrow_internal tail event current_state_name sub_state sub_astd env current_key 
    else find_arrow_internal tail event current_state_name sub_state sub_astd env current_key

  | ASTD_arrow.From_sub ( from,to_state,through,transition,guards,final,optional_action)::tail ->
    if (through = current_state_name)
        &&
        ((ASTD_event.get_label event) = (ASTD_transition.get_label transition))
        && 
        (ASTD_astd.is_automata sub_astd)
    then 
      let (sub_from, hist, sub_state2, attributes_instances) = ASTD_state.get_data_automata_s sub_state in
        if from = sub_from then
          let sub_env = ASTD_environment.add_attributes_to_env attributes_instances env in 
            if final then
              let (new_sub_state,final)=(is_final (ASTD_astd.find_subastd sub_from (ASTD_astd.get_sub sub_astd)) sub_state2 env [] current_key) in
              let new_state = ASTD_state.Automata_s (sub_from,hist,new_sub_state,attributes_instances) in
              if final then
                if is_valid_arrow event sub_env (List.hd arrow_list) then
                  Some (ASTD_arrow.From_sub ( from,to_state,through,transition,guards,final,optional_action), new_state)
                else find_arrow_internal tail event current_state_name new_state sub_astd env current_key
              else find_arrow_internal tail event current_state_name new_state sub_astd env current_key
            else if is_valid_arrow event sub_env (List.hd arrow_list) then
              Some (ASTD_arrow.From_sub ( from,to_state,through,transition,guards,final,optional_action), sub_state)
            else find_arrow_internal tail event current_state_name sub_state sub_astd env current_key
        else find_arrow_internal tail event current_state_name sub_state sub_astd env current_key
    else find_arrow_internal tail event current_state_name sub_state sub_astd env current_key

  | ASTD_arrow.To_sub ( from,to_state,through,transition,guards,final,optional_action)::tail -> 
    if (current_state_name = from)
        &&
        ((ASTD_event.get_label event) = (ASTD_transition.get_label transition))
    then
      if final then
        let (new_state, final) = is_final sub_astd sub_state env [] current_key in
          if final then
            if is_valid_arrow event env (List.hd arrow_list) then
              Some (ASTD_arrow.To_sub (from, to_state, through, transition, guards, final, optional_action), new_state)
            else
              find_arrow_internal tail event current_state_name new_state sub_astd env current_key
          else
            find_arrow_internal tail event current_state_name new_state sub_astd env current_key
      else if is_valid_arrow event env (List.hd arrow_list) then
        Some (ASTD_arrow.To_sub (from, to_state, through, transition, guards, final, optional_action), sub_state)
      else
        find_arrow_internal tail event current_state_name sub_state sub_astd env current_key
    else
      find_arrow_internal tail event current_state_name sub_state sub_astd env current_key
  | [] -> None

(** Finds an arrow (transition) that can accept the event received
  Params :
    arrow_list : List of arrows in which to look for a valid arrow
    event : event received
    current_state_name : name of the current state of the automata astd (considered the from state of the arrow)
    sub_state : current sub state of the automata
    sub_astd : current sub astd of the automata
    env : environment containing quantification variables
    current_key : id of current astd (contains the values of quantified variables from parent astds)
  Returns :
    Optional
      arrow : ASTD_arrow found
      state : new state pointed by arrow
 *)
let find_arrow arrow_list event current_state_name sub_state sub_astd env current_key =
  match arrow_list with
  | h::t -> find_arrow_internal arrow_list event current_state_name sub_state sub_astd env current_key
  | [] -> failwith "an automata should have at least one transition"

(** Gets the value from the event which is associated to the variable in the transition
  Ex 1: var = x, transition = e(x,y), event = e(1,2)
        Returns 1 because it is at the same position in the event as x is in the transition
  Ex 2: var = x, transition = e(y,x), event = e(1,2)
        Returns 2
  Ex 3: var = x, transition = e(y,z), event = e(1,2)
        Returns None
  *)
let rec get_value_associated_to_variable variable_name event_params transition_params =
  match (event_params, transition_params) with 
  | (event_params_head :: event_params_tail, transition_params_head :: transition_params_tail) ->
      if ASTD_transition.is_parameter_a_term transition_params_head then
        let term_of_parameter = ASTD_transition.term_from_parameter transition_params_head in 
          if ASTD_term.is_term_a_variable term_of_parameter && (ASTD_term.variable_name_of_term term_of_parameter) = variable_name then 
            Some event_params_head
          else
            get_value_associated_to_variable variable_name event_params_tail transition_params_tail
      else 
        get_value_associated_to_variable variable_name event_params_tail transition_params_tail
  | _ -> None

(** Gets the values from the event's parameters that can be associated to the variable in any of the transitions (or transitions of child-astd)
    of the astd.

  Ex 1: Two transitions accepting e(x,y) and e(y,x), var = x and event = e(1,2)
        Then x can take values 1 and 2, but it is determinist.
  Ex 2: Two transitions accepting e(x,y) and e(y,x), var = x and event = e(1,1)
        Then x can only take value 1, but it is indeterminist because it may be any transition of the two.
  Ex 3: Two transitions both accepting e(x) and e(x), var = x and event = e(1)
        Then x can take value 1, but it is indeterminist because it may be any transition of the two.
  Ex 4: Two transitions accepting e(x) and e(y), var = x and event = e(1)
        Then x can take value 1, but it is indeterminist because the targeted transition could also be e(y) where y = 1.
  Ex 5: One transition accepting e(y), var = x and event = e(1)
        Then x can take no value, and it is considered indeterminist because transition e(y) could accept it for y = 1.

  Parameters
    event : event to execute
    astd : astd that receives the event
    var : variable for which we want the associated values from the event's parameters

  Returns
    values : values that the variable can take in a transition
    indeterminist : boolean indicating that
                    more than one transition accept the same value for the variable (the two transitions are then possible with this value)
                    or if there was transitions which did not contain the variable (they can also accept the transition, regardless of the variable)
  *)
let get_values event astd (var_name : ASTD_variable.name) = 
  let event_params = ASTD_event.get_const event in
  let transitions = ASTD_astd.get_sub_transitions astd in 
  let valid_transitions = List.filter (ASTD_transition.is_transition_valid_for_event event) transitions in
  let params_list_of_valid_transitions = List.map ASTD_transition.get_params valid_transitions in
  let params_list_containing_the_variable = List.filter (ASTD_transition.is_variable_name_in_params var_name) params_list_of_valid_transitions in
  let optional_values_in_params_for_variable = List.map (get_value_associated_to_variable var_name event_params) params_list_containing_the_variable in
  let filtered_optional_values_in_params_for_variable = List.filter ASTD_functions.optional_has_value optional_values_in_params_for_variable in
  let values_in_params_for_variable = List.map ASTD_functions.get_optional_value filtered_optional_values_in_params_for_variable in
  let distinct_values_in_params_for_variable = ASTD_functions.remove_duplicates_from_left values_in_params_for_variable in
  (* It is indeterminist if more than one transition accepts the same value for the variable (the two transition are then possible with this value)
     or
     if there was transitions which did not contain the variable (they can also accept the transition) *)
  let indeterminist
    = (List.length values_in_params_for_variable) <> (List.length distinct_values_in_params_for_variable)
      ||
      (List.length params_list_of_valid_transitions) <> (List.length params_list_containing_the_variable) 
  in
    (distinct_values_in_params_for_variable, indeterminist)

let rec find_value_indirect event astd env dep_path_list var_name = 
  match dep_path_list with
  | (ASTD_optimisation.Dep_path (variable, dep, dep_path_list2))::tail -> 
      if var_name = variable then (
        debug ("found dep to follow for " ^ var_name);
        let (_, var_met, _, _, _) = dep in
        let values = List.map (find_value_indirect event astd env dep_path_list2) var_met in
          debug ("found values for dep for " ^ var_name);
          ASTD_optimisation.get_kappa dep values 
      ) else (
        find_value_indirect event astd env tail var_name
      )
  | [] ->
      debug ("try in env for " ^ var_name);
      try
        ASTD_environment.find_value_from_variable_name env var_name
      with
        | Not_found ->
            debug ("try to retrieve kappa indirect threw kappa direct for "^var_name);
            let (qchoice,indeter)=(get_values event astd var_name) in
              if List.length qchoice = 1 then (
                debug "get val to apply ";
                let value_ext = List.hd qchoice in
                  debug "value extracted";
                  ASTD_term.const_of value_ext
              ) else (
                failwith "impossible to kappa optimize indirect (find value)"
              )

let rec active_optimisation event astd env label var opt_list =
  match opt_list with
  | (label2, path, variable, dep_path)::tail ->
      if label = label2 then (
        debug ("found_label " ^ label ^ " in active opt");
        ASTD_state.Val(find_value_indirect event astd env [dep_path] var)
      ) else (
        active_optimisation event astd env label var tail
      )
  | [] ->
      debug ("NOT found label " ^ label ^ " in active opt");
      ASTD_state.ChoiceNotMade
    

(** Execute the client optional_code from an action and returns the updated environment.
  Parameters
    optional_action : Optional action to execute
    env_acc : current environment accessor
  Returns
    updated_env : updated environment with values updated by the client's optional_code
 *)
let execute_action env_acc optional_action =
  match optional_action with
  | Some action -> 
      let action_id = ASTD_action.get_id action in 
      let optional_module = ASTD_astd.get_action action_id in 
        if ASTD_functions.optional_has_value optional_module then (
          let module Executable_module = (val ASTD_functions.get_optional_value optional_module) in
            try
              Executable_module.execute_action env_acc
            with
              exn ->
                print_endline ("Action execution failed with client error : " ^ (Printexc.to_string exn));
                env_acc
        ) else (
          print_endline "Action is missing, no optional_code executed.";
          env_acc
        )
  | None ->
      env_acc

let execute_action_internal env optional_action =
  let environment_accessor = new ASTD_environment.environment_accessor env in
  let updated_environment_accessor = execute_action environment_accessor optional_action in
    updated_environment_accessor#get_env

(** Prepare the environment for execution of the transition's action and then execute the code for the automata
  Parameters
    env : current environment of the automata (including its attributes)
    transition : transition that accepts the event
    event : current event
    optional_action : action of the transition
    optional_code : code of the automata
  Returns
    updated_env : udpated environment containing modifications from the action and the code
  *)
let execute_action_and_code_for_automata env transition event optional_action optional_code =
  let local_transition_env = add_local_transition_captured_constant_to_env env transition event in 
  let updated_local_transition_env = execute_action_internal local_transition_env optional_action in
  let updated_sub_env_for_code = remove_local_transition_captured_constant_from_env updated_local_transition_env transition in 
    execute_action_internal updated_sub_env_for_code optional_code

let try_execute_code is_modified env astd = 
  if is_modified 
  then (* Execute code *)
    execute_action_internal env (ASTD_astd.get_optional_code astd)
  else 
    env

(** Update the environment to reflect changes made to a possible non-readonly variable assigned to a parameter during a call.

  The parameter_assignation contains the parameter name and its assigned term, as defined in the call astd.
  If the term assigned to the parameter is a variable name refering to a non-readonly variable of the current environment,
  then we will update the variable's assigned value in the environment to reflect changes that were made during the call.

  Parameters
    env : current environment
    call_env : environment returned by the called astd, containing the updated parameters' values
    parameter_assignation : a pair of the variable name of the parameter and the term that is assigned to it
  Returns
    updated_env : updated environment
  *)
let update_env_from_parameter_assignation env call_env parameter_assignation =
  let parameter_variable_name, argument_term = parameter_assignation in 
  if ASTD_term.is_term_a_variable argument_term then
    let variable_name = ASTD_term.variable_name_of_term argument_term in 
    let variable = ASTD_environment.find_complete_key_infos env variable_name in
    if not (ASTD_variable.is_readonly variable) then 
      let value = ASTD_environment.find_value_from_variable_name call_env parameter_variable_name in
        ASTD_environment.add_binding (ASTD_environment.bind variable value) env
    else
      env
  else
    env

(** Update the environment to reflect changes made to non-readonly variables assigned to parameters during a call.

  The parameter_assignation contains the parameter name and its assigned term, as defined in the call astd.
  If the term assigned to the parameter is a variable name refering to a non-readonly variable of the current environment,
  then we will update the variable's assigned value in the environment to reflect changes that were made during the call.

  Parameters
    env : current environment
    call_env : environment returned by the called astd, containing the updated parameters' values
    parameter_assignation : a pair of the variable name of the parameter and the term that is assigned to it
  Returns
    updated_env : updated environment
  *)
let update_env_with_call_result env call_env fct_vec =
  List.fold_right (fun assignation env -> update_env_from_parameter_assignation env call_env assignation) fct_vec env

(** Executes an event on the astd if possible and reports about the effects of the execution.
  Params
    state : current state of the targeted astd
    astd : the targeted astd
    event : the event sent
    env : the current evaluation environment (containing quantified variables and attributes)
    current_key : id of current astd (contains the values of quantified variables from parent astds). 
        Format : Main/astd_name/child_astd_name:quantified_variable_value/sub_child_astd_name

  Returns 
    new_state : new state of the targeted astd
    to_save : qsync table updates 
    kappa : ???????
    is_modified : boolean value indicating whether or not the event was accepted
    updated_env : environment updated with new attributes values
  *)
let rec execute state astd event env current_key = 
debug "*** started execute";
let label_list = List.map ASTD_transition.get_label (ASTD_astd.get_sub_transitions astd) in
if not (List.mem (ASTD_event.get_label event) label_list) then
  (state, [], [], false, env) 
else
  match state with 
  | ASTD_state.Automata_s (current_state_name, state_history_list, current_sub_state, attributes_instances) ->
      debug ("aut exec "^(ASTD_astd.get_name astd));
      let sub_env = ASTD_environment.add_attributes_to_env attributes_instances env in
      let (_,attributes,optional_code,sub_astd_list, arrow_list, _, _, _) = ASTD_astd.get_data_automata astd in
      let current_sub_astd = ASTD_astd.find_subastd current_state_name sub_astd_list in (
        match 
          find_arrow
            arrow_list
            event
            current_state_name
            current_sub_state
            current_sub_astd
            sub_env
            (current_key ^ "/" ^ current_state_name)
        with
        | Some (arrow, new_state) -> (* If found, means that the transition is valid (event name is correct, params are ok, final rules are respected, etc.)*)
            let transition = ASTD_arrow.get_transition arrow in
            let new_hist = 
              if ASTD_state.is_automata new_state
              then modify_h state_history_list current_state_name new_state
              else state_history_list
            in 
              if ASTD_arrow.is_to_sub arrow then (* to sub arrow *)
                let dest = ASTD_arrow.get_to arrow in
                let through = ASTD_arrow.get_through arrow in
                let new_sub_astd = ASTD_astd.find_subastd through sub_astd_list in
                let optional_action = ASTD_arrow.get_optional_action arrow in
                let optional_code = ASTD_astd.get_optional_code astd in
                let updated_sub_env = execute_action_and_code_for_automata sub_env transition event optional_action optional_code in
                let new_sub_state = goto_automata new_sub_astd dest new_hist in
                let (updated_attributes_instances, updated_env) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env in
                let new_state = ASTD_state.Automata_s (through, new_hist, new_sub_state, updated_attributes_instances) in
                  (new_state,
                  [],
                  [],
                  true,
                  updated_env)
              else if ASTD_arrow.is_from_sub arrow then ( (* from sub arrow *)
                let dest = ASTD_arrow.get_to arrow in
                let attributes_of_from_sub_astd = ASTD_state.get_attributes current_sub_state in
                let from_sub_env = ASTD_environment.add_attributes_to_env attributes_of_from_sub_astd sub_env in 
                let new_sub_astd = ASTD_astd.find_subastd dest sub_astd_list in
                let optional_action = ASTD_arrow.get_optional_action arrow in
                let optional_code = ASTD_astd.get_optional_code astd in
                let updated_from_sub_env = execute_action_and_code_for_automata from_sub_env transition event optional_action optional_code in
                let (from_sub_updated_attributes_instances, updated_sub_env) = ASTD_environment.extract_attributes_from_env attributes_of_from_sub_astd updated_from_sub_env in
                let (updated_attributes_instances, updated_env) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env in
                (* We are exiting the from_sub astd, we need to update its attributes in the history list because they may have been modified during the execution of the action *)
                let new_from_sub_state = ASTD_state.set_attributes_instances current_sub_state from_sub_updated_attributes_instances in
                let new_history_with_from_sub_attributes = modify_h new_hist current_state_name new_from_sub_state in
                let new_state = ASTD_state.Automata_s (dest, new_history_with_from_sub_attributes, init new_sub_astd, updated_attributes_instances) in
                  (new_state,
                  [],
                  [],
                  true,
                  updated_env)
              ) else ( (* Local arrow *)
                let dest = ASTD_arrow.get_to arrow in
                let new_sub_astd = ASTD_astd.find_subastd dest sub_astd_list in
                let optional_action = ASTD_arrow.get_optional_action arrow in
                let optional_code = ASTD_astd.get_optional_code astd in
                let updated_sub_env = execute_action_and_code_for_automata sub_env transition event optional_action optional_code in
                let (updated_attributes_instances, updated_env) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env in
                let new_state = ASTD_state.Automata_s (dest, new_hist, init new_sub_astd, updated_attributes_instances) in
                  (new_state,
                  [],
                  [],
                  true,
                  updated_env)
              )
        | None -> (* No valid arrow was found, we expect that maybe the current sub-astd is the one that can receive the event *)
            let (mod_state, to_save, kappa, is_modified, modified_sub_env) = execute current_sub_state current_sub_astd event sub_env (current_key ^ "/" ^ current_state_name) in
            let updated_sub_env_after_code_exec = try_execute_code is_modified modified_sub_env astd in
            let (updated_attributes_instances, modified_env) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env_after_code_exec in
              (ASTD_state.Automata_s (current_state_name, state_history_list, mod_state, updated_attributes_instances),
              to_save,
              kappa,
              is_modified,
              modified_env)
      )


  | ASTD_state.Sequence_s (step, sub_state, attributes_instances) -> 
      debug ("seq exec " ^ (ASTD_astd.get_name astd));
      let (_, attributes,optional_code, first_astd, second_astd) = ASTD_astd.get_data_sequence astd in
        if step = ASTD_state.Fst then (* The Sequence ASTD is in its first step (first astd) *)
          let sub_env = ASTD_environment.add_attributes_to_env attributes_instances env in
          let (mod_state, to_save, kappa, is_modified, modified_sub_env) = execute sub_state first_astd event sub_env (current_key ^ "/" ^ (ASTD_astd.get_name first_astd) ) in
          let updated_sub_env_after_code_exec = try_execute_code is_modified modified_sub_env astd in
          let (updated_attributes_instances, modified_env) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env_after_code_exec in
            if is_modified then (* First astd accepted the event *)
              (ASTD_state.Sequence_s (step, mod_state, updated_attributes_instances),
              to_save,
              kappa,
              true,
              modified_env)
            else (* First astd rejected the event, we may need to pass to the second *)
              let (new_state, final) = (is_final first_astd mod_state env [] (current_key ^ "/" ^ (ASTD_astd.get_name first_astd) )) in
                if final then (* First astd is final, we can try to execute the action on the second *)
                  let sub_env = ASTD_environment.add_attributes_to_env attributes_instances env in
                  let (mod_state2, to_save2, kappa2, is_modified2, modified_sub_env) = execute (init second_astd) second_astd event sub_env (current_key ^ "/" ^ (ASTD_astd.get_name second_astd) ) in
                  let updated_sub_env_after_code_exec = try_execute_code is_modified2 modified_sub_env astd in
                  let (updated_attributes_instances, modified_env) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env_after_code_exec in
                    if is_modified2 then (* The second astd accepted the event *)
                      (ASTD_state.Sequence_s (ASTD_state.Snd, mod_state2, updated_attributes_instances),
                      to_save2,
                      kappa2,
                      true,
                      modified_env)
                    else (* The second astd didn't accept the event. The event is rejected *)
                      (state, [], [], false, modified_env) 
                else (* The first is not final, we cannot try to execute the event on the second, so the event is rejected. *)
                  (state, [], [], false, env)
        else (* The Sequence ASTD is in its second step (second astd) *)
          let sub_env = ASTD_environment.add_attributes_to_env attributes_instances env in
          let (mod_state, to_save, kappa, is_modified, modified_sub_env) = execute sub_state second_astd event sub_env (current_key^"/"^(ASTD_astd.get_name second_astd) ) in
          let updated_sub_env_after_code_exec = try_execute_code is_modified modified_sub_env astd in
          let (updated_attributes_instances, modified_env) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env_after_code_exec in
            if is_modified then (* The second astd accepted the event *)
              (ASTD_state.Sequence_s (step,mod_state, updated_attributes_instances),
              to_save,
              kappa,
              true,
              modified_env)
            else (* The second astd didn't accept the event. The event is rejected *)
              (state, [], [], false, modified_env) 

  | ASTD_state.Choice_s (side, state2, attributes_instances) -> 
      debug ("choice exec " ^ (ASTD_astd.get_name astd));
      let (name, attributes,optional_code, astd1, astd2) = ASTD_astd.get_data_choice astd in
        if side = ASTD_state.Right then
          let sub_env = ASTD_environment.add_attributes_to_env attributes_instances env in
          let (mod_state, to_save, kappa, is_modified, modified_sub_env) = execute state2 astd2 event sub_env (current_key ^ "/" ^ (ASTD_astd.get_name astd2)) in
          let updated_sub_env_after_code_exec = try_execute_code is_modified modified_sub_env astd in
          let (updated_attributes_instances, modified_env) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env_after_code_exec in
            if is_modified then
              (ASTD_state.Choice_s (side, mod_state, updated_attributes_instances),
              to_save,
              kappa,
              is_modified,
              modified_env)
            else
              (state, [], [], false, modified_env) 
        else if side = ASTD_state.Left then
          let sub_env = ASTD_environment.add_attributes_to_env attributes_instances env in
          let (mod_state, to_save, kappa, is_modified, modified_sub_env) = execute state2 astd1 event sub_env (current_key ^ "/" ^ (ASTD_astd.get_name astd1)) in
          let updated_sub_env_after_code_exec = try_execute_code is_modified modified_sub_env astd in
          let (updated_attributes_instances, modified_env) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env_after_code_exec in
            if is_modified then
              (ASTD_state.Choice_s (side, mod_state, updated_attributes_instances),
              to_save,
              kappa,
              is_modified,
              modified_env)
            else
              (state, [], [], false, modified_env) 
        else
          let sub_env = ASTD_environment.add_attributes_to_env attributes_instances env in
          let (mod_state, to_save1, kappa1, is_modified, modified_sub_env) = execute (init astd1) astd1 event sub_env (current_key ^ "/" ^ (ASTD_astd.get_name astd1)) in
          let updated_sub_env_after_code_exec = try_execute_code is_modified modified_sub_env astd in
          let (updated_attributes_instances, modified_env) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env_after_code_exec in
            if is_modified then
              (ASTD_state.Choice_s (ASTD_state.Left, mod_state, updated_attributes_instances),
              to_save1,
              kappa1,
              is_modified,
              modified_env)
            else
              let (mod_state2, to_save2, kappa2, is_modified2, modified_sub_env2) = execute (init astd2) astd2 event sub_env (current_key ^ "/" ^ (ASTD_astd.get_name astd2)) in
              let updated_sub_env_after_code_exec = try_execute_code is_modified2 modified_sub_env2 astd in
              let (updated_attributes_instances2, modified_env2) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env_after_code_exec in
                if is_modified2 then
                  (ASTD_state.Choice_s (ASTD_state.Right, mod_state2, updated_attributes_instances2),
                  to_save2,
                  kappa2,
                  is_modified2,
                  modified_env2)
                else
                  (state, [], [], false, modified_env2) 

  | ASTD_state.Kleene_s (started, state2, attributes_instances) ->  
      debug ("kleene exec " ^ (ASTD_astd.get_name astd));
      let (name, attributes,optional_code, astd2) = ASTD_astd.get_data_kleene astd in
      let sub_env = ASTD_environment.add_attributes_to_env attributes_instances env in
      let (mod_state, to_save, kappa, is_modified, modified_sub_env) = execute state2 astd2 event sub_env (current_key ^ "/" ^ (ASTD_astd.get_name astd2)) in
      let updated_sub_env_after_code_exec = try_execute_code is_modified modified_sub_env astd in      
      let (updated_attributes_instances, modified_env) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env_after_code_exec in
        if started then
          if is_modified then (
            debug ("kleene modified " ^ name);
            if mod_state = (init astd2) then (
              debug "kleene reports child is at init";
              (ASTD_state.Kleene_s (false, mod_state, updated_attributes_instances),
              to_save,
              kappa,
              true,
              modified_env)
            ) else (
              debug "kleene reports child is not init";
              (ASTD_state.Kleene_s (true, mod_state, updated_attributes_instances),
              to_save,
              kappa,
              true,
              modified_env)
            )
          )
          else
            let (new_state, isfinal) = (is_final astd2 state2 env [] (current_key ^ "/" ^ (ASTD_astd.get_name astd2))) in
              if isfinal then (
                debug ("restart kleene " ^ name); 
                let (mod_state2, to_save2, kappa2, is_modified2, modified_sub_env2) = execute (init astd2) astd2 event sub_env (current_key ^ "/" ^ (ASTD_astd.get_name astd2)) in
                let updated_sub_env_after_code_exec = try_execute_code is_modified2 modified_sub_env2 astd in      
                let (updated_attributes_instances2, modified_env2) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env_after_code_exec in
                  if is_modified2 then
                    (ASTD_state.Kleene_s (started, mod_state2, updated_attributes_instances2),
                    to_save2,
                    kappa2,
                    is_modified2,
                    modified_env2)
                  else
                    (state, [], [], false, modified_env2) 
              ) else (
                debug ("restart impossible kleene " ^ name);
                (state, [], [], false, modified_env)
              )
        else (
          debug ("kleene not started " ^ name);
          if is_modified then
            (ASTD_state.Kleene_s (true, mod_state, updated_attributes_instances),
            to_save,
            kappa,
            is_modified,
            modified_env)
          else
            (state, [], [], false, modified_env)
        )

  | ASTD_state.Synchronisation_s (state1, state2, attributes_instances) -> 
      debug ("synch exec "^(ASTD_astd.get_name astd));
      let (name, transition_list, attributes,optional_code, astd1, astd2) = ASTD_astd.get_data_synchronisation astd in
      let sub_env = ASTD_environment.add_attributes_to_env attributes_instances env in
        if List.mem (ASTD_event.get_label event) transition_list then
          let (mod_state, to_save1, kappa1, is_modified, modified_sub_env) = execute state1 astd1 event sub_env (current_key ^ "/" ^ (ASTD_astd.get_name astd1)) in
          let (mod_state2, to_save2, kappa2, is_modified2, modified_sub_env2) = execute state2 astd2 event sub_env (current_key ^ "/" ^ (ASTD_astd.get_name astd2)) in
          let updated_sub_env_after_code_exec = try_execute_code (is_modified && is_modified2) sub_env astd in      
          let (updated_attributes_instances, modified_env) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env_after_code_exec in
            if is_modified && is_modified2 then
              (ASTD_state.Synchronisation_s (mod_state, mod_state2, updated_attributes_instances),
              to_save1@to_save2,
              kappa1@kappa2,
              true,
              modified_env)
            else
              (state, [], [], false, env) 
        else 
          let (mod_state, to_save, kappa, is_modified, modified_sub_env) = execute state1 astd1 event sub_env (current_key ^ "/" ^ (ASTD_astd.get_name astd1)) in
          let updated_sub_env_after_code_exec = try_execute_code is_modified modified_sub_env astd in      
          let (updated_attributes_instances, modified_env) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env_after_code_exec in
            if is_modified then
              (ASTD_state.Synchronisation_s (mod_state, state2, updated_attributes_instances),
              to_save,
              kappa,
              true,
              modified_env)
            else
              let (mod_state2, to_save2, kappa2, is_modified2, modified_sub_env2) = execute state2 astd2 event sub_env (current_key ^ "/" ^ (ASTD_astd.get_name astd2)) in
              let updated_sub_env_after_code_exec = try_execute_code is_modified2 modified_sub_env2 astd in      
              let (updated_attributes_instances2, modified_env2) = ASTD_environment.extract_attributes_from_env updated_attributes_instances updated_sub_env_after_code_exec in
                if is_modified2 then
                  (ASTD_state.Synchronisation_s (mod_state, mod_state2, updated_attributes_instances2),
                  to_save2,
                  kappa2,
                  true,
                  modified_env2)
                else
                  (state, [], [], false, env) 

  | ASTD_state.Guard_s (started, state2, attributes_instances) -> 
      debug ("guard exec "^(ASTD_astd.get_name astd));
      let (name, attributes,optional_code, guards, astd2) = ASTD_astd.get_data_guard astd in
      let guard_modules = ASTD_astd.get_guard_modules guards in
      let sub_env = ASTD_environment.add_attributes_to_env attributes_instances env in
        if started then
          let (mod_state, to_save, kappa, is_modified, modified_sub_env) = execute state2 astd2 event sub_env (current_key ^ "/" ^ (ASTD_astd.get_name astd2)) in
          let updated_sub_env_after_code_exec = try_execute_code is_modified modified_sub_env astd in      
          let (updated_attributes_instances, modified_env) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env_after_code_exec in
            (ASTD_state.Guard_s (started, mod_state, updated_attributes_instances),
            to_save,
            kappa,
            is_modified,
            modified_env)
        else if (ASTD_arrow.evaluate_guard env guard_modules) then
          let (mod_state,to_save,kappa,is_modified,modified_sub_env) = execute state2 astd2 event sub_env (current_key^"/"^(ASTD_astd.get_name astd2) ) in
          let updated_sub_env_after_code_exec = try_execute_code is_modified modified_sub_env astd in                
          let (updated_attributes_instances, modified_env) = ASTD_environment.extract_attributes_from_env attributes_instances updated_sub_env_after_code_exec in
            (ASTD_state.Guard_s (true, mod_state, updated_attributes_instances),
            to_save,
            kappa,
            is_modified,
            modified_env)
        else
          (state, [], [], false, env)




  | ASTD_state.QChoice_s (val_used, final_dom, unknown_dom, sub_state, attributes_instances) -> 
      debug ("qchoice exec " ^ (ASTD_astd.get_name astd));
      let (name, var, domain_of_value, attributes,optional_code, dependency_list, sub_astd) = ASTD_astd.get_data_qchoice astd in
        if val_used = ASTD_state.ChoiceNotMade then (
          debug "trying some values";
          let (direct_val, indeterminist) = get_values event sub_astd (ASTD_variable.get_name var) in
          let sub_env = ASTD_environment.add_attributes_to_env attributes_instances env in
          let optional_code = ASTD_astd.get_optional_code astd in
            let (mod_state, to_save, kappa, is_modified, modified_sub_env)
              = try_qchoice 
                  dependency_list
                  (ASTD_event.get_label event)
                  sub_state
                  sub_astd
                  var 
                  event 
                  sub_env 
                  domain_of_value 
                  direct_val 
                  indeterminist 
                  current_key
                  attributes_instances
                  optional_code
            in
              (mod_state, 
              to_save, 
              kappa, 
              is_modified, 
              modified_sub_env)
        ) else ( 
          debug ("qchoice " ^ (ASTD_variable.get_name var) ^ " choice using " ^ (ASTD_term.string_of (ASTD_state.get_val val_used)) ^ " for the astd " ^ name);
          let bind_env = ASTD_environment.bind var (ASTD_state.get_val val_used) in
          let sub_env = ASTD_environment.add_attributes_to_env attributes_instances env in
          let sub_env_with_quantified_vars = ASTD_environment.add_binding bind_env sub_env in
          let (mod_state, to_save, kappa, is_modified, modified_sub_env_with_quantified_vars) = execute sub_state sub_astd event sub_env_with_quantified_vars (current_key ^ ":" ^ (ASTD_constant.string_of (ASTD_term.extract_constant_from_term (ASTD_state.get_val val_used))) ^ "/" ^ (ASTD_astd.get_name sub_astd)) in
          let updated_sub_env_after_code_exec = try_execute_code is_modified modified_sub_env_with_quantified_vars astd in                
          let modified_sub_env = ASTD_environment.remove var updated_sub_env_after_code_exec in
          let (updated_attributes_instances, modified_env) = ASTD_environment.extract_attributes_from_env attributes_instances modified_sub_env in
            (ASTD_state.QChoice_s (val_used, final_dom, unknown_dom, mod_state, updated_attributes_instances),
            to_save,
            (ASTD_optimisation.automatic_gestion_of_kappa_values env (ASTD_event.get_label event) dependency_list (ASTD_state.get_val val_used))@kappa,
            is_modified,
            modified_env)
        )


  | ASTD_state.QSynchronisation_s (not_fin_dom, unknown_dom, not_init_dom, init_state, attributes_instances) -> 
      debug ("qsynch exec " ^ (ASTD_astd.get_name astd));
      let (name, var, val_list, trans_list, attributes,optional_code, opt, sub_astd) = ASTD_astd.get_data_qsynchronisation astd in (
        try
          let value2 = active_optimisation event astd env (ASTD_event.get_label event) (ASTD_variable.get_name var) opt in
            if not (value2 = ASTD_state.ChoiceNotMade) then (
              debug ("kappa indirect " ^ (ASTD_variable.get_name var) ^ " " ^ (ASTD_term.string_of (ASTD_state.get_val value2)) ^ " for the astd " ^ name);
              if (List.mem (ASTD_event.get_label event) trans_list) || (not (ASTD_constant.is_included (ASTD_term.extract_constant_from_term (ASTD_state.get_val value2)) val_list)) then
                (state, [], [], false, env)
              else ( 
                let bind_env = ASTD_environment.bind var (ASTD_state.get_val value2) in
                let sub_env = ASTD_environment.add_attributes_to_env attributes_instances env in
                let sub_env_quantified_var = ASTD_environment.add_binding bind_env sub_env in
                let value = ASTD_term.extract_constant_from_term (ASTD_state.get_val value2) in
                let value'= ASTD_constant.value_of value in
                let get_state = get_synch_bdd not_init_dom init_state current_key value in
                let (mod_state, to_save, kappa, is_modified, modified_sub_env_quantified_vars)
                  = execute get_state sub_astd event sub_env_quantified_var (current_key ^ ":" ^ (ASTD_constant.string_of (ASTD_term.extract_constant_from_term (ASTD_state.get_val value2))) ^ "/" ^ (ASTD_astd.get_name sub_astd)) in
                let updated_sub_env_after_code_exec = try_execute_code is_modified modified_sub_env_quantified_vars astd in                
                let modified_sub_env = ASTD_environment.remove var updated_sub_env_after_code_exec in
                let (updated_attributes_instances, modified_env) = ASTD_environment.extract_attributes_from_env attributes_instances modified_sub_env in
                  if is_modified then (
                    let (new_state, isfinal) = is_final sub_astd mod_state modified_sub_env_quantified_vars [] (current_key ^ ":" ^ (ASTD_constant.string_of (ASTD_term.extract_constant_from_term (ASTD_state.get_val value2))) ^ "/" ^ (ASTD_astd.get_name sub_astd)) in
                      debug "kappa indirect !!!!!!!!!!";
                      let new_not_fin_dom = if isfinal then ASTD_constant.remove value' not_fin_dom else ASTD_constant.insert value' not_fin_dom in
                      let new_study_state = ASTD_state.QSynchronisation_s (new_not_fin_dom, (ASTD_constant.remove value' unknown_dom), (ASTD_constant.insert value' not_init_dom), init_state, updated_attributes_instances) in
                        (new_study_state,
                        ((current_key, value), new_state)::to_save,
                        kappa,
                        is_modified,
                        modified_env)
                  ) else (
                    debug "qsynch child astd not modified";
                    (state, [], [], is_modified, modified_env)
                  )
              )

            ) else ( (* Choice is not made *)
              debug ("no optimisation indirect kappa in " ^ name ^ " for " ^ (ASTD_event.get_label event));
              if List.mem (ASTD_event.get_label event) trans_list then
                let sub_env = ASTD_environment.add_attributes_to_env attributes_instances env in
                let optional_modifications = modif_all_qsync astd state event var val_list sub_env current_key in
                  match optional_modifications with
                  | Some modifications ->
                      let (updated_not_fin_dom, updated_unknown_dom, updated_not_init_dom, updated_to_save, updated_kappa) 
                        = merge_all_modifications modifications not_fin_dom unknown_dom not_init_dom [] [] current_key in
                      debug (ASTD_constant.print_dom updated_not_fin_dom);
                      debug (ASTD_constant.print_dom updated_unknown_dom);
                      debug (ASTD_constant.print_dom updated_not_init_dom);
                      debug (string_of_int (List.length updated_to_save));
                      debug (string_of_int (List.length updated_kappa));
                      (* Note : We do not update our environment with possible modifications done by child astds on synchronized transitions. See issue #27 for more info. *)
                      let new_state = ASTD_state.qsynchronisation_s_of updated_not_fin_dom updated_unknown_dom updated_not_init_dom init_state attributes_instances in
                        (new_state, 
                        updated_to_save, 
                        updated_kappa, 
                        true, 
                        env)
                  | None -> 
                    debug "no modifications";
                    (state, [], [], false, env)
              else
                let (direct_val, indeterminist) = get_values event sub_astd (ASTD_variable.get_name var) in
                let sub_env = ASTD_environment.add_attributes_to_env attributes_instances env in
                let optional_code = ASTD_astd.get_optional_code astd in
                let (mod_state, to_save, kappa, is_modified, modified_sub_env)
                  = try_qsynch  
                     state 
                     sub_astd 
                     var 
                     event 
                     sub_env 
                     val_list 
                     direct_val 
                     trans_list 
                     val_list 
                     indeterminist 
                     current_key 
                     optional_code
                in
                let (updated_attributes_instances, modified_env) = ASTD_environment.extract_attributes_from_env attributes_instances modified_sub_env in
                  (ASTD_state.set_attributes_instances mod_state updated_attributes_instances,
                  to_save,
                  kappa,
                  is_modified,
                  modified_env)

            )
        with _ -> (state, [], [], false, env)
      )


  | ASTD_state.Call_s (called, called_astd_state) -> 
      debug ("call exec " ^ (ASTD_astd.get_name astd));
      let (name, called_name, fct_vec) = ASTD_astd.get_data_call astd in
      let (called_astd, var_dom_list) = ASTD_astd.get_call_astd called_name in
      let call_env = ASTD_environment.get_call_env fct_vec env var_dom_list in
      let called_astd = ASTD_astd.call_astd called_name call_env in
      let sub_state = if called then called_astd_state else init called_astd in
      let (mod_state, to_save, kappa, is_modified, modified_env) = execute sub_state called_astd event call_env (current_key ^ "/" ^ (ASTD_astd.get_name called_astd)) in
      let updated_env = update_env_with_call_result env modified_env fct_vec in
        (ASTD_state.Call_s (true, mod_state), 
        to_save, 
        kappa, 
        is_modified, 
        updated_env)

  | _ -> (state, [], [], false, env)


(* Tries to execute an event on a qchoice astd for every value passed in kappa_dir_val (we are assigning them to var).
   Falls back on the domain (list_val) when no value from kappa_dir_val works or the event is indeterminist (no kappa_dir_val).
   This means we are iterating over the entirety of the domain to test every possible value.
  Parameters
    dep : dependencies list
    label : event label
    state : state of astd (sub astd of the qchoice_astd)
    astd : astd (sub astd of the qchoice_astd)
    var : variable of qchoice
    event : event to execute
    env : environment already containing the attributes of the qchoice astd
    list_val : domain of the variable on which we are doing a quantification
    kappa_dir_val : potential values of variable according to transitions and current event
    indeterminist : boolean indicating if the event is considered indeterminist (multiple transition could accept the event)
    current_key : id of the qchoice astd
    attributes_instances : instances of the qchoice attributes
    optional_code : The code to execute if an event on the astd has been done

  Returns 
    new_state : new state of the qchoice astd
    to_save : qsync table updates 
    kappa : ???????
    is_modified : boolean value indicating whether of not the event was accepted
    updated_env : environment updated with new attributes values
  *)
and try_qchoice dep label state astd var event env list_val kappa_dir_val indeterminist current_key attributes_instances optional_code =
  if kappa_dir_val = [] then
    if indeterminist && not (list_val = ASTD_constant.empty_dom) then ( (* Domain not empty, iterate through the domain *)
      (* INFINITE LOOP WARNING
         If the domain is infinite, like strings or integers, we will try to execute the event on every value.
         This will result in an infinite loop here because the values are infinite. *)
      debug "then trying global values";
      let (head_val, tail) = ASTD_constant.head_tail list_val in
      let bind_env = ASTD_environment.bind_const var head_val in
      let env_with_quantified_variable = (ASTD_environment.add_binding bind_env env) in
      let (mod_state, to_save, kappa, is_modified, modified_env_with_quantified_variable) = execute state astd event env_with_quantified_variable (current_key ^ ":" ^ (ASTD_constant.string_of head_val) ^ "/" ^ (ASTD_astd.get_name astd)) in
        if is_modified then (* Try execute with the first value of the domain *)
          let updated_sub_env_after_code_exec = execute_action_internal modified_env_with_quantified_variable optional_code in
          let modified_env = ASTD_environment.remove var updated_sub_env_after_code_exec in
          let (updated_qchoice_attributes_instances, modified_qchoice_parent_env) = ASTD_environment.extract_attributes_from_env attributes_instances modified_env in
            (ASTD_state.QChoice_s (ASTD_state.val_of (ASTD_term.Const head_val),(ASTD_constant.empty_dom),(ASTD_constant.empty_dom),mod_state, updated_qchoice_attributes_instances),
            to_save,
            (ASTD_optimisation.automatic_gestion_of_kappa_values env label dep (ASTD_term.Const head_val))@kappa,
            is_modified,
            modified_qchoice_parent_env)
        else (* First value of the domain doesn't execute, try with the rest of the domain (recursively) *)
          try_qchoice dep label state astd var event env tail kappa_dir_val indeterminist current_key attributes_instances optional_code
    ) else ( (* Empty domain and no potential values *)
      (state, 
      [], 
      [], 
      false, 
      env)
    )
  else ( (* There are potential values of variable according to transitions and current event *)
    debug "trying first kappa values";
    if not (ASTD_constant.is_included (List.hd kappa_dir_val) list_val) then (* Check if any of the potential values is included in the domain recursively *)
      try_qchoice dep label state astd var event env list_val (List.tl kappa_dir_val) indeterminist current_key attributes_instances optional_code
    else (* We got a match! *)
      let head_val = ASTD_term.const_of (List.hd kappa_dir_val) in
      let bind_env = ASTD_environment.bind var head_val in
      let env_with_quantified_variable = ASTD_environment.add_binding bind_env env in
      let (mod_state, to_save, kappa, is_modified, modified_env_with_quantified_variable) = execute state astd event env_with_quantified_variable (current_key ^ ":" ^ (ASTD_constant.string_of (ASTD_term.extract_constant_from_term head_val)) ^ "/" ^ (ASTD_astd.get_name astd)) in
        if is_modified then (
          debug "kappa direct !!!!!!!!!!";
          let updated_sub_env_after_code_exec = execute_action_internal modified_env_with_quantified_variable optional_code in          
          let modified_env = ASTD_environment.remove var updated_sub_env_after_code_exec in
          let (updated_qchoice_attributes_instances, modified_qchoice_parent_env) = ASTD_environment.extract_attributes_from_env attributes_instances modified_env in
            (ASTD_state.QChoice_s (ASTD_state.val_of head_val,(ASTD_constant.empty_dom),(ASTD_constant.empty_dom),mod_state, updated_qchoice_attributes_instances),
            to_save,
            (ASTD_optimisation.automatic_gestion_of_kappa_values env label dep head_val)@kappa,
            is_modified,
            modified_qchoice_parent_env)
        ) else (
          try_qchoice dep label state astd var event env list_val (List.tl kappa_dir_val) indeterminist current_key attributes_instances optional_code
        )
  )

(* Tries to execute an event on a qsync astd for every value passed in kappa_dir_val (we are assigning them to var).
   Falls back on the domain (list_val) is no value from kappa_dir_val works or the event is indeterminist (no kappa_dir_val),
   this means we are iterating over the entirety of the domain to test every possible value.

  Note : The event must not target a transition from the synchronized transitions list! try_qsynch is meant to handle transitions
  which are not synchronized.

  Parameters
    state : state of the qsync_astd
    sub_astd : sub_astd of the qsync_astd
    var : variable on which we are doing the quantified synchronization
    event : event to execute
    env : environment already containing the attributes of the qsynch astd
    list_val : domain of the variable on which we are doing a quantification
    kappa_dir_val : possible values of variable from event for possible transitions
    trans_list : synchronized transitions of qsync_astd 
    dom : domain of value of var
    indeterminist : boolean indicating that the event is considered indeterminist (multiple transition could accept the event)
    current_key : id of current qsync_astd (contains the values of quantified variables from parent astds). 
    optional_code : The code to execute if an event on the astd has been done

  Returns 
    new_state : new state of the targeted astd
    to_save : qsync table updates
    kappa : ???????
    is_modified : boolean value indicating whether of not the event was accepted
    updated_env : environment updated with new attributes values
  *)
and try_qsynch state sub_astd var event env list_val kappa_dir_val trans_list dom indeterminist current_key optional_code =
  if kappa_dir_val = [] then
    if indeterminist && list_val <> (ASTD_constant.empty_dom) then (
      (* INFINITE LOOP WARNING
         Here we are going to try every value of the domain as a possible value of the quantification.
         This limits to finite domains (as in lists of values) and limits the use of infinite (or very large) domains (like any value of type int or string)
         In the case of an infinite domain, we need to iterate over all the values, just in case an instance of the sub-astd can accept the event but only
         with a specific value for the quantification variable (may enforce this validation in the guard for example).
         Example : Var x is an integer, sub astd of qsynch is an Automata at its initial state which can accept the event e(), but with a guard that
                   validates the x = 9999999. We are going to iterate over all the possible values of integer from 0 to 9999999 before seeing an instance 
                   of the sub-astd that can accept it.
         ## If the domain is truly infinite, such as strings, and the sub-astd refuse all values (or no transition from the current state accept this event's label),
            we are going to loop forever. ## *)
      debug "then try dom for qsynch";
      let (head_val, tail) = ASTD_constant.head_tail list_val in
      let (not_fin_dom, unknown_dom, not_init_dom, init_state, attributes_instances) = ASTD_state.get_data_from_qsynchro state in
      let value = ASTD_constant.value_of head_val in
      let bind_env = ASTD_environment.bind_const var head_val in
      let env2 = ASTD_environment.add_binding bind_env env in
      let sub_state = get_synch_bdd not_init_dom init_state current_key head_val in
      let (mod_state, to_save, kappa, is_modified, modified_env) = execute sub_state sub_astd event env2 (current_key ^ ":" ^ (ASTD_constant.string_of head_val) ^ "/" ^ (ASTD_astd.get_name sub_astd)) in
      let updated_sub_env_after_code_exec = if is_modified then execute_action_internal modified_env optional_code else modified_env in    
        if is_modified then
          let (new_state, isfinal) = (is_final sub_astd mod_state env2 [] (current_key ^ ":" ^ (ASTD_constant.string_of head_val) ^ "/" ^ (ASTD_astd.get_name sub_astd))) in
          let new_not_fin_dom = if isfinal then (ASTD_constant.remove value not_fin_dom) else (ASTD_constant.insert value not_fin_dom) in
          let new_study_state = ASTD_state.QSynchronisation_s (new_not_fin_dom, (ASTD_constant.remove value unknown_dom), (ASTD_constant.insert value not_init_dom), init_state, attributes_instances) in
            (new_study_state,
            ((current_key, head_val), new_state)::to_save,
            kappa,
            is_modified,
            updated_sub_env_after_code_exec)
        else
          try_qsynch state sub_astd var event env tail [] trans_list dom indeterminist current_key optional_code
    )
    else
      (state, [], [], false, env)
  else (
    debug " try kappa dir for qsynch ";
    let head_val = List.hd kappa_dir_val in
    let (not_fin_dom, unknown_dom, not_init_dom, init_state, attributes_instances) = ASTD_state.get_data_from_qsynchro state in
    let value = ASTD_constant.value_of head_val in
      if not (ASTD_constant.is_included head_val dom) then
        try_qsynch state sub_astd var event env list_val (List.tl kappa_dir_val) trans_list dom indeterminist current_key optional_code
      else (
        debug "try_qsynch value is in domain";
        let bind_env = ASTD_environment.bind_const var head_val in
        let sub_env = ASTD_environment.add_binding bind_env env in
        let sub_state = get_synch_bdd not_init_dom init_state current_key head_val in
        let (mod_state, to_save, kappa, is_modified, modified_sub_env) = execute sub_state sub_astd event sub_env (current_key ^ ":" ^ (ASTD_constant.string_of head_val) ^ "/" ^ (ASTD_astd.get_name sub_astd)) in
        let updated_sub_env_after_code_exec = if is_modified then execute_action_internal modified_sub_env optional_code else modified_sub_env in
        let modified_env = ASTD_environment.remove var updated_sub_env_after_code_exec in
          if is_modified then (
            let (new_state, isfinal) = is_final sub_astd mod_state updated_sub_env_after_code_exec [] (current_key ^ ":" ^ (ASTD_constant.string_of head_val) ^ "/" ^ (ASTD_astd.get_name sub_astd)) in
              debug "kappa direct !!!!!!!!!!";
              let new_not_fin_dom = if isfinal then (ASTD_constant.remove value not_fin_dom) else (ASTD_constant.insert value not_fin_dom) in
              let new_study_state = ASTD_state.QSynchronisation_s (new_not_fin_dom, (ASTD_constant.remove value unknown_dom), (ASTD_constant.insert value not_init_dom), init_state, attributes_instances) in
                (new_study_state,
                ((current_key, head_val), new_state)::to_save,
                kappa,
                is_modified,
                modified_env)
          ) else (
            try_qsynch state sub_astd var event env list_val (List.tl kappa_dir_val) trans_list dom indeterminist current_key optional_code
          )
      )
  )

(** Calculates the modification for the current value of the variable.
  Parameters
    astd : astd on which to execute the event 
    state : state of the astd
    event : event to execute
    not_init_dom : ?????
    env : environment containing the attributes of the qsync, but not its qvar
    current_key : id of the astd
    var : quantified variable
    value : value to assign to var
  Returns
    modification
      val_used : value used for the quantification variable
      mod_state : modified state
      to_save : qsync table updates
      kappa : ??????
      is_astd_final : boolean indicating if the resulting sub_astd is in a final state
 *)
and compute_modification_for_value astd state event not_init_dom env current_key var value : ASTD_constant.t * ASTD_state.t *
((string * ASTD_constant.t) * ASTD_state.t) list *
((ASTD_optimisation.dependency * ASTD_term.t list) * ASTD_term.t * bool) list *
bool =
  let bind_env = ASTD_environment.bind_const var value in
  let env2 = ASTD_environment.add_binding bind_env env in
  let (mod_state, to_save, kappa, is_modified, modified_sub_env) = execute state astd event env2 current_key in
    if is_modified then (
      debug ((ASTD_astd.get_name astd) ^ " modified");
      let (final_state, is_astd_final) = is_final astd mod_state modified_sub_env [] current_key in
        (value, final_state, to_save, kappa, is_astd_final)
    ) else (
      debug "event cannot be accepted by the astd";
      failwith "event cannot be accepted by the astd" 
    )

(** Calculates the modification for each value from the domain of the quantification variable.
  Parameters
    qsync_astd : qsynch astd
    qsync_state : state of the qsync astd
    event : event to execute
    var : quantified variable
    value_list : list of all the possible value of the variable (corresponds to the domain)
    env : environment containing the attributes of the qsynch
    current_key : id of current qchoice_astd
  Returns
    [optional] modifications : list of all the modifications to do
      val_used : value used for the quantification variable
      mod_state : modified state
      to_save : qsync table updates
      kappa : ??????
      is_astd_final : boolean indicating if the resulting sub_astd is in a final state
 *)
and modif_all_qsync qsync_astd qsync_state event var value_domain env current_key : (
         ASTD_constant.t * ASTD_state.t *
         ((string * ASTD_constant.t) * ASTD_state.t) list *
         ((ASTD_optimisation.dependency * ASTD_term.t list) * ASTD_term.t *
          bool)
         list * bool) list option =
  debug "modif_all_qsync";
  let (name, var, dom, synchro, attributes,optional_code, dep, sub_astd) = ASTD_astd.get_data_qsynchronisation qsync_astd in
  let (not_fin_dom, unknown_dom, not_init_dom, init_state, attributes_instances) = ASTD_state.get_data_from_qsynchro qsync_state in
    debug "modif_all_qsync, before try";
    try
      (* INFINITE LOOP WARNING
            If the domain is infinite, like strings or integers, we will try to execute the event on every value.
            This will result in an infinite loop here because the values are infinite. *)
      let fct  = (fun (value : ASTD_constant.t) -> 
            let sub_state = get_synch_bdd not_init_dom init_state current_key value in
            let sub_key = current_key ^ ":" ^ (ASTD_constant.string_of value) ^ "/" ^ (ASTD_astd.get_name sub_astd) in
              compute_modification_for_value sub_astd sub_state event not_init_dom env sub_key var value
          ) in
      debug (ASTD_constant.print_dom value_domain);
      Some (ASTD_constant.map_on_domain fct value_domain)
    with exn -> debug ("error during modif_all_qsync" ^ (Printexc.to_string exn)); None


(**Affichage*)
let rec print state astd s current_key= match state with
        |ASTD_state.Automata_s (a,b,c,attributes_instances) ->print_newline();
                              print_endline(s^"Automata_s ,"^(ASTD_astd.get_name astd));
                              print_endline(s^"//StartHistory");
                              (print_h astd b (s^"//")) current_key;
                              print_endline(s^"sub_state : "^a);
                              print c (ASTD_astd.find_subastd a (ASTD_astd.get_sub astd)) (s^"   ") (current_key^"/"^a)
        |ASTD_state.Sequence_s (a,b,attributes_instances) ->print_newline();print_endline(s^"Sequence_s ,");print_endline(s^"step : "^(ASTD_state.string_of_seq a));
               begin if a=ASTD_state.Fst 
        then print b (ASTD_astd.get_seq_l astd) (s^"   ")  (current_key^"/"^(ASTD_astd.get_name (ASTD_astd.get_seq_l astd)))
                                else print b (ASTD_astd.get_seq_r astd) (s^"   ") (current_key^"/"^(ASTD_astd.get_name (ASTD_astd.get_seq_r astd)))
               end
        |ASTD_state.Choice_s (a,b,attributes_instances) ->print_newline();print_endline(s^"Choice_s ,");print_endline(s^"step : "^(ASTD_state.string_of_choice a));
               begin if a=ASTD_state.Undef then print_endline (s^"No choice made")
                                        else if a=ASTD_state.Left then print b (ASTD_astd.get_choice1 astd) (s^"   ") (current_key^"/"^(ASTD_astd.get_name (ASTD_astd.get_choice1 astd)))
                                                      else print b (ASTD_astd.get_choice2 astd)(s^"   ") (current_key^"/"^(ASTD_astd.get_name (ASTD_astd.get_choice2 astd)))
               end
        |ASTD_state.Kleene_s (a,b,attributes_instances) ->print_newline();print_endline(s^"Kleene_s ,");print_endline(s^"started ? : "^(string_of_bool a)); 
                          print b (ASTD_astd.get_astd_kleene astd) (s^"   ") (current_key^"/"^(ASTD_astd.get_name (ASTD_astd.get_astd_kleene astd)))
        |ASTD_state.Synchronisation_s (a,b,attributes_instances) ->print_newline();print_endline(s^"Synchronisation_s ,");
                                   print a (ASTD_astd.get_synchro_astd1 astd) (s^"   ") (current_key^"/"^(ASTD_astd.get_name (ASTD_astd.get_synchro_astd1 astd))) ;
                                   print b (ASTD_astd.get_synchro_astd2 astd) (s^"   ") (current_key^"/"^(ASTD_astd.get_name (ASTD_astd.get_synchro_astd2 astd)))
        |ASTD_state.QChoice_s (a,final_dom,unknown_dom,b,attributes_instances) ->print_newline();print_endline(s^"QChoice_s ,");
                                      begin 
          let (n,o,p,attributes,optional_code,q,r)= ASTD_astd.get_data_qchoice astd
                                        in if a=ASTD_state.ChoiceNotMade 
                                           then begin print_endline(s^"Value Not Chosen // Possible values: "^(ASTD_constant.print_dom p ))
                                                end
                                           else begin print_endline(s^"chosen value : "^(ASTD_state.string_of_qchoice a)^" for  qchoice "^(ASTD_variable.get_name o));
                                                      print b (ASTD_astd.get_qastd astd) (s^"   ") (current_key^":"^(ASTD_state.string_of_qchoice a)^"/"^(ASTD_astd.get_name r))
                                                end
                                      end;
        |ASTD_state.QSynchronisation_s (not_fin,unknown,not_init_dom,init_state,attributes_instances) -> print_newline();print_endline(s^"QSynchronisation_s ,Not_Initial values:  "^(ASTD_constant.print_dom not_init_dom));
                                           (print_synch (ASTD_astd.get_qastd astd) (s^"   ") not_init_dom (ASTD_astd.get_qvar astd) current_key)
        |ASTD_state.Guard_s (a,b,attributes_instances) ->print_newline();print_endline(s^"Guard_s ,");print_endline(s^"started ? : "^(string_of_bool a));
                         print b (ASTD_astd.get_guard_astd astd) (s^"   ") (current_key^"/"^(ASTD_astd.get_name (ASTD_astd.get_guard_astd astd)))
        |ASTD_state.Call_s (a,b) ->print_newline();print_endline(s^"Call_s ,");print_endline(s^"started ? : "^(string_of_bool a));
                        print b (ASTD_astd.get_astd (ASTD_astd.get_called_name astd)) (s^"   ") (current_key^"/"^(ASTD_astd.get_called_name astd))
        |ASTD_state.NotDefined ->print_endline (s^"End of the state")
        |ASTD_state.Elem -> print_endline(s^"Elem")


and print_h astd hist s current_key= match hist with
  |(n1,h)::t ->print_endline(s^n1^" @ "^current_key);
               print h (ASTD_astd.find_subastd n1 (ASTD_astd.get_sub astd)) (s) (current_key^"/"^n1);
               print_h astd  t s current_key
  |[]->print_endline(s^"EndHistory")


and print_synch sub_astd s not_init var current_key =
  if ASTD_constant.is_empty_dom not_init 
    then print_newline ()
    else let (value,t)=ASTD_constant.head_tail not_init
      in begin 
        print_newline ();
        print_endline (s^"Value "^(ASTD_constant.string_of value)^" for qsynch "^ (ASTD_variable.get_name var) ); 
        print (get_bdd current_key value)
          (sub_astd)
          s
          (current_key^":"^(ASTD_constant.string_of value)^"/"^(ASTD_astd.get_name sub_astd));
        print_endline (s^"end");
        print_synch sub_astd s t var current_key
        end

let compteur=
  let n= ref 0 
      in function () -> 
                n:=!n+1;
                print_endline ("event number "^(string_of_int !n))

let rec execute_event_list affichage state astd event_list =
  match event_list with
    | event::tail->
      if affichage <> 1 then ( 
        (*print_endline "================================================================";*)
        (*print_endline ("Execution of : "^(ASTD_label.string_of(ASTD_event.get_label event)))*)
      );
      let (new_state,to_save,kappa,is_modified,modified_env) = execute state astd event ASTD_environment.empty "Main" in
        if is_modified then (
          if affichage = 2 then (
            compteur()
          );
          save_synch_data to_save;
          ASTD_optimisation.apply_each_mod kappa;
          if affichage = 3 then (
            print new_state astd "" "Main"
          )
       ); (*else (
          print_endline ("Execution of : " ^ (ASTD_label.string_of (ASTD_event.get_label event) ) ^ " not possible")
        );*)
        execute_event_list affichage new_state astd tail
    | [] -> state




