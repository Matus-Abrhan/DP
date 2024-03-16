let contains s1 s2 =
    let re = Str.regexp_string s2
    in
        try ignore (Str.search_forward re s1 0); true
        with Not_found -> false

let action1 () : unit = 
    print_endline "Alert - Bench Test\n"
