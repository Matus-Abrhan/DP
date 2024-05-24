type token =
  | BOOL of (string)
  | IDENTITY_NAME of (string)
  | STRING_VALUE of (string)
  | INT_VALUE of (int)
  | IMPORTS
  | ATTRIBUTES
  | CODE
  | FILE
  | LAMBDA
  | AUTOMATA
  | ELEM
  | BEGIN_ASTD
  | END_ASTD
  | CALL
  | TRUE
  | FALSE
  | SEQUENCE
  | CHOICE
  | PARALLEL
  | INTERLEAVE
  | LSYNCHRO
  | RSYNCHRO
  | LENV
  | RENV
  | GUARD
  | KLEENE
  | PLUS
  | QMARK
  | LPAR
  | RPAR
  | LINT
  | RINT
  | LSET
  | RSET
  | COLON
  | SCOLON
  | COMMA
  | IS
  | EQUALS
  | LINK
  | REMOVE
  | LOCAL
  | FROM_SUB
  | TO_SUB
  | UNDERSCORE
  | EOF

val structure :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> unit
val apply_event :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> ASTD_event.t list
