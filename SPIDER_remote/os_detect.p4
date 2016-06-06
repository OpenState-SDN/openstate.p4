metadata openstate_t detect;

register reg_state_det {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_hard_to_det {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_hard_rb_det {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_idle_to_det {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_idle_rb_det {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_hard_to_expiration_det {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_idle_to_expiration_det {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

field_list_calculation l_hash_det {
    input {
        lookup_hash_field_det;
    }
    algorithm : crc32;
    output_width : 32;
}

field_list_calculation u_hash_det {
    input {
        update_hash_field_det;
    }
    algorithm : crc32;
    output_width : 32;
}

action lookup_state_table_det() {
    //store the new hash value used for the lookup
    modify_field_with_hash_based_offset(detect.lookup_state_index, 0, l_hash_det, STATE_TABLE_SIZE);
    //Using the new hash, we perform the lookup reading the reg_state_det[idx]
    register_read(detect.state,reg_state_det, detect.lookup_state_index);
    //Store the idle_to[idx] value in the metadata
    register_read(detect.idle_to, reg_idle_to_det, detect.lookup_state_index);
    //Store the idle_rb[idx] value in the metadata
    register_read(detect.idle_rb, reg_idle_rb_det, detect.lookup_state_index);
    //Store the last idle timeout expiration time in the metadata
    register_read(detect.idle_to_expiration, reg_idle_to_expiration_det, detect.lookup_state_index);
    //Store the hard_to[idx] value in the metadata
    register_read(detect.hard_to, reg_hard_to_det, detect.lookup_state_index);
    //Store the hard_rb[idx] value in the metadata
    register_read(detect.hard_rb, reg_hard_rb_det, detect.lookup_state_index);
    //Store the hard timeout expiration time in the metadata
    register_read(detect.hard_to_expiration, reg_hard_to_expiration_det, detect.lookup_state_index);
    //Calculation of the new idle_to_expiration value
    modify_field(detect.new_idle_to_expiration, intrinsic_metadata.ingress_global_timestamp);
    add_to_field(detect.new_idle_to_expiration, detect.idle_to);
    register_write(reg_idle_to_expiration_det, detect.lookup_state_index, detect.new_idle_to_expiration); 
}

action update_state_table_det(state, idle_to, idle_rb, hard_to, hard_rb) {
    //store the new hash value used for the update
    modify_field_with_hash_based_offset(detect.update_state_index, 0, u_hash_det, STATE_TABLE_SIZE);
    //Using the new hash, we perform the update of the register reg_state_det[idx]
    register_write(reg_state_det, detect.update_state_index, state);
    //Store in the register the new hard timeout  
    register_write(reg_idle_to_det, detect.update_state_index, idle_to);
    //Store in the register the new idle rollback
    register_write(reg_idle_rb_det, detect.update_state_index, idle_rb);
    //Store in the register the new hard timeout
    register_write(reg_hard_to_det, detect.update_state_index, hard_to);
    //Store in the register the new hard rollback
    register_write(reg_hard_rb_det, detect.update_state_index, hard_rb);
    //The expiration time is the sum between the idle timeout and when the timeout is set up
    modify_field(detect.new_idle_to_expiration, intrinsic_metadata.ingress_global_timestamp);
    add_to_field(detect.new_idle_to_expiration, idle_to);
    register_write(reg_idle_to_expiration_det, detect.update_state_index, detect.new_idle_to_expiration); 
    //The expiration time is the sum between the hard timeout and when the timeout is set up
    modify_field(detect.hard_to_expiration, intrinsic_metadata.ingress_global_timestamp);
    add_to_field(detect.hard_to_expiration, hard_to);
    register_write(reg_hard_to_expiration_det, detect.update_state_index, detect.hard_to_expiration);
}

action set_hard_rb_state_det(){
    //After the timeout expiration, the state is updated with the rollback state and all the registers are reset to 0 (we do not have timeouts associated to rollback states)
    modify_field(detect.state, detect.hard_rb);
    modify_field_with_hash_based_offset(detect.update_state_index, 0, u_hash_det, STATE_TABLE_SIZE);
    register_write(reg_state_det, detect.update_state_index, detect.state);
    register_write(reg_hard_to_expiration_det, detect.update_state_index, 0);
    register_write(reg_hard_rb_det, detect.update_state_index, 0);
    register_write(reg_hard_to_det, detect.update_state_index, 0);
    register_write(reg_idle_to_expiration_det, detect.update_state_index, 0);
    register_write(reg_idle_to_det, detect.update_state_index, 0);
    register_write(reg_idle_rb_det, detect.update_state_index, 0);
}

action set_idle_rb_state_det(){
    //After the timeout expiration, the state is updated with the rollback state and all the registers are reset to 0 (we do not have timeouts associated to rollback states)
    modify_field(detect.state, detect.idle_rb);
    modify_field_with_hash_based_offset(detect.update_state_index, 0, u_hash_det, STATE_TABLE_SIZE);
    register_write(reg_state_det, detect.update_state_index, detect.state);
    register_write(reg_hard_to_expiration_det, detect.update_state_index, 0);
    register_write(reg_hard_rb_det, detect.update_state_index, 0);
    register_write(reg_hard_to_det, detect.update_state_index, 0);
    register_write(reg_idle_to_expiration_det, detect.update_state_index, 0);
    register_write(reg_idle_to_det, detect.update_state_index, 0);
    register_write(reg_idle_rb_det, detect.update_state_index, 0);
}

table state_lookup_det {
    actions { 
        lookup_state_table_det;
        _nop;
    }
}

table hard_to_expired_det {
    actions {
        set_hard_rb_state_det; 
        _nop;
    }
}

table idle_to_expired_det {
    actions {
        set_idle_rb_state_det; 
        _nop;
    }
}

table state_update_det {
    actions {
        update_state_table_det;
        _nop;
    }
}