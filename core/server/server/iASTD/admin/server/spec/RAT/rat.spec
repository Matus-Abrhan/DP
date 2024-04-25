(portscan_seq,
    <aut;
      {
	(n0->elem),
	(n1->elem),
        (n2->elem)
      };
      {
	((local,n0,n1),e(_,_,_,ipdst,portdst,?tcpflags1 : string,_), {file : "guard1"},"",false),
        ((local,n1,n2),e(_,ipdst,portdst,_,_,?tcpflags2 : string,_), {file : "guard2"},"Functions.action1(count, thres, recon_end)",false)
      };
      {n0,n1,n2};
      {};
      n0
>)
{
(ipdst,string)->{"192.168.1.129","10.10.8.136","10.10.8"},
(portdst,string)->{"62796","63052","4444","152","53","41","smtp","http","https","imap2","ssh","telnet","bgp","netbios-ns","kerberos","snmp","gopher","netstat","pop3","loc-srv","195","153","254","tacacs-ds","234","188","190","118","sftp","msp","mailq","74","197","185","155","28","6","46","snmp-trap","250","151","224","157","finger","netbios-dgm","bootpc","hostnames","141","225","ftp-data","whois","irc","systat","poppassd","235","149","qmtp","bootps","discard","qmtp","chargen","44","83","45","252"},
(count,int)->[0,300],
(thres,int)->[0,100],
(recon_end,int)->{0,1}
};

(exploit_seq,
    <aut;
      {
	(n4->elem),
	(n5->elem),
        (n6->elem)
      };
      {
	((local,n4,n5),e(_,ipsrc,_,ipdst,_,?tcpflags1 : string,_), {file : "guard4"},"",false),
        ((local,n5,n6),e(_,ipdst,_,ipsrc,_,?tcpflags2 : string,?payload : string), {file : "guard5"},"Functions.action2()",true)
      };
      {n6};
      {};
      n4
>)
{
(ipsrc,string)->{"10.10.8.136","192.168.1.129","10.10.8.130"},
(ipdst,string)->{"192.168.1.129","10.10.8.136","10.10.8.130"}
};

(MAIN,
   <.;
    imports : {"functions.ml"};
    attributes : {
     (thres,int,45),
     (recon_end,int,0)
    };
    (recon_phase,
       <|||:;
	       (ipdst,string);
	       {"10.10.8.136","192.168.1.129","10.10.8.130"};
	       attributes : {
      		 (count,int,0)
	       };
	       <|||:;
	                (portdst, string);
		        {"62796","63052","4444","152","53","41","smtp","http","https","imap2","ssh","telnet","bgp","netbios-ns","kerberos","snmp","gopher","netstat","pop3","loc-srv","195","153","254","tacacs-ds","234","188","190","118","sftp","msp","mailq","74","197","185","155","28","6","46","snmp-trap","250","151","224","157","finger","netbios-dgm","bootpc","hostnames","141","225","ftp-data","whois","irc","systat","poppassd","235","149","qmtp","bootps","discard","qmtp","chargen","44","83","45","252"};
                        <call;
                         portscan_seq;
                         {
                          ipdst->ipdst,
                          portdst->portdst,
                          count->count,
                          thres->thres,
                          recon_end->recon_end
                          }
                         >
               >
      >);
      (exploit_phase,
	     <=>;
	     {file : "guard3"};
	     <|||:;
	       (ipsrc, string);
	       {"10.10.8.136","192.168.1.129","10.10.8.130"};
	       <|||:;
		       (ipdst,string);
		       {"192.168.1.129","10.10.8.136","10.10.8.130"};
                       <call;
                         exploit_seq;
                         {
                          ipsrc->ipsrc,
                          ipdst->ipdst
                          }
                        >
               >
             >
      >)
>)
