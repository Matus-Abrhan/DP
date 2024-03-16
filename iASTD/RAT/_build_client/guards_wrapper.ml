module G0 : ASTD_plugin_interfaces.Guard_interface = 
struct 
let [@ocaml.warning "-26"] execute_guard (env_acc : ASTD_environment.environment_accessor) : bool = 
  let tcpflags1 = env_acc#get_string "tcpflags1" in 
  let ipdst = env_acc#get_string "ipdst" in 
  let portdst = env_acc#get_string "portdst" in 
  let count = env_acc#get_int "count" in 
  let thres = env_acc#get_int "thres" in 
  let recon_end = env_acc#get_int "recon_end" in 
    tcpflags1 = "S" && recon_end = 0
end 
let () = ASTD_plugin_builder.register_guard 0 (module G0) 

module G1 : ASTD_plugin_interfaces.Guard_interface = 
struct 
let [@ocaml.warning "-26"] execute_guard (env_acc : ASTD_environment.environment_accessor) : bool = 
  let tcpflags2 = env_acc#get_string "tcpflags2" in 
  let ipdst = env_acc#get_string "ipdst" in 
  let portdst = env_acc#get_string "portdst" in 
  let count = env_acc#get_int "count" in 
  let thres = env_acc#get_int "thres" in 
  let recon_end = env_acc#get_int "recon_end" in 
    tcpflags2 = "RA"
end 
let () = ASTD_plugin_builder.register_guard 1 (module G1) 

module G3 : ASTD_plugin_interfaces.Guard_interface = 
struct 
let [@ocaml.warning "-26"] execute_guard (env_acc : ASTD_environment.environment_accessor) : bool = 
  let tcpflags1 = env_acc#get_string "tcpflags1" in 
  let ipsrc = env_acc#get_string "ipsrc" in 
  let ipdst = env_acc#get_string "ipdst" in 
    tcpflags1 = "S"
end 
let () = ASTD_plugin_builder.register_guard 3 (module G3) 

module G4 : ASTD_plugin_interfaces.Guard_interface = 
struct 
let [@ocaml.warning "-26"] execute_guard (env_acc : ASTD_environment.environment_accessor) : bool = 
  let tcpflags2 = env_acc#get_string "tcpflags2" in 
  let payload = env_acc#get_string "payload" in 
  let ipsrc = env_acc#get_string "ipsrc" in 
  let ipdst = env_acc#get_string "ipdst" in 
    (Functions.contains payload "stdapi") && (tcpflags2 = "SA")
end 
let () = ASTD_plugin_builder.register_guard 4 (module G4) 

module G6 : ASTD_plugin_interfaces.Guard_interface = 
struct 
let [@ocaml.warning "-26"] execute_guard (env_acc : ASTD_environment.environment_accessor) : bool = 
  let thres = env_acc#get_int "thres" in 
  let recon_end = env_acc#get_int "recon_end" in 
    recon_end = 1
end 
let () = ASTD_plugin_builder.register_guard 6 (module G6) 

