(MAIN,
    <*;
    <aut;
	imports: {"functions.ml"};
	{
	(n0->elem),
	(n1->elem)
	};
	{
	((local, n0, n1), e(?x:WinEventLog), {file: "guard1"}, "Functions.action1()", false),
	};
	{n1};
	{};
	n0
    >
    >
)
