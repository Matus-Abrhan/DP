module type Action_interface = 
  sig 
        val execute_action: ASTD_environment.environment_accessor -> ASTD_environment.environment_accessor 
  end

module type Guard_interface = 
  sig 
        val execute_guard: ASTD_environment.environment_accessor -> bool 
  end