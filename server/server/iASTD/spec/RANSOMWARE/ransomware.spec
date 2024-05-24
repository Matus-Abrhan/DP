(MAIN,
    <*;
    <aut;
	imports: {"global_functions.ml", "functions.ml"};
	{
	(n0->elem),
	(n1->elem),
	(n2->elem),
	(n3->elem)
	};
	{
	((local, n0, n1), e(?x:WinEventLog), {file: "guard_t1083"}, "", false),
	((local, n1, n2), e(?x:WinEventLog), {file: "guard_t1222"}, "", false),
	((local, n2, n3), e(?x:WinEventLog), {file: "guard_t1486"}, "Functions.alert3()", false),
	};
	{n3};
	{};
	n0
    >
    >
)
