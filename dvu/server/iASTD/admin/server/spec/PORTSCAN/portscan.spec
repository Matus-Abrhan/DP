(portscan_seq,
    <aut;
      {
	      (n0->elem),
	      (n1->elem),
        (n2->elem)
      };
      {
	      ((local,n0,n1),e(_,_,ipdst,portdst,?tcpflags1 : string,_), {file : "guard1"},"",false),
        ((local,n1,n2),e(ipdst,portdst,_,_,?tcpflags2 : string,_), {file : "guard2"},"Functions.action1(count, thres)",false)
      };
      {n0,n1,n2};
      {};
      n0
>)
{
(ipdst,string)->{"192.168.1.129","10.10.8.136"},
(portdst,string)->{"62796","63052","4444","152","53","41","smtp","http","https","imap2","ssh","telnet","bgp","netbios-ns","kerberos","snmp","gopher","netstat","pop3","loc-srv","195","153","254","tacacs-ds","234","188","190","118","sftp","msp","mailq","74","197","185","155","28","6","46","snmp-trap","250","151","224","157","finger","netbios-dgm","bootpc","hostnames","141","225","ftp-data","whois","irc","systat","poppassd","235","149","qmtp","bootps","discard","qmtp","chargen","44","83","45","252"},
(count,int)->[0,300],
(thres,int)->[0,100]
};

(MAIN,
       <|||:;
	       (ipdst,string);
	       {"10.10.8.136","192.168.1.129"};
         imports : {"functions.ml"};
	       attributes : {
		       (count,int,0),
           (thres,int,45)
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
                          thres->thres
                          }
                      >
               >
 >)
