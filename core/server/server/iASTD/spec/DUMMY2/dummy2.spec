(MAIN,
    <*;
    <aut;
	imports: {"functions.ml"};
	{
	(n0->elem),
	(n1->elem),
	(n2->elem)
	};
	{
	((local, n0, n1), e(?ipdst:string,?portdst:string,_,_,_,_,_), {file: "guard1"}, "", false),
	((local, n1, n2), e(?ipdst:string,?portdst:string,_,_,_,_,_), {file: "guard2"}, "Functions.action1()", false)
	};
	{n2};
	{};
	n0
    >
    >
)
