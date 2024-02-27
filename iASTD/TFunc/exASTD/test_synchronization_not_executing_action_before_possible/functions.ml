
let global_var = ref 0

let is_side_effect_applied () =
  !global_var <> 0

let apply_side_effect () =
  global_var := 1