let contains s1 s2 =
    let re = Str.regexp_string s2
    in
        try ignore (Str.search_forward re s1 0); true
        with Not_found -> false

let alert (msg : string) : unit =
   print_endline msg


let action1 (d1 : int ref) : unit =
  if !d1 = 0 then
     alert("Net/Win32.Ransom.WannaCry - Communicating With CnC Server");
     d1 := !d1 + 1

let action2 (d2: int ref) : unit =
  if !d2 = 0 then
     alert("Host/Win32.Ransom.WannaCry - Communicating With CnC Server");
     d2 := !d2 + 1
