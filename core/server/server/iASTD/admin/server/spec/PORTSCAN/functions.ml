let alert1 () : unit = 
   print_endline "Alert Portscan attack"

let comp (s1 : int ref ) (s2 : int) : bool =
    let x = compare !s1 s2 in
    if x > 0 then true else false

let action1 (count : int ref) (threshold : int ref) : unit = 
    count := !count+1;
    if !count >= !threshold then (alert1 (); count := 0;)

let contains s1 s2 =
    let re = Str.regexp_string s2
    in
        try ignore (Str.search_forward re s1 0); true
        with Not_found -> false
