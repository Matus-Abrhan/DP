import subprocess

tests = [
    # | spec | input | nb_events | nb_not_possible_events | nb_errors

    # Backward compatibility tests for iASTD
    ("TFunc/iASTD/s1",  "TFunc/iASTD/i1",  7,  2, 0),
    ("TFunc/iASTD/s2",  "TFunc/iASTD/i2",  10, 4, 0),
    ("TFunc/iASTD/s3",  "TFunc/iASTD/i3",  8,  4, 0),
    ("TFunc/iASTD/s4",  "TFunc/iASTD/i4",  9,  2, 0),
    ("TFunc/iASTD/s5",  "TFunc/iASTD/i5",  12, 4, 0),
    ("TFunc/iASTD/s6",  "TFunc/iASTD/i6",  10, 2, 0),
    ("TFunc/iASTD/s7",  "TFunc/iASTD/i7",  9,  2, 0),
    ("TFunc/iASTD/s8",  "TFunc/iASTD/i8",  12, 2, 0),
    ("TFunc/iASTD/s9",  "TFunc/iASTD/i9",  11, 1, 0),
    ("TFunc/iASTD/s10", "TFunc/iASTD/i10", 9,  4, 0),
    ("TFunc/iASTD/s11", "TFunc/iASTD/i11", 12, 5, 0),
    ("TFunc/iASTD/s12", "TFunc/iASTD/i12", 7,  2, 0),
    ("TFunc/iASTD/s13", "TFunc/iASTD/i13", 22, 4, 0),
    ("TFunc/iASTD/s14", "TFunc/iASTD/i14", 15, 2, 0),
    ("TFunc/iASTD/s15", "TFunc/iASTD/i15", 10, 3, 0),
    ("TFunc/iASTD/s16", "TFunc/iASTD/i16", 3,  1, 0),

    # Backward compatibility tests for performance
    ("TPerf/TP1/1.astd", "TPerf/TP1/1.order", 20000, 0, 0),
    ("TPerf/TP1/2.astd", "TPerf/TP1/2.order", 20000, 0, 0),
    ("TPerf/TP1/3.astd", "TPerf/TP1/3.order", 20000, 0, 0),

    ("TPerf/TP2/1.astd", "TPerf/TP2/1.order", 20000, 0, 0),
    ("TPerf/TP2/2.astd", "TPerf/TP2/2.order", 20000, 0, 0),
    ("TPerf/TP2/3.astd", "TPerf/TP2/3.order", 20000, 0, 0),
    ("TPerf/TP2/4.astd", "TPerf/TP2/4.order", 20000, 0, 0),
    ("TPerf/TP2/5.astd", "TPerf/TP2/5.order", 50005, 5, 0),

    ("TPerf/TP3/1.astd", "TPerf/TP3/1.order", 45, 2, 0),
    ("TPerf/TP3/2.astd", "TPerf/TP3/2.order", 30, 0, 0),

    # Tests for exASTD
    # Tests for parsing error from spec
    ("TFunc/exASTD/test_parsing_errs_from_spec/s_exASTD_grammar", "TFunc/exASTD/test_parsing_errs_from_spec/i_empty",      0, 0, 0),
    ("TFunc/exASTD/test_parsing_errs_from_spec/s_exASTD_grammar", "TFunc/exASTD/test_parsing_errs_from_spec/i_emprunter",  1, 0, 0),
    ("TFunc/exASTD/test_parsing_errs_from_spec/s_empty_lists",    "TFunc/exASTD/test_parsing_errs_from_spec/i_empty",      0, 0, 0),
    ("TFunc/exASTD/test_parsing_errs_from_spec/s_actions",        "TFunc/exASTD/test_parsing_errs_from_spec/i_empty",      0, 0, 0),
    ("TFunc/exASTD/test_trailing_comma/spec.iastd",               "TFunc/exASTD/test_trailing_comma/in.txt",               0, 0, 0),

    # Tests for guards
    ("TFunc/exASTD/test_guards/s_guards",              "TFunc/exASTD/test_guards/i_guards",               3,  0, 0),
    ("TFunc/exASTD/test_guards/s_biblio_guards",       "TFunc/exASTD/test_guards/i_biblio_guards",        10, 6, 0),
    ("TFunc/exASTD/test_guards/s_actions_with_guards", "TFunc/exASTD/test_guards/i_actions_with_guards",  18, 8, 0),

    # Tests for code execution
    ("TFunc/exASTD/test_code_execution/s_aut",      "TFunc/exASTD/test_code_execution/i_aut",       4,  0, 0),
    ("TFunc/exASTD/test_code_execution/s_seq",      "TFunc/exASTD/test_code_execution/i_seq",       10, 4, 0),
    ("TFunc/exASTD/test_code_execution/s_qchoice",  "TFunc/exASTD/test_code_execution/i_qchoice",   9,  4, 0),
    ("TFunc/exASTD/test_code_execution/s_qsync",    "TFunc/exASTD/test_code_execution/i_qsync",     12, 5, 0),

    # Tests sync and qsync derivation (interleave + parallel composition)
    ("TFunc/exASTD/test_sync_qsync_derivation/s_interleave",           "TFunc/exASTD/test_sync_qsync_derivation/i_empty",                  0,  0, 0),
    ("TFunc/exASTD/test_sync_qsync_derivation/s_qinterleave",          "TFunc/exASTD/test_sync_qsync_derivation/i_empty",                  0,  0, 0),
    ("TFunc/exASTD/test_sync_qsync_derivation/s_parallel_composition", "TFunc/exASTD/test_sync_qsync_derivation/i_parallel_composition",   11, 4, 0),
    ("TFunc/exASTD/test_sync_qsync_derivation/s_qparallel_composition","TFunc/exASTD/test_sync_qsync_derivation/i_qparallel_composition",  6,  4, 0),

    # Tests biblio demo
    ("TFunc/exASTD/test_biblio_demo/s_biblio",  "TFunc/exASTD/test_biblio_demo/i_biblio1",  2,  0, 0),
    ("TFunc/exASTD/test_biblio_demo/s_biblio",  "TFunc/exASTD/test_biblio_demo/i_biblio2",  6,  0, 0),

    # Tests arguments in actions
    ("TFunc/exASTD/test_action_arguments/s_unref_attribute_in_action",    "TFunc/exASTD/test_action_arguments/i_unref_attribute_in_action",     6,  1, 0),
    ("TFunc/exASTD/test_action_arguments/s_action_arguments",             "TFunc/exASTD/test_action_arguments/i_action_arguments",              3,  0, 0),

    # Domains validation during calls
    ("TFunc/exASTD/test_domains_validation_during_call/valid_spec.iastd",                "TFunc/exASTD/test_domains_validation_during_call/valid_in.txt",                 5,  2, 0),
    ("TFunc/exASTD/test_domains_validation_during_call/attributes_bust_domain.iastd",    "TFunc/exASTD/test_domains_validation_during_call/attributes_bust_domain.txt",   2,  2, 0),
    ("TFunc/exASTD/test_domains_validation_during_call/attributes_bust_domain.1.iastd",  "TFunc/exASTD/test_domains_validation_during_call/attributes_bust_domain.1.txt", 2,  2, 0),
    ("TFunc/exASTD/test_domains_validation_during_call/constant_bust_domain.iastd",      "TFunc/exASTD/test_domains_validation_during_call/constant_bust_domain.txt",     2,  2, 0),
    ("TFunc/exASTD/test_domains_validation_during_call/constant_bust_domain.1.iastd",    "TFunc/exASTD/test_domains_validation_during_call/constant_bust_domain.1.txt",   2,  2, 0),
    ("TFunc/exASTD/test_domains_validation_during_call/set_domain.iastd",                "TFunc/exASTD/test_domains_validation_during_call/valid_in.txt",                 5,  2, 0),

    # Tests import compiled files
    ("TFunc/exASTD/test_import_compiled_files/s_module_printer_compiled",  "TFunc/exASTD/test_import_compiled_files/i_module_printer_compiled",  6,  2, 0),    

    # Other tests
    ("TFunc/exASTD/test_strings/s_string_test", "TFunc/exASTD/test_strings/i_string_test", 8, 3, 0),
    ("TFunc/exASTD/test_synchronized_transitions_not_affecting_environment/s_synchronized_transitions", "TFunc/exASTD/test_synchronized_transitions_not_affecting_environment/i_synchronized_transitions", 6, 2, 0),  
    ("TFunc/exASTD/test_automata_deep_final/s_automata_deep_final_test", "TFunc/exASTD/test_automata_deep_final/i_automata_deep_final_test", 1, 1, 0),
    ("TFunc/exASTD/test_attributes_through_call/s_attributes_through_call_test", "TFunc/exASTD/test_attributes_through_call/i_attributes_through_call_test",  3,  1, 0),
    ("TFunc/exASTD/test_using_both_const_and_qvar_in_transition/spec.iastd", "TFunc/exASTD/test_using_both_const_and_qvar_in_transition/in.txt", 3, 1, 0),
    ("TFunc/exASTD/test_capture_event_arguments/spec.iastd", "TFunc/exASTD/test_capture_event_arguments/in.txt", 5, 3, 0),
    ("TFunc/exASTD/test_automata_inside_automata/spec.iastd", "TFunc/exASTD/test_automata_inside_automata/in.txt", 38, 3, 0),
]

