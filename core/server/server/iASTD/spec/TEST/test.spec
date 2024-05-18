(MAIN,
	<aut;
		imports: {"functions.ml"};
	        {
	        (n0->elem),
	        (n1->elem)
	        };
	        {
	        ((local, n0, n1), e(?x:string,?y:string), {file: "guard1"}, "Functions.alert1()", true),
	        };
	        {n1};
	        {};
	        n0
	>
)
