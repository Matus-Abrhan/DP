module M1 : ASTD_plugin_interfaces.Action_interface = 
struct 
let execute_action (env_acc : ASTD_environment.environment_accessor) : ASTD_environment.environment_accessor = 
    ignore(Functions.action1 ());
    env_acc 
end 
let () = ASTD_plugin_builder.register_action 1 (module M1) 

