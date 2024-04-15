(MAIN,
	<*;
		<aut;
			imports: {"functions.ml"};
			{
			(n0->elem),
			(n4->elem),
			(n5->elem),
			(n6->elem)
			};
			{
			((local, n0, n4),e(?ipdst:string,?portdst:string),{file:"guard_TEST"},"Functions.alert_TEST",false),
			((local, n0, n5),e(_,_,ipdst,portdst,?tcpflags1:string,_),{file:"guard_PORTSCAN"},"Functions.alert_PORTSCAN",false),
			((local, n0, n6),e(_,_,_,ipdst,portdst,?tcpflags1:string,_),{file:"guard_RAT"},"Functions.alert_RAT",false)
			};
			{n4,n5,n6};
			{};
			n0
		>
	>
)