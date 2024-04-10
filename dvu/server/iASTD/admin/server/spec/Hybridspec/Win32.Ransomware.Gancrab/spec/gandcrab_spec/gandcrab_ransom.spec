(Email_Phishing,
  <aut;
   {
    (n0->elem),
    (n1->elem)
   };
   {
     ((local,n0,n1),e(?x0:HTTPSession),{file: "guard0"},"Functions.a0(isdwnld1,isdwnld2)", false)
   };
   {n1};
   {};
   n0
>)
{
  (ipdst,string)->{"18.222.240.45","18.188.34.58","209.141.49.93"},
  (portdst,string)->{"53","80"},
  (isdwnld1,int)->{0,1},
  (isdwnld2,int)->{0,1}
};

(Net_Exec_Code,
  <aut;
   {
    (n2->elem),
    (n3->elem),
    (n4->elem),
    (n5->elem)
   };
   {
     ((local,n2,n3),e(?x2:HTTPSession),{file: "guard2"},"",false),
     ((local,n3,n4),e(?x1:DNSSession),{file: "guard1"},"",false),
     ((local,n4,n5),e(?x3:HTTPSession),{file: "guard3"},"Functions.a1(x3.ipsrc,isdwnld1)",false)
   };
   {n5};
   {};
   n2
>)
{
  (ipdst,string)->{"18.222.240.45","18.188.34.58","209.141.49.93"},
  (portdst,string)->{"53","80"},
  (isdwnld1,int)->{0,1}
};

(Host_Exec_Code,
  <aut;
   {
    (n6->elem),
    (n7-> <|||;
            <aut;
             {
               (n8->elem),
               (n9->elem)
             };
             {
              ((local,n8,n9),e(?x6:WinEventLog),{file: "guard6"},"Functions.a2(isdwnld2)",false)
             };
             {n9};
             {};
             n8
           >;
           <aut;
             {
               (n10->elem),
               (n11-> <aut;
                       {
                        (n12->elem),
                        (n13->elem)
                       };
                       {
                        ((local,n12,n13),e(?x9:WinEventLog),{file: "guard9"},"Functions.a3(isdwnld2)",false)
                       };
                       {n13};
                       {};
                       n12
                      >
               )
             };
             {
              ((local,n10,n11),e(?x7:WinEventLog),{file: "guard7"},"",false),
              ((local,n11,n11),e(?x8:WinEventLog),{file: "guard8"},"",false)
             };
             {n11};
             {};
             n10
           >
        >
    )
   };
   {
     ((local,n6,n7),e(?x4:WinEventLog),{file: "guard4"},"",false),
     ((local,n7,n7),e(?x5:WinEventLog),{file: "guard5"},"",false)
   };
   {n7};
   {};
   n6
>)
{
  (ip,string)->{"18.222.240.45","18.188.34.58"},
  (isdwnld2,int)->{0,1}
};

(MAIN,
  <|||;
   imports: {"functions.ml"};
   attributes: {
   (isdwnld1,int,0),
   (isdwnld2,int,0)
   };
   (Phishing,
     <*;
       <|||:;
        (ipdst,string);
        {"18.222.240.45","18.188.34.58","209.141.49.93"};
        <|||:;
         (portdst, string);
         {"53","80"};
         <call;
           Email_Phishing;
           {
             ipdst->ipdst,
             portdst->portdst,
             isdwnld1->isdwnld1,
             isdwnld2->isdwnld2
            }
          >
        >
       >
    >);
   (Exec_Code,
     <|||;
      <*;
        <|||:;
          (ipdst,string);
          {"18.222.240.45","18.188.34.58","209.141.49.93"};
          <|||:;
            (portdst,string);
            {"53","80"};
            <call;
              Net_Exec_Code;
              {
               ipdst->ipdst,
               portdst->portdst,
               isdwnld1->isdwnld1
              }
            >
          >
        >
      >;
      <*;
       <|||:;
         (ip,string);
         {"18.222.240.45","18.188.34.58","209.141.49.93"};
         <call;
           Host_Exec_Code;
           {
             ip->ip,
             isdwnld2->isdwnld2
           }
         >
        >
      >
   >)
>)
