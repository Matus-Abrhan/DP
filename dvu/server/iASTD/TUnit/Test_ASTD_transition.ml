open OUnit2

let label = ASTD_label.of_string "e"
let another_label = ASTD_label.of_string "e2"
let constant1 = ASTD_constant.of_int 1
let constant2 = ASTD_constant.of_int 2
let constants = constant1::(constant2::[])
let smaller_constants = constant1::[]
let event = ASTD_event.event label constants 
let variable1 = ASTD_variable.variable_name_of_string "x"
let variable2 = ASTD_variable.variable_name_of_string "y"
let term1 = ASTD_term.term_of_variable_name variable1
let term2 = ASTD_term.term_of_variable_name variable2
let param1 = ASTD_transition.parameter_from_term term1
let param2 = ASTD_transition.parameter_from_term term1
let params = param1::(param2::[])
let transition = ASTD_transition.transition label params

let test_is_transition_valid_for_event test_ctxt = 
  assert_bool "transition is supposed to be valid" (ASTD_transition.is_transition_valid_for_event event transition)

let test_is_transition_valid_for_event_label_mismatch test_ctxt =
  let event = ASTD_event.set_label another_label event in
    assert_bool "transition is supposed to be invalid because labels mismatch" 
      (not (ASTD_transition.is_transition_valid_for_event event transition))

let test_is_transition_valid_for_event_event_count_mismatch test_ctxt =
  let event = ASTD_event.set_consts smaller_constants event in
    assert_bool "transition is supposed to be invalid because parameters counts mismatch" 
      (not (ASTD_transition.is_transition_valid_for_event event transition))


let suite = "Test_ASTD_transition" >:::
[
  "test_is_transition_valid_for_event" >:: test_is_transition_valid_for_event;
  "test_is_transition_valid_for_event_label_mismatch" >:: test_is_transition_valid_for_event_label_mismatch;
  "test_is_transition_valid_for_event_event_count_mismatch" >:: test_is_transition_valid_for_event_event_count_mismatch;
]

let _ =
  run_test_tt_main suite