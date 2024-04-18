(MAIN,
	<*;
		<aut;
			imports: {"functions.ml"};
			{
			(n0->elem),
			(n2->elem),
			(n3->elem),
			(n4->elem),
			(n5->elem),
			(n6->elem)
			};
			{
			((local, n0, n2),e(?x:int,_,_,_,_,_,_),{file:"guard_DUMMY1"},"Functions.alert_DUMMY1",false),
			((local, n0, n3),e(?ipdst:string,?portdst:string,_,_,_,_,_),{file:"guard_DUMMY2"},"Functions.alert_DUMMY2",false),
			((local, n0, n4),e(?ipdst:string,?portdst:string,_,_,_,_,_),{file:"guard_TEST"},"Functions.alert_TEST",false),
			((local, n0, n5),e(_,_,ipdst,portdst,?tcpflags1:string,_,_),{file:"guard_PORTSCAN"},"Functions.alert_PORTSCAN",false),
			((local, n0, n6),e(_,_,_,ipdst,portdst,?tcpflags1:string,_),{file:"guard_RAT"},"Functions.alert_RAT",false)
			};
			{n2,n3,n4,n5,n6};
			{};
			n0
		>
	>
)