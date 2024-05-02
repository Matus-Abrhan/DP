(* header section *)
{
    open ASTD_parser_rules ;;
 
    let ebs_lexer_debug = false ;;
    let ebs_lexer_msg m = if (ebs_lexer_debug) 
                           then print_endline m 
                           else ignore m;;
}

(* definitions section *)
let ws = ['\r''\n''\t'' '' ']
let lowerletters = ['a'-'z']
let upperletters = ['A'-'Z']
let letters = lowerletters | upperletters
let digits = ['0'-'9']
let id = "Id"
let underscore='_'
let quote='"'
let dot='.'
let hyphen='-'
let slash='/'

(* ORDER IS IMPORTANT HERE. Ref : http://caml.inria.fr/pub/docs/manual-ocaml-4.00/manual026.html
If several regular expressions match a prefix of the input,
the “longest match” rule applies: the regular expression that matches the longest prefix of the input is selected.
In case of tie, the regular expression that occurs earlier in the rule is selected. *)

(* rules section *)
rule token = parse
 | ws    { token lexbuf }
 | '%'   { LAMBDA }
 | "aut" { AUTOMATA }
 | '.'   { SEQUENCE }
 | '*'   { KLEENE }
 | '+'   { PLUS }
 | '?'   { QMARK }
 | "|["  { LSYNCHRO }
 | "]|"  { RSYNCHRO }
 | "|||" { INTERLEAVE }
 | "||"  { PARALLEL }
 | '|'   { CHOICE }
 | "=>"  { GUARD }
 | "->"  { ebs_lexer_msg "new LINT" ;LINK }
 | "(["  { LENV }
 | "])"  { RENV }
 | "call" { CALL }
 | "elem" { ELEM }
 | ['T' 't']"rue" { TRUE }
 | ['F' 'f']"alse" { FALSE }
 | '-'    { REMOVE }
 | "local"  {LOCAL}
 | "to_sub" {TO_SUB}
 | "from_sub" {FROM_SUB}
 | "imports" { IMPORTS }
 | "attributes" { ATTRIBUTES }
 | "code" { CODE }
 | "file" { FILE }
 | letters+ (letters+ | digits+ | underscore)*  { ebs_lexer_msg "identifiant_name"; IDENTITY_NAME (Lexing.lexeme lexbuf) }
 | quote ([^'"']* as string_name) quote         { ebs_lexer_msg "string_name";      STRING_VALUE  string_name }
 | digits+ as number                            { ebs_lexer_msg "new int value";    INT_VALUE     (int_of_string number) }


 | underscore                 {ebs_lexer_msg "new underscore" ; UNDERSCORE}
 | '<'   { BEGIN_ASTD }
 | '>'   { END_ASTD } 
 | '['   { ebs_lexer_msg "new LINT" ; LINT }
 | ']'   { ebs_lexer_msg "new RINT" ; RINT }
 | '{'   { ebs_lexer_msg "new LSET" ; LSET }
 | '}'   { ebs_lexer_msg "new RSET" ; RSET }
 | '('   { ebs_lexer_msg "new LPAR" ; LPAR }
 | ')'   { ebs_lexer_msg "new RPAR" ; RPAR }
 | ':'   { ebs_lexer_msg "new COLON" ; COLON }
 | ';'   { ebs_lexer_msg "new SCOLON" ; SCOLON }
 | ','   { ebs_lexer_msg "new COMMA" ; COMMA }
 | ":="  { IS }
 | '='   { EQUALS }
 | eof   { EOF }
