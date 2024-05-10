(MAIN,
    <*;
    <aut;
	imports: {"global_functions.ml", "functions.ml"};
	{
	(n0->elem),
	(n1->elem)
	};
	{
	((local, n0, n1), e(?x:WinEventLog), {file: "guard1"}, "Functions.alert1()", false),
	};
	{n1};
	{};
	n0
    >
    >
)
