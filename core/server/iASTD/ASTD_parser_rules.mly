
%{
  (* Header*)
  let astd_parser_debug = false ;;
  let astd_parser_msg m = if (astd_parser_debug) 
                          then (print_endline m )
                          else (ignore m);;

%}

/* Declarations */
%token <string> BOOL
%token <string> IDENTITY_NAME
%token <string> STRING_VALUE
%token <int>    INT_VALUE
%token IMPORTS ATTRIBUTES CODE FILE
%token LAMBDA AUTOMATA ELEM BEGIN_ASTD END_ASTD CALL TRUE FALSE
%token SEQUENCE CHOICE PARALLEL INTERLEAVE
%token LSYNCHRO RSYNCHRO
%token LENV RENV GUARD
%token KLEENE PLUS QMARK
%token LPAR RPAR LINT RINT LSET RSET 
%token COLON SCOLON COMMA 
%token IS EQUALS LINK
%token REMOVE LOCAL FROM_SUB TO_SUB
%token UNDERSCORE
%token EOF

%nonassoc QINTERLEAVE QSYNCHRO QCHOICE
%right PARALLEL INTERLEAVE SYNCHRO
%right CHOICE
%right SEQUENCE
%nonassoc GUARD
%nonassoc KLEENE PLUS QMARK 
%nonassoc CLOSURE
%nonassoc PAR_PE

%start structure
%start apply_event

%type <unit> structure
%type <ASTD_event.t list> apply_event

%%
/* Rules */
structure:
     |structure SCOLON astd LSET domain_list RSET
      { astd_parser_msg ("structure 1st choice");
        print_endline "========================================" ;
        ASTD_astd.global_save_astd $3 $5 ;
        print_endline ("Registered: "^(ASTD_astd.get_name $3)) 
      }
     |astd LSET domain_list RSET
      { astd_parser_msg ("structure 2nd choice");
        print_endline "========================================" ;
        ASTD_astd.global_save_astd $1 $3 ;
        print_endline ("Registered: "^(ASTD_astd.get_name $1)) 
      }
     |structure SCOLON astd 
      { astd_parser_msg ("structure 1st choice");
        print_endline "========================================" ;
        ASTD_astd.global_save_astd $3 [] ;
        print_endline ("Registered: "^(ASTD_astd.get_name $3)) 
      }
     |astd 
      { astd_parser_msg ("structure 2nd choice");
        print_endline "========================================" ;
        ASTD_astd.global_save_astd $1 [] ;
        print_endline ("Registered: "^(ASTD_astd.get_name $1)) 
      }
  ;


domain_list:
    |domain_link COMMA domain_list
      { astd_parser_msg ("callable astd domain"); $1::$3 }
    |domain_link COMMA /* trailing comma at the end of a list */
      { astd_parser_msg ("callable astd domain"); [$1] }
    |domain_link
      { astd_parser_msg ("callable astd domain"); [$1] }
    ;

domain_link :
    |parameter_of_astd LINK complex_val_construction
      { astd_parser_msg ("link var domain"); ($1,$3) }
    ;

astd:
    |LPAR IDENTITY_NAME COMMA type_astd RPAR
      { astd_parser_msg ("astd 1st choice "^$2); let astd2 = ASTD_astd.rename_astd $4 $2 in begin astd2 end }
    |type_astd
      { astd_parser_msg ("astd 2nd choice");
        $1 }
    ;


type_astd:
    | astd_automata
      { astd_parser_msg ("type_astd automata "); $1 }
    | astd_choice
      { astd_parser_msg ("type_astd choix "); $1 }
    | astd_sequence
      { astd_parser_msg ("type_astd sequence "); $1 }
    | astd_kleene
      { astd_parser_msg ("type_astd kleene "); $1 }
    | astd_synchronisation
      { astd_parser_msg ("type_astd synchro "); $1 }
    | astd_qchoice
      { astd_parser_msg ("type_astd qchoice "); $1 }
    | astd_qsynchro
      { astd_parser_msg ("type_astd qsynch "); $1 }
    | astd_guard
      { astd_parser_msg ("type_astd guard "); $1 }
    | astd_call
      { astd_parser_msg ("type_astd call "); $1 }
    | ELEM
      { astd_parser_msg ("type_astd elem "); ASTD_astd.elem_of(ASTD_astd.give_name()) }
    ;


