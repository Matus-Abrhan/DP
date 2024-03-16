(MAIN,
  <|||:;
     (ipdst, string);
     {"72.5.65.99","104.17.39.137","104.17.41.137"}; 
     imports: {"functions.ml"}; 
     <|||:;
       (portdst, string);
       {"80","53"};
      <*;
       <aut;
         {
          (n0->elem),
          (n1->elem)
         };
         {
          ((local,n0,n1), e(?ipdst:string,portdst), {file: "guard1"},"Functions.action1()", false)
         };
         {n1};
         {};
         n0
       >
     >
   >
>)
