metadata openstate_t redirect;

register reg_state_red {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_hard_to_red {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_hard_rb_red {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_idle_to_red {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_idle_rb_red {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_hard_to_expiration_red {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_idle_to_expiration_red {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

field_list_calculation l_hash_red {
    input {
        lookup_hash_field_red;
    }
    algorithm : crc32;
    output_width : 32;
}

field_list_calculation u_hash_red {
    input {
        update_hash_field_red;
    }
    algorithm : crc32;
    output_width : 32;
}

action lookup_state_table_red() {
    //store the new hash value used for the lookup
    modify_field_with_hash_based_offset(redirect.lookup_state_index, 0, l_hash_red, STATE_TABLE_SIZE);
    //Using the new hash, we perform the lookup reading the reg_state[idx]
    register_read(redirect.state, reg_state_red, redirect.lookup_state_index);
    //Store the idle_to[idx] value in the metadata
    register_read(redirect.idle_to, reg_idle_to_red, redirect.lookup_state_index);
    //Store the idle_rb[idx] value in the metadata
    register_read(redirect.idle_rb, reg_idle_rb_red, redirect.lookup_state_index);
    //Store the last idle timeout expiration time in the metadata
    register_read(redirect.idle_to_expiration, reg_idle_to_expiration_red, redirect.lookup_state_index);
    //Store the hard_to[idx] value in the metadata
    register_read(redirect.hard_to, reg_hard_to_red, redirect.lookup_state_index);
    //Store the hard_rb[idx] value in the metadata
    register_read(redirect.hard_rb, reg_hard_rb_red, redirect.lookup_state_index);
    //Store the hard timeout expiration time in the metadata
    register_read(redirect.hard_to_expiration, reg_hard_to_expiration_red, redirect.lookup_state_index);
    //Calculation of the new idle_to_expiration value
    modify_field(redirect.new_idle_to_expiration, intrinsic_metadata.ingress_global_timestamp);
    add_to_field(redirect.new_idle_to_expiration, redirect.idle_to);
    register_write(reg_idle_to_expiration_red, redirect.lookup_state_index, redirect.new_idle_to_expiration); 
}

action update_state_table_red(state, idle_to, idle_rb, hard_to, hard_rb) {
    //store the new hash value used for the update
    modify_field_with_hash_based_offset(redirect.update_state_index, 0, u_hash_red, STATE_TABLE_SIZE);
    //Using the new hash, we perform the update of the register reg_state[idx]
    register_write(reg_state_red, redirect.update_state_index, state);
    //Store in the register the new hard timeout  
    register_write(reg_idle_to_red, redirect.update_state_index, idle_to);
    //Store in the register the new idle rollback
    register_write(reg_idle_rb_red, redirect.update_state_index, idle_rb);
    //Store in the register the new hard timeout
    register_write(reg_hard_to_red, redirect.update_state_index, hard_to);
    //Store in the register the new hard rollback
    register_write(reg_hard_rb_red, redirect.update_state_index, hard_rb);
    //The expiration time is the sum between the idle timeout and when the timeout is set up
    modify_field(redirect.new_idle_to_expiration, intrinsic_metadata.ingress_global_timestamp);
    add_to_field(redirect.new_idle_to_expiration, idle_to);
    register_write(reg_idle_to_expiration_red, redirect.update_state_index, redirect.new_idle_to_expiration); 
    //The expiration time is the sum between the hard timeout and when the timeout is set up
    modify_field(redirect.hard_to_expiration, intrinsic_metadata.ingress_global_timestamp);
    add_to_field(redirect.hard_to_expiration, hard_to);
    register_write(reg_hard_to_expiration_red, redirect.update_state_index, redirect.hard_to_expiration);
}

action set_hard_rb_state_red(){
    //After the timeout expiration, the state is updated with the rollback state and all the registers are reset to 0 (we do not have timeouts associated to rollback states)
    modify_field(redirect.state, redirect.hard_rb);
    modify_field_with_hash_based_offset(redirect.update_state_index, 0, u_hash_red, STATE_TABLE_SIZE);
    register_write(reg_state_red, redirect.update_state_index, redirect.state);
    register_write(reg_hard_to_expiration_red, redirect.update_state_index, 0);
    register_write(reg_hard_rb_red, redirect.update_state_index, 0);
    register_write(reg_hard_to_red, redirect.update_state_index, 0);
    register_write(reg_idle_to_expiration_red, redirect.update_state_index, 0);
    register_write(reg_idle_to_red, redirect.update_state_index, 0);
    register_write(reg_idle_rb_red, redirect.update_state_index, 0);
}

action set_idle_rb_state_red(){
    //After the timeout expiration, the state is updated with the rollback state and all the registers are reset to 0 (we do not have timeouts associated to rollback states)
    modify_field(redirect.state, redirect.idle_rb);
    modify_field_with_hash_based_offset(redirect.update_state_index, 0, u_hash_red, STATE_TABLE_SIZE);
    register_write(reg_state_red, redirect.update_state_index, redirect.state);
    register_write(reg_hard_to_expiration_red, redirect.update_state_index, 0);
    register_write(reg_hard_rb_red, redirect.update_state_index, 0);
    register_write(reg_hard_to_red, redirect.update_state_index, 0);
    register_write(reg_idle_to_expiration_red, redirect.update_state_index, 0);
    register_write(reg_idle_to_red, redirect.update_state_index, 0);
    register_write(reg_idle_rb_red, redirect.update_state_index, 0);
}

table state_lookup_red {
    actions { 
        lookup_state_table_red;
        _nop; 
    }
}

table hard_to_expired_red {
    actions {
        set_hard_rb_state_red;
        _nop;
    }
}

table idle_to_expired_red {
    actions {
        set_idle_rb_state_red; 
        _nop;
    }
}

table state_update_red {
    actions {
        update_state_table_red;
        _nop;
    }
}