astd_automata:
  | BEGIN_ASTD AUTOMATA SCOLON list_of_imports list_of_attributes code list_of_meanings SCOLON list_of_arrows SCOLON list_of_names SCOLON list_of_names SCOLON IDENTITY_NAME END_ASTD
    { ASTD_astd.automata_of (ASTD_astd.give_name ()) $5 $6 $7 $9 $11 $13 $15 }
  ;

list_of_imports : 
    | /* Empty rules : backward compatibility with ASTD */
      { astd_parser_msg ("No imports "); }
    | IMPORTS COLON LSET RSET SCOLON /* exASTD */
      { astd_parser_msg ("Empty list of imports "); }
    | IMPORTS COLON LSET list_of_imports_content RSET SCOLON /* exASTD */
      { astd_parser_msg ("List of imports "); }
    ;

list_of_imports_content :
    | my_import COMMA list_of_imports_content
    {}
    | my_import COMMA /*trailing comma at the end of a list */
    {}
    | my_import
    {}
    ;

my_import : 
    | STRING_VALUE
      { astd_parser_msg ("import created ");
        (ASTD_plugin_builder.add_import $1) }
    ;

list_of_attributes :
    | /* Empty rules : backward compatibility with ASTD */
      { astd_parser_msg ("No attributes "); 
        [] }
    | ATTRIBUTES COLON LSET RSET SCOLON /* exASTD */
      { astd_parser_msg ("Empty list of attributes "); 
        [] }
    | ATTRIBUTES COLON LSET list_of_attributes_content RSET SCOLON /* exASTD */
      { astd_parser_msg ("List of attributes "); 
        $4 }
    ;

list_of_attributes_content :
    | attribute COMMA list_of_attributes_content
      { $1::$3 }
    | attribute COMMA /*trailing comma at the end of a list */
      { $1::[] }
    | attribute
      { $1::[] }
    ;

attribute : 
    | LPAR IDENTITY_NAME COMMA IDENTITY_NAME COMMA INT_VALUE RPAR
      { astd_parser_msg ("attribute created ");
        ASTD_attribute.attribute_of (ASTD_variable.variable_of $2 $4 false) (ASTD_constant.of_int $6) }
    | LPAR IDENTITY_NAME COMMA IDENTITY_NAME COMMA STRING_VALUE RPAR
      { astd_parser_msg ("attribute created "); 
        ASTD_attribute.attribute_of (ASTD_variable.variable_of $2 $4 false) (ASTD_constant.of_string $6) }
    ;

code : 
    | /* Empty rules : backward compatibility with ASTD */
    { None }
    | CODE COLON STRING_VALUE SCOLON
    { ASTD_action.action_of_string $3 }

list_of_labels :
    | LSET RSET
      { astd_parser_msg ("Empty label list");[] }
    | LSET list_of_labels_content RSET
      { astd_parser_msg ("Label list");$2 }
;


list_of_labels_content:
    | IDENTITY_NAME COMMA list_of_labels_content
      { $1::$3 }
    | IDENTITY_NAME COMMA /* trailing comma at the end of a list */
      { $1::[] }
    | IDENTITY_NAME
      { $1::[] }
    ;


transition :
    | IDENTITY_NAME list_of_transition_params
      { astd_parser_msg ("Transition construction " ^ $1); 
        ASTD_transition.transition (ASTD_label.of_string $1) $2 }
    | IDENTITY_NAME 
      { astd_parser_msg ("Transition without params construction " ^ $1); 
        ASTD_transition.transition (ASTD_label.of_string $1) [] }
    ;

list_of_transition_params :
    | LPAR RPAR 
      { [] }
    | LPAR list_of_transition_params_content RPAR
      { $2 }
    ;

list_of_transition_params_content :
    | transition_param COMMA list_of_transition_params_content
      { $1::$3 }
    | transition_param
      { $1::[] }
    ;

transition_param :
    | term
      { ASTD_transition.parameter_from_term $1 }
    | captured_variable
      { ASTD_transition.parameter_from_capture $1 }
    ;

captured_variable :
    | QMARK IDENTITY_NAME COLON IDENTITY_NAME
      { ASTD_variable.variable_of $2 $4 true }
    ;

list_of_names :
    |LSET list_of_names_content RSET
      { astd_parser_msg ("List of names "); 
        $2 }
    | LSET RSET
      { astd_parser_msg ("List of names "); 
        [] }
    ;


