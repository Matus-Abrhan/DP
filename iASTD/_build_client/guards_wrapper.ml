module G0 : ASTD_plugin_interfaces.Guard_interface = 
struct 
let [@ocaml.warning "-26"] execute_guard (env_acc : ASTD_environment.environment_accessor) : bool = 
  let protocol = env_acc#get_string "protocol" in 
  let ipdst = env_acc#get_string "ipdst" in 
  let portdst = env_acc#get_string "portdst" in 
  let ipsrc = env_acc#get_string "ipsrc" in 
  let msg_cnt = env_acc#get_string "msg_cnt" in 
  let msg_req = env_acc#get_string "msg_req" in 
  let msg_hdr = env_acc#get_string "msg_hdr" in 
  let timestamp = env_acc#get_string "timestamp" in 
  let portsrc = env_acc#get_string "portsrc" in 
  let portdst = env_acc#get_string "portdst" in 
  let ipdst = env_acc#get_string "ipdst" in 
    (ipdst = ipdst) && (portdst = "80") && ((Functions.contains msg_req "GET") || (Functions.contains msg_req "POST") || (Functions.contains msg_req "PUT") || (Functions.contains msg_req "DELETE")) && (Functions.contains msg_hdr "httpbin")
end 
let () = ASTD_plugin_builder.register_guard 0 (module G0) 

