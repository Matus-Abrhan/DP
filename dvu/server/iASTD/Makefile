YACC=ocamlyacc
LEX=ocamllex
OCAMLFIND = ocamlfind
OCAMLOPT = ocamlopt
OCAMLC = ocamlc 
OCAMLDEP = ocamldep
MKTOPLEVEL = ocamlmktop
OCAMLCLIB = str.cma dynlink.cma
OCAMLOPTLIB = str.cmxa dynlink.cmxa
INCLUDES = -g 
OCAMLOPTFLAGS = $(INCLUDES) 
OCAMLFLAGS = $(INCLUDES) 
OCAMLDEPFLAGS =
TESTFOLDER = TUnit
BUILDFOLDER = _build
CLIENTBUILDFOLDER = _build_client

OCAMLTOPLEVEL = ocaml_ASTD
INTERPRETER = xASTD
DEBUGABLE = debug_xASTD
UNITTESTS = unit_tests
INIT = init

TARGET = $(INTERPRETER) $(OCAMLTOPLEVEL) $(DEBUGABLE) $(UNITTESTS)

BASE = ASTD_functions \
	ASTD_constant \
	ASTD_variable ASTD_term \
	ASTD_attribute \
	ASTD_action \
	ASTD_label ASTD_environment \
	ASTD_plugin_interfaces \
	ASTD_guard \
	ASTD_event ASTD_transition \
	ASTD_arrow \
	ASTD_optimisation \
	ASTD_wrapper_generator \
	ASTD_astd \
	ASTD_state \
	ASTD_static_kappa_indirect \
	ASTD_exec_first_hash \
	ASTD_plugin_builder \
	
TESTS = Test_ASTD_environment \
		Test_ASTD_transition \
		Test_ASTD_action

PARSER = ASTD_parser

PARSERRULES = ASTD_lexer_rules ASTD_parser_rules  

OBJ = $(BASE) $(PARSERRULES) $(PARSER)
OBJCMX = $(addprefix $(BUILDFOLDER), $(addprefix /, $(addsuffix .cmx,$(OBJ)))) 
OBJCMO = $(addprefix $(BUILDFOLDER), $(addprefix /, $(addsuffix .cmo,$(OBJ))))

TESTCMO = $(addprefix $(TESTFOLDER), $(addprefix /, $(addprefix $(BUILDFOLDER), $(addprefix /, $(addsuffix .cmo,$(TESTS))))))

DOC = $(BASE) $(PARSER)
DOCMLI = $(addsuffix .mli,$(DOC))  

GENDOC = gen_ocamldoc/gen_ocamlpai

# MAIN RULES 

.PHONY : depend 
all : clean $(INIT) $(TARGET)
	./unit_tests

$(OCAMLTOPLEVEL) : $(OBJCMO)
	$(OCAMLFIND) $(MKTOPLEVEL) $(OCAMLFLAGS) $(OCAMLCLIB) unix.cma -I $(BUILDFOLDER) $^ -o $@

$(DEBUGABLE) : $(OBJCMO)  ASTD_main.ml
	$(OCAMLFIND) $(OCAMLC) $(OCAMLFLAGS) $(OCAMLCLIB) unix.cma -I $(BUILDFOLDER) $^ -o $@

$(INTERPRETER) : $(OBJCMX) ASTD_main.ml
	$(OCAMLFIND) $(OCAMLOPT) $(OCAMLOPTFLAGS) $(OCAMLOPTLIB) unix.cmxa -I $(BUILDFOLDER) $^ -o $@

$(UNITTESTS) : $(OBJCMO) $(TESTCMO)
	$(OCAMLFIND) $(OCAMLC) $(OCAMLFLAGS) $(OCAMLCLIB) -package oUnit -linkpkg -I $(BUILDFOLDER) $^ -o $@ 

$(INIT) :
	# Create if not exists
	-if [ ! -d $(BUILDFOLDER)/ ] 				; then mkdir $(BUILDFOLDER)/ ; fi 
	-if [ ! -d $(TESTFOLDER)/$(BUILDFOLDER)/ ] 	; then mkdir $(TESTFOLDER)/$(BUILDFOLDER)/ ; fi 

# SPECIAL RULES FOR PARSER  

$(BUILDFOLDER)/ASTD_lexer_rules.ml: ASTD_lexer_rules.mll $(BUILDFOLDER)/ASTD_parser_rules.cmi
	$(LEX) -o $@ ASTD_lexer_rules.mll 

$(BUILDFOLDER)/ASTD_parser_rules.ml: ASTD_parser_rules.mly
	$(YACC) -b $(BUILDFOLDER)/ASTD_parser_rules ASTD_parser_rules.mly 

$(BUILDFOLDER)/ASTD_parser_rules.cmx: $(BUILDFOLDER)/ASTD_parser_rules.ml $(BUILDFOLDER)/ASTD_parser_rules.cmi 
	$(OCAMLOPT) -c -o $@ -I $(BUILDFOLDER) $<

$(BUILDFOLDER)/ASTD_parser_rules.cmi: $(BUILDFOLDER)/ASTD_parser_rules.mli
	$(OCAMLC) $(OCAMLFLAGS) -c -o $@ -I $(BUILDFOLDER) $<

$(BUILDFOLDER)/ASTD_parser_rules.cmo: $(BUILDFOLDER)/ASTD_parser_rules.ml
	$(OCAMLC) $(OCAMLFLAGS) -c -o $@ -I $(BUILDFOLDER) $< 