list_of_names_content :
    | IDENTITY_NAME COMMA list_of_names_content
      { $1::$3 }
    | IDENTITY_NAME COMMA /* trailing comma at the end of a list */
      { $1::[] }
    | IDENTITY_NAME
      { $1::[] }
    ;


list_of_meanings :
    | LSET list_of_meanings_content RSET
      { astd_parser_msg ("List of meanings "); 
        $2 }
    ;


list_of_meanings_content :
    | name_astd_link COMMA list_of_meanings_content
      { $1::$3}
    | name_astd_link COMMA /* trailing comma at the end of a list */
      { $1::[] }
    | name_astd_link
      { $1::[] }
    ;


name_astd_link :
    | LPAR IDENTITY_NAME LINK astd RPAR
      { (ASTD_astd.rename_astd $4 $2) }
    ;


list_of_arrows :
    | LSET RSET
      { astd_parser_msg ("List of arrows "); 
        [] }
    | LSET list_of_arrows_content RSET
      { astd_parser_msg ("List of arrows "); 
        $2 }
    ;


list_of_arrows_content :
    |  arrow COMMA list_of_arrows_content
      { astd_parser_msg ("arrow created "); 
        $1::$3 }
    |  arrow COMMA /* trailing comma at the end of a list */
      { astd_parser_msg ("arrow created "); 
        $1::[] }
    |  arrow
      { astd_parser_msg ("arrow created "); 
        $1::[] }
    ;


arrow :
    | LPAR LPAR LOCAL COMMA IDENTITY_NAME COMMA IDENTITY_NAME RPAR COMMA arrow_end RPAR
      { astd_parser_msg ("arrow local "); 
        let (a,b,c,d) = $10 in ASTD_arrow.local_arrow $5 $7 a b c d }
    | LPAR LPAR FROM_SUB COMMA IDENTITY_NAME COMMA IDENTITY_NAME COMMA IDENTITY_NAME RPAR COMMA arrow_end RPAR
      { astd_parser_msg ("arrow fsub"); 
        let (a,b,c,d) = $12 in ASTD_arrow.fsub_arrow $7 $9 $5 a b c d }
    | LPAR LPAR TO_SUB COMMA IDENTITY_NAME COMMA IDENTITY_NAME COMMA IDENTITY_NAME RPAR COMMA arrow_end RPAR
      { astd_parser_msg ("arrow tsub"); 
        let (a,b,c,d) = $12 in ASTD_arrow.tsub_arrow $5 $9 $7 a b c d }
    ;


arrow_end :
    | transition COMMA list_of_guards COMMA TRUE
      { astd_parser_msg ("detail of arrow t"); 
        ($1,$3,true,None) }
    | transition COMMA list_of_guards COMMA FALSE
      { astd_parser_msg ("detail of arrow f"); 
        ($1,$3,false,None) }
    | transition COMMA list_of_guards COMMA STRING_VALUE COMMA TRUE
      { astd_parser_msg ("detail of arrow t"); 
        ($1,$3,true,ASTD_action.action_of_string $5) }
    | transition COMMA list_of_guards COMMA STRING_VALUE COMMA FALSE
      { astd_parser_msg ("detail of arrow f"); 
        ($1,$3,false,ASTD_action.action_of_string $5) }
    ;


list_of_guards :
    | LSET RSET 
      { astd_parser_msg ("List of guards "); 
        [] }   
    | LSET list_of_guards_content RSET
      {$2}
    ;

list_of_guards_content :
    | guard
      { $1::[] }
    ;

guard :
    | FILE COLON STRING_VALUE 
      { ASTD_guard.guard_of_string $3 }
    ;


astd_sequence :
    | BEGIN_ASTD SEQUENCE SCOLON list_of_imports list_of_attributes code astd SCOLON astd END_ASTD
      { ASTD_astd.sequence_of (ASTD_astd.give_name ()) $5 $6 $7 $9 }
    ;


astd_choice :
    | BEGIN_ASTD CHOICE SCOLON list_of_imports list_of_attributes code astd SCOLON astd END_ASTD
      { astd_parser_msg ("astd_choice "); ASTD_astd.choice_of (ASTD_astd.give_name ()) $5 $6 $7 $9 }
    ;


astd_kleene :
    | BEGIN_ASTD KLEENE SCOLON list_of_imports list_of_attributes code astd END_ASTD 
      { ASTD_astd.kleene_of (ASTD_astd.give_name ()) $5 $6 $7 }
    ;


