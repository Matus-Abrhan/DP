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
	((local, n0, n1), e(?x:WinEventLog), {file: "guard_t1053"}, "", false),
	((local, n1, n2), e(?x:WinEventLog), {file: "guard_t1056"}, "", false),
	((local, n2, n3), e(?x:WinEventLog), {file: "guard_t1059"}, "Functions.alert3()", false),
	};
	{n3};
	{};
	n0
    >
    >
)
