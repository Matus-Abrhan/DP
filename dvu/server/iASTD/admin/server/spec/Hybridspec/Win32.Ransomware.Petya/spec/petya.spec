(MAIN,
 <|||;
  imports: {"functions.ml"};
  attributes: { 
         (d1, int, 0),
         (d2, int, 0) 
  };
  <|||:;
     (ipdst, string);
     {"192.168.56.101"}; 
     <|||:;
       (portdst, string);
       {"80","445"};
      <*;
       <aut;
         {
          (n0->elem),
          (n1->elem)
         };
         {
          ((local,n0,n1), e(?x1:HTTPSession), {file: "guard1"},"Functions.action1(d1)", false)
         };
         {n1};
         {};
         n0
       >
     >
   >
 >;
 <|||:;
  (ip, string);
  {"10.128.4.1"};
  <*;
   <aut;
    {
      (n2->elem),
      (n3->elem),
      (n4->elem)
    };
    {
      ((local,n2,n3), e(?x2:WinEventLog), {file: "guard2"}, "", false),
      ((local,n3,n4), e(?x3:WinEventLog), {file: "guard3"}, "Functions.action2(d2)", false)
    };
    {n4};
    {};
    n2
   >
  >
 >
>)