astd_synchronisation :
    | BEGIN_ASTD LSYNCHRO RSYNCHRO SCOLON list_of_labels SCOLON list_of_imports list_of_attributes code astd SCOLON astd END_ASTD
      { ASTD_astd.synchronisation_of (ASTD_astd.give_name ()) $5 $8 $9 $10 $12 }
    ;
    /* Interleave */
    | BEGIN_ASTD INTERLEAVE SCOLON list_of_imports list_of_attributes code astd SCOLON astd END_ASTD
      { ASTD_astd.synchronisation_of (ASTD_astd.give_name ()) [] $5 $6 $7 $9 }
    ;
    /* Parallel Composition */
    | BEGIN_ASTD PARALLEL SCOLON list_of_imports list_of_attributes code astd SCOLON astd END_ASTD
      { ASTD_astd.parallelcomposition_of (ASTD_astd.give_name ()) $5 $6 $7 $9 }
    ;


astd_qchoice :
    | BEGIN_ASTD CHOICE COLON SCOLON quantification_variable SCOLON complex_val_construction SCOLON list_of_imports list_of_attributes code astd END_ASTD
      { ASTD_astd.qchoice_of (ASTD_astd.give_name ()) $5 $7 $10 $11 [] $12 }
    ;

parameter_of_astd :
  | typed_variable
    { ASTD_variable.set_readonly $1 false }

quantification_variable :
  | typed_variable
    { ASTD_variable.set_readonly $1 true }

typed_variable : 
    | LPAR IDENTITY_NAME COMMA IDENTITY_NAME RPAR 
      { ASTD_variable.of_strings $2 $4 } 
    | IDENTITY_NAME /* For retrocompatibility, we only accepted int values prior to exASTD */
      { ASTD_variable.of_strings $1 "int" } 
    ; 


complex_val_construction :
    | LSET UNDERSCORE RSET /* Beta feature : this does not support indeterministic events and is mostly untested, use at your own risks */
      { ASTD_constant.Domain.add (ASTD_constant.value_of ASTD_constant.FreeConst) (ASTD_constant.Domain.empty) }
    | val_construction
      { $1 }
    | string_val_construction
      { $1 }
    | val_construction REMOVE val_construction
      { astd_parser_msg "Suppression from domain" ; ASTD_constant.remove_domain_from $3 $1 }       
    ;


val_construction : 
    | val_construction_range
      { $1 }
    | val_construction_explicit 
      { $1 }
    | val_construction_range PLUS val_construction
      { ASTD_constant.fusion $1 $3 }
    | val_construction_explicit PLUS val_construction
      { ASTD_constant.fusion $1 $3 }
    ;


val_construction_range :
    | LINT INT_VALUE COMMA INT_VALUE RINT
      { astd_parser_msg "Construction from range" ; 
        ASTD_constant.Domain.add (ASTD_constant.range_of $2 $4) (ASTD_constant.Domain.empty) }
    ;


val_construction_explicit :
    | LSET list_val_content RSET 
      { astd_parser_msg "Explicit construction" ; 
        $2 }
    ;


list_val_content :
    | INT_VALUE COMMA list_val_content
      { ASTD_constant.Domain.add (ASTD_constant.value_of(ASTD_constant.of_int $1)) $3 }
    | INT_VALUE COMMA /* trailing comma at the end of a list */
      { ASTD_constant.Domain.add (ASTD_constant.value_of(ASTD_constant.of_int $1)) (ASTD_constant.Domain.empty) }
    | INT_VALUE 
      { ASTD_constant.Domain.add (ASTD_constant.value_of(ASTD_constant.of_int $1)) (ASTD_constant.Domain.empty) }
    ;

string_val_construction :
    | LSET string_list_content RSET 
      { astd_parser_msg "Explicit construction" ; 
        $2 }
    ;


string_list_content :
    | STRING_VALUE COMMA string_list_content
      { ASTD_constant.Domain.add (ASTD_constant.value_of(ASTD_constant.Symbol ($1))) $3 }
    | STRING_VALUE
      { ASTD_constant.Domain.add (ASTD_constant.value_of(ASTD_constant.Symbol ($1))) (ASTD_constant.Domain.empty) }
    ;