# Init
print("=========== Init ===========")
subprocess.check_output(["make", "cleanall"])
subprocess.check_output(["make", "all"])
print("========= End Init =========")

all_tests_passed = True

for count, test in enumerate(tests):
    expected_nb_events = test[2]
    expected_nb_not_possible_events = test[3]
    expected_nb_errors = test[4]
    actual_nb_not_possible_events = -1
    actual_nb_events = -1
    actual_nb_errors = -1
    
    try:
        output = subprocess.check_output(["./xASTD", "-s", test[0], "-i", test[1], "-vv"]).lower()
        actual_nb_not_possible_events = output.count("not possible")
        actual_nb_events = output.count("event number") + actual_nb_not_possible_events
        actual_nb_errors = output.count("error")
    except:
        print("============ Exception thrown ============")
        actual_nb_errors = -1

    if expected_nb_events == actual_nb_events and \
        expected_nb_not_possible_events == actual_nb_not_possible_events and \
        expected_nb_errors == actual_nb_errors :
        print("Test #{count} passed!".format(**locals()))
    else:
        all_tests_passed = False
        print ("""
Test #{count} failed with :
s = {test[0]}
i = {test[1]}
nb_events =              expected : {expected_nb_events} actual : {actual_nb_events}
nb_not_possible_events = expected : {expected_nb_not_possible_events} actual : {actual_nb_not_possible_events}
nb_errors =              expected : {expected_nb_errors} actual : {actual_nb_errors}
""".format(**locals()))

print
print("Good Boy!" if all_tests_passed else "BAD BOY ...")