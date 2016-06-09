header_type openstate_t {
    fields {
        lookup_state_index : STATE_MAP_SIZE; // state map index
        update_state_index : STATE_MAP_SIZE; // state map index
        state : 32;                          // state        
        hard_to: 32;                         // hard timeout
        hard_rb: 32;                         // hard rollback
        idle_to: 32;                         // idle timeout
        idle_rb: 32;                         // idle rollback
        hard_to_expiration : 32;             // it is the sum of hard_to and the timestamp of when it has been set
        idle_to_expiration : 32;             // last reference time
        new_idle_to_expiration : 32;         // new reference time
    }
}

metadata openstate_t openstate;

register reg_state {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_hard_to {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_hard_rb {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_idle_to {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_idle_rb {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_hard_to_expiration {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_idle_to_expiration {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

field_list_calculation l_hash {
    input {
        lookup_hash_field;
    }
    algorithm : crc32;
    output_width : 32;
}

field_list_calculation u_hash {
    input {
        update_hash_field;
    }
    algorithm : crc32;
    output_width : 32;
}

action lookup_state_table() {
    //store the new hash value used for the lookup
    modify_field_with_hash_based_offset(openstate.lookup_state_index, 0, l_hash, STATE_TABLE_SIZE);
    //Using the new hash, we perform the lookup reading the reg_state[idx]
    register_read(openstate.state,reg_state, openstate.lookup_state_index);
    //Store the idle_to[idx] value in the metadata
    register_read(openstate.idle_to, reg_idle_to, openstate.lookup_state_index);
    //Store the idle_rb[idx] value in the metadata
    register_read(openstate.idle_rb, reg_idle_rb, openstate.lookup_state_index);
    //Store the last idle timeout expiration time in the metadata
    register_read(openstate.idle_to_expiration, reg_idle_to_expiration, openstate.lookup_state_index);
    //Store the hard_to[idx] value in the metadata
    register_read(openstate.hard_to, reg_hard_to, openstate.lookup_state_index);
    //Store the hard_rb[idx] value in the metadata
    register_read(openstate.hard_rb, reg_hard_rb, openstate.lookup_state_index);
    //Store the hard timeout expiration time in the metadata
    register_read(openstate.hard_to_expiration, reg_hard_to_expiration, openstate.lookup_state_index);
    //Calculation of the new idle_to_expiration value
    modify_field(openstate.new_idle_to_expiration, intrinsic_metadata.ingress_global_timestamp);
    add_to_field(openstate.new_idle_to_expiration, openstate.idle_to);
    register_write(reg_idle_to_expiration, openstate.lookup_state_index, openstate.new_idle_to_expiration); 
}

action update_state_table(state, idle_to, idle_rb, hard_to, hard_rb) {
    //store the new hash value used for the update
    modify_field_with_hash_based_offset(openstate.update_state_index, 0, u_hash, STATE_TABLE_SIZE);
    //Using the new hash, we perform the update of the register reg_state[idx]
    register_write(reg_state, openstate.update_state_index, state);
    //Store in the register the new hard timeout  
    register_write(reg_idle_to, openstate.update_state_index, idle_to);
    //Store in the register the new idle rollback
    register_write(reg_idle_rb, openstate.update_state_index, idle_rb);
    //Store in the register the new hard timeout
    register_write(reg_hard_to, openstate.update_state_index, hard_to);
    //Store in the register the new hard rollback
    register_write(reg_hard_rb, openstate.update_state_index, hard_rb);
    //The expiration time is the sum between the idle timeout and when the timeout is set up
    modify_field(openstate.new_idle_to_expiration, intrinsic_metadata.ingress_global_timestamp);
    add_to_field(openstate.new_idle_to_expiration, idle_to);
    register_write(reg_idle_to_expiration, openstate.update_state_index, openstate.new_idle_to_expiration); 
    //The expiration time is the sum between the hard timeout and when the timeout is set up
    modify_field(openstate.hard_to_expiration, intrinsic_metadata.ingress_global_timestamp);
    add_to_field(openstate.hard_to_expiration, hard_to);
    register_write(reg_hard_to_expiration, openstate.update_state_index, openstate.hard_to_expiration);
}

action set_hard_rb_state(){
    //After the timeout expiration, the state is updated with the rollback state and all the registers are reset to 0 (we do not have timeouts associated to rollback states)
    modify_field(openstate.state, openstate.hard_rb);
    modify_field_with_hash_based_offset(openstate.update_state_index, 0, u_hash, STATE_TABLE_SIZE);
    register_write(reg_state, openstate.update_state_index, openstate.state);
    register_write(reg_hard_to_expiration, openstate.update_state_index, 0);
    register_write(reg_hard_rb, openstate.update_state_index, 0);
    register_write(reg_hard_to, openstate.update_state_index, 0);
    register_write(reg_idle_to_expiration, openstate.update_state_index, 0);
    register_write(reg_idle_to, openstate.update_state_index, 0);
    register_write(reg_idle_rb, openstate.update_state_index, 0);
}

action set_idle_rb_state(){
    //After the timeout expiration, the state is updated with the rollback state and all the registers are reset to 0 (we do not have timeouts associated to rollback states)
    modify_field(openstate.state, openstate.idle_rb);
    modify_field_with_hash_based_offset(openstate.update_state_index, 0, u_hash, STATE_TABLE_SIZE);
    register_write(reg_state, openstate.update_state_index, openstate.state);
    register_write(reg_hard_to_expiration, openstate.update_state_index, 0);
    register_write(reg_hard_rb, openstate.update_state_index, 0);
    register_write(reg_hard_to, openstate.update_state_index, 0);
    register_write(reg_idle_to_expiration, openstate.update_state_index, 0);
    register_write(reg_idle_to, openstate.update_state_index, 0);
    register_write(reg_idle_rb, openstate.update_state_index, 0);
}

action __nop() {   
}

table state_lookup {
    actions { 
        lookup_state_table; 
        __nop;
    }
}

table hard_to_expired {
    actions {
        set_hard_rb_state; 
        __nop;
    }
}

table idle_to_expired {
    actions {
        set_idle_rb_state; 
        __nop;
    }
}

table state_update {
    actions {
        update_state_table; 
        __nop;
    }
}
