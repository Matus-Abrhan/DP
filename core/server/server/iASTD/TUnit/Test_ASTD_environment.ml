open OUnit2

let test_extract_attributes_from_env test_ctxt = 
  let variable1 = ASTD_variable.of_strings "x" "int" in 
  let variable2 = ASTD_variable.of_strings "y" "int" in 
  let constant1 = ASTD_constant.of_int 1 in 
  let constant2 = ASTD_constant.of_int 2 in 
  let attribute_instance1 = ASTD_attribute.init (ASTD_attribute.attribute_of variable1 constant1) in
  let attribute_instance2 = ASTD_attribute.init (ASTD_attribute.attribute_of variable2 constant2) in
  let attribute_instances = attribute_instance1 :: (attribute_instance2 :: []) in 

  let modified_constant1 = ASTD_constant.of_int 3 in 
  let modified_constant2 = ASTD_constant.of_int 4 in 
  let env = ASTD_environment.empty in
  let env = ASTD_environment.add_binding (ASTD_environment.bind_const variable1 modified_constant1) env in
  let env = ASTD_environment.add_binding (ASTD_environment.bind_const variable2 modified_constant2) env in

  let (updated_instances, env_without_attributes) = ASTD_environment.extract_attributes_from_env attribute_instances env in
    (*Make sure the attributes were removed*)
    assert_raises (ASTD_environment.Variable_not_found ("x")) (fun () -> ASTD_environment.find_value_of env_without_attributes variable1);
    assert_raises (ASTD_environment.Variable_not_found ("y")) (fun () -> ASTD_environment.find_value_of env_without_attributes variable2);
    (*Make sure the attributes returned contains the correct value and are all there*)
    List.iter 
      (fun instance -> 
        if variable1 = (ASTD_attribute.variable_of_instance instance) then 
          assert_equal (ASTD_attribute.value_of_instance instance) modified_constant1
        else if variable2 = (ASTD_attribute.variable_of_instance instance) then 
          assert_equal (ASTD_attribute.value_of_instance instance) modified_constant2
        else
          assert_failure "attribute not supposed to be returned"
      )
      updated_instances;
    assert_equal (List.length updated_instances) 2

let test_extract_attributes_from_env_with_missing_attributes test_ctxt =
  let variable1 = ASTD_variable.of_strings "x" "int" in 
  let variable2 = ASTD_variable.of_strings "y" "int" in 
  let constant1 = ASTD_constant.of_int 1 in 
  let constant2 = ASTD_constant.of_int 2 in 
  let attribute_instance1 = ASTD_attribute.init (ASTD_attribute.attribute_of variable1 constant1) in
  let attribute_instance2 = ASTD_attribute.init (ASTD_attribute.attribute_of variable2 constant2) in
  let attribute_instances = attribute_instance1 :: (attribute_instance2 :: []) in 

  let modified_constant1 = ASTD_constant.of_int 3 in 
  let env = ASTD_environment.empty in
  let env = ASTD_environment.add_binding (ASTD_environment.bind_const variable1 modified_constant1) env in

  (* Try to extract attributes instances from env that contains only some of them*)
  try
    let _ = ASTD_environment.extract_attributes_from_env attribute_instances env in
      assert_failure "extraction should fail when attributes are missing from env"
  with
    _ -> () (* We expect this exception to happen *)


let suite = "Test_ASTD_environment" >:::
[
  "test_extract_attribtes_from_env" >:: test_extract_attributes_from_env;
  "test_extract_attributes_from_env_with_missing_attributes" >:: test_extract_attributes_from_env_with_missing_attributes;
]

let _ =
  run_test_tt_main suite