astd_qsynchro :
    | BEGIN_ASTD LSYNCHRO RSYNCHRO COLON SCOLON quantification_variable SCOLON complex_val_construction SCOLON list_of_labels SCOLON list_of_imports list_of_attributes code astd END_ASTD
      {ASTD_astd.qsynchronisation_of (ASTD_astd.give_name ()) $6 ($8) $10 $13 $14 [] $15 }
    ;
    /* Q-Interleave */
    | BEGIN_ASTD INTERLEAVE COLON SCOLON quantification_variable SCOLON complex_val_construction SCOLON list_of_imports list_of_attributes code astd END_ASTD
      {ASTD_astd.qsynchronisation_of (ASTD_astd.give_name ()) $5 ($7) [] $10 $11 [] $12 }
    ;
    /* Q-Parallel Composition */
    | BEGIN_ASTD PARALLEL COLON SCOLON quantification_variable SCOLON complex_val_construction SCOLON list_of_imports list_of_attributes code astd END_ASTD
      {ASTD_astd.qparallelcomposition_of (ASTD_astd.give_name ()) $5 ($7) $10 $11 [] $12 }
    ;


astd_guard :
    | BEGIN_ASTD GUARD SCOLON list_of_imports list_of_attributes code list_of_guards SCOLON astd END_ASTD
      { ASTD_astd.guard_of (ASTD_astd.give_name ()) $5 $6 $7 $9 }
    ;


astd_call :
    | BEGIN_ASTD CALL SCOLON list_of_imports IDENTITY_NAME SCOLON fct_vect END_ASTD
      { ASTD_astd.call_of (ASTD_astd.give_name ()) $5 $7}
    ;


fct_vect :
    | LSET RSET
      { [] }     
    | LSET fct_vect_content RSET
      { $2 }
    ;


fct_vect_content :
    |fct_assoc COMMA fct_vect_content
      { $1::$3 }
    |fct_assoc COMMA /* trailing comma at the end of a list */
      { $1::[] }
    |fct_assoc
      { $1::[] }
    ;


fct_assoc :
    | LPAR IDENTITY_NAME LINK term RPAR
      { $2, $4 }
    ;
    | IDENTITY_NAME LINK term 
      { $1, $3 }
    ;

term :
    | IDENTITY_NAME 
      { astd_parser_msg ("term "); 
        (ASTD_term.Var(ASTD_variable.variable_name_of_string $1))}
    | STRING_VALUE
      { astd_parser_msg ("term "); 
        (ASTD_term.Const(ASTD_constant.Symbol($1))) }
    | INT_VALUE
      { astd_parser_msg ("term "); 
        (ASTD_term.Const(ASTD_constant.of_int ($1)))}
    | UNDERSCORE
      { astd_parser_msg ("term "); 
        (ASTD_term.Const(ASTD_constant.FreeConst)) }

    /*
    | LPAR term PLUS term RPAR
      { astd_parser_msg ("term "); 
        (ASTD_term.Addition($2,$4))}

    | LPAR term KLEENE term RPAR
      { astd_parser_msg ("term "); 
        (ASTD_term.Multiplication($2,$4))}

    | LPAR term REMOVE term RPAR
      { astd_parser_msg ("term "); 
        (ASTD_term.Substraction($2,$4))}
    */
    ;

apply_event:
  | event_to_apply SCOLON apply_event
     {$1::$3}
  | event_to_apply apply_event
     {$1::$2}
  | event_to_apply
     {$1::[]}
  | event_to_apply SCOLON
     {$1::[]}
;

event_to_apply:
  | IDENTITY_NAME list_of_value
      { astd_parser_msg ("Event " ^ $1); 
        ASTD_event.event (ASTD_label.of_string $1) $2 }
  | IDENTITY_NAME 
      { astd_parser_msg ("Transition without params construction " ^ $1); 
        ASTD_event.event (ASTD_label.of_string $1) [] }
;

list_of_value:
  |LPAR RPAR /* allows no parameters */
    { [] }
  |LPAR list_of_value_content RPAR
      {$2}
;

list_of_value_content :
    | INT_VALUE COMMA list_of_value_content
      { (ASTD_constant.of_int $1)::$3 }
    | INT_VALUE COMMA /* trailing comma at the end of a list */
      { (ASTD_constant.of_int $1)::[] }
    | INT_VALUE 
      { (ASTD_constant.of_int $1)::[] }
    | STRING_VALUE COMMA list_of_value_content
      { (ASTD_constant.Symbol ($1))::$3 }
    | STRING_VALUE COMMA /* trailing comma at the end of a list */
      { (ASTD_constant.Symbol ($1))::[] }
    | STRING_VALUE
      { (ASTD_constant.Symbol ($1))::[] }
    ;
