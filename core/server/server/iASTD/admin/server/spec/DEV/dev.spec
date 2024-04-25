(MAIN,
    <*;
    <aut;
	imports: {"functions.ml"};
	{
	(n0->elem),
	(n1->elem),
	(n2->elem),
	(n3->elem)
	};
	{
	((local, n0, n1), e(?x:int,_,_,_,_,_,_), {file: "guard1"}, "Functions.action1()", false),
	((local, n0, n2), e(?x:int,_,_,_,_,_,_), {file: "guard2"}, "Functions.action2()", false),
	((local, n0, n3), e(?x:int,_,_,_,_,_,_), {file: "guard3"}, "Functions.action3()", false)
	};
	{n1,n2,n3};
	{};
	n0
    >
    >
)
