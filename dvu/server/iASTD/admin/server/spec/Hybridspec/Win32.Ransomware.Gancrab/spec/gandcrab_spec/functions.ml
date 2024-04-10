let a0 (isdwnld1: int ref) (isdwnld2: int ref) : unit =
    isdwnld1 := 1;
    isdwnld2 := 1

let a1 (ipsrc: string) (isdwnld1: int ref) : unit =
   if !isdwnld1 = 1 then 
      print_endline "Alert- Net/Win32.Ransom.GandCrab - Communicating With Command and Control Server";
      let os_type = Sys.os_type in
        (** Block Malicious IP **)
        if os_type = "Unix" then
           let cmd = Sys.command ("sudo iptables -A INPUT -s "^(ipsrc)^" -j DROP") in
               isdwnld1 := 0
      

let a2 (isdwnld2: int ref) : unit = 
    if !isdwnld2 = 1 then
       print_endline "Alert- Host/Win32.Ransom.GandCrab - CnC domain check in";
       isdwnld2 := 1

let a3 (isdwnld2: int ref) : unit =
    if !isdwnld2 = 1 then
        print_endline "Alert - Host/Win32.Ransom.GandCrab - Communicating With Command and Control Server";
        (** Block open port 3389**)
        let os_type = Sys.os_type in
          if os_type = "Windows" then 
             let cmd = Sys.command "netsh advfirewall firewall add rule name='BlockPort' protocol=TCP dir=in localport=3389 action=block" in
                 isdwnld2 := 1
                       
let contains s1 s2 =
  (*try ignore(Pcre.exec ~s2 s1); (true)
  with Not_found -> (false)*)
  let re = Str.regexp s2
    in
        try ignore(Str.search_forward re s1 0); true
        with Not_found -> false 
