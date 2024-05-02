let contains keyword str =
    let re = Str.regexp_string str
    in
        try ignore (Str.search_forward re keyword 0); true
        with Not_found -> false

let count_occurances keyword arr =
  let rec count_helper count = function
    | [] -> count
    | hd::tl ->
        if contains keyword hd then
          count_helper (count + 1) tl
        else
          count_helper count tl
  in
  count_helper 0 arr


let action1 () : unit = 
    print_endline "T1083 ALERT\n"