$(BUILDFOLDER)/ASTD_parser_rules.mli: $(BUILDFOLDER)/ASTD_parser_rules.ml

$(BUILDFOLDER)/ASTD_lexer_rules.cmx: $(BUILDFOLDER)/ASTD_lexer_rules.ml
	$(OCAMLOPT) $(OCAMLFLAGS) -c -o $@ -I $(BUILDFOLDER) $< 

$(BUILDFOLDER)/ASTD_lexer_rules.cmo: $(BUILDFOLDER)/ASTD_lexer_rules.ml
	$(OCAMLC) $(OCAMLFLAGS) -c -o $@ -I $(BUILDFOLDER) $< 

# SPECIAL RULES FOR ACTION PARSER

$(BUILDFOLDER)/ASTD_action_lexer.ml: ASTD_action_lexer.mll $(BUILDFOLDER)/ASTD_action_parser.cmi
	$(LEX) -o $@ ASTD_action_lexer.mll 

$(BUILDFOLDER)/ASTD_action_parser.ml: ASTD_action_parser.mly
	$(YACC) -b $(BUILDFOLDER)/ASTD_action_parser ASTD_action_parser.mly 

$(BUILDFOLDER)/ASTD_action_parser.cmx: $(BUILDFOLDER)/ASTD_action_parser.ml $(BUILDFOLDER)/ASTD_action_parser.cmi 
	$(OCAMLOPT) -c -o $@ -I $(BUILDFOLDER) $<

$(BUILDFOLDER)/ASTD_action_parser.cmi: $(BUILDFOLDER)/ASTD_action_parser.mli
	$(OCAMLC) $(OCAMLFLAGS) -c -o $@ -I $(BUILDFOLDER) $<

$(BUILDFOLDER)/ASTD_action_parser.cmo: $(BUILDFOLDER)/ASTD_action_parser.ml
	$(OCAMLC) $(OCAMLFLAGS) -c -o $@ -I $(BUILDFOLDER) $< 

$(BUILDFOLDER)/ASTD_action_parser.mli: $(BUILDFOLDER)/ASTD_action_parser.ml

$(BUILDFOLDER)/ASTD_action_lexer.cmx: $(BUILDFOLDER)/ASTD_action_lexer.ml
	$(OCAMLOPT) $(OCAMLFLAGS) -c -o $@ -I $(BUILDFOLDER) $< 

$(BUILDFOLDER)/ASTD_action_lexer.cmo: $(BUILDFOLDER)/ASTD_action_lexer.ml
	$(OCAMLC) $(OCAMLFLAGS) -c -o $@ -I $(BUILDFOLDER) $< 

# GENERIC RULES

.SUFFIXES: .ml .mli .cmo .cmi .cmx

$(TESTFOLDER)/$(BUILDFOLDER)/%.cmo : $(TESTFOLDER)/%.ml
	$(OCAMLFIND) $(OCAMLC) -package oUnit -linkpkg $(OCAMLFLAGS) -c -o $@ -I $(BUILDFOLDER) $< 

$(BUILDFOLDER)/%.cmo: %.ml $(BUILDFOLDER)/%.cmi 
	$(OCAMLC) $(OCAMLFLAGS) -c -o $@ -I $(BUILDFOLDER) $< 

$(BUILDFOLDER)/%.cmx: %.ml $(BUILDFOLDER)/%.cmi 
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -c -o $@ -I $(BUILDFOLDER) $< 

$(BUILDFOLDER)/%.cmi: %.mli
	$(OCAMLC) $(OCAMLFLAGS) -c -o $@ -I $(BUILDFOLDER) $< 

# This line is meant to prevent the removal of .cmi files, which are considered intermediary by Make and removed automatically
.PRECIOUS: $(BUILDFOLDER)/%.cmi

# CLEAN
clean: 
	-\rm -rf $(BUILDFOLDER)
	-\rm -rf $(CLIENTBUILDFOLDER)
	-\rm -rf $(TESTFOLDER)/$(BUILDFOLDER)

cleantarget:
	-\rm $(TARGET)

cleandoc:
	-\rm -f types_dependencies.dot modules_dependencies.dot 
	-\rm -f -r doc/*

cleangendoc: 
	-\rm -f $(GENDOC).cm*

cleanall: clean cleandoc cleangendoc cleantarget
	-\rm -f .depend

# DOC 
doc: cleandoc $(DOCMLI) types_dependencies.dot modules_dependencies.dot doc/index.html

$(GENDOC).cmo : $(GENDOC).ml
	ocamlc -I $$(dirname `ocamldoc -customdir`) -c $^

doc/index.html : $(GENDOC).cmo $(TARGET) 
	-if [ ! -d doc/ ] ; then mkdir doc/ ; fi 
	cp -f -p template/style.css doc/
	ocamldoc -v -css-style style.css \
             -colorize-code -keep-code \
             -g $(GENDOC).cmo -max-line-length 800 \
             -t OCamlPAI -d doc/ $(DOCMLI) 

modules_dependencies.dot : $(TARGET)
	ocamldoc -dot -dot-include-all ASTD*.ml -o modules_dependencies.dot

types_dependencies.dot : $(TARGET)
	ocamldoc -dot -dot-include-all -dot-types ASTD*.ml -o types_dependencies.dot

# TESTS
test: 
	python func_tests.py

unit:
	./unit_tests

# DEPENDENCIES
.depend:
	$(OCAMLDEP) $(OCAMLDEPFLAGS) *.mli *.ml > .depend

include .depend

