header_type openstate_t {
    fields {
        lookup_state_index : STATE_MAP_SIZE; // state map index
        update_state_index : STATE_MAP_SIZE; // state map index
        key_from_pkt : 64;  // key copied from the packet
        active1: 1;         // First (key,state) couple
        key1 : 64;
        state1 : 32;
        active2: 1;         // Second (key,state) couple
        key2 : 64;
        state2 : 32;
        state : 32;         // state
    }
}

metadata openstate_t openstate;

register reg_active1 {
    width : 1;
    instance_count : STATE_TABLE_SIZE;
}

register reg_key1 {
    width : 64;
    instance_count : STATE_TABLE_SIZE;
}

register reg_state1 {
    width : 32;
    instance_count : STATE_TABLE_SIZE;
}

register reg_active2 {
    width : 1;
    instance_count : STATE_TABLE_SIZE;
}

register reg_key2 {
    width : 64;
    instance_count : STATE_TABLE_SIZE;
}

register reg_state2 {
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

/*
field_list_calculation l_hash_concat {
    input {
        lookup_hash_field;
    }
    algorithm : concat;
    output_width : 128;
}

field_list_calculation u_hash_concat {
    input {
        update_hash_field;
    }
    algorithm : concat;
    output_width : 128;
}
*/

action lookup_state_table() {
    // TODO: We should copy into 'key_from_pkt' metadata a concatenation of fields defined in 'lookup_hash_field',
    // but modify_field() primitive accepts only VAL/FLD/R-REF (and we have a FLDLIST).
    // The fastest fix is to define a custom hash function 'concatenate' to concatenate fields instead of hashing them.
    // (http://lists.p4.org/pipermail/p4-dev_lists.p4.org/2016-June/000351.html)
    // modify_field_with_hash_based_offset(openstate.key_from_pkt, 0, l_hash_concat, 128);
    modify_field(openstate.key_from_pkt,ethernet.dstAddr);

    //store the new hash value used for the lookup
    modify_field_with_hash_based_offset(openstate.lookup_state_index, 0, l_hash, STATE_TABLE_SIZE);
    //Using the new hash, we perform the lookup reading the reg_state[idx]
    register_read(openstate.active1,reg_active1, openstate.lookup_state_index);
    register_read(openstate.key1,reg_key1, openstate.lookup_state_index);
    register_read(openstate.state1,reg_state1, openstate.lookup_state_index);
    register_read(openstate.active2,reg_active2, openstate.lookup_state_index);
    register_read(openstate.key2,reg_key2, openstate.lookup_state_index);
    register_read(openstate.state2,reg_state2, openstate.lookup_state_index);
}

action load_state1_in_state() {
    modify_field(openstate.state,openstate.state1);
}

action load_state2_in_state() {
    modify_field(openstate.state,openstate.state2);
}

action write_state_in_state1() {
    register_write(reg_active1, openstate.update_state_index, 1);
    register_write(reg_key1, openstate.update_state_index, openstate.key_from_pkt);
    register_write(reg_state1, openstate.update_state_index, openstate.state);
}

action write_state_in_state2() {
    register_write(reg_active2, openstate.update_state_index, 1);
    register_write(reg_key2, openstate.update_state_index, openstate.key_from_pkt);
    register_write(reg_state2, openstate.update_state_index, openstate.state);
}

action do_something_for_the_collision() {
    /* To handle a collision we might:
        1. refuse the state update
        2. overwrite the first couple (key,state) (i.e. call 'write_state_in_state1' as default action of 'handle_collision')
        3. overwrite the last couple (key,state) (i.e. call 'write_state_in_state2' as default action of 'handle_collision')
    */
}

action preupdate_state_table() {
    // TODO: see lookup_state_table()
    modify_field(openstate.key_from_pkt,ethernet.srcAddr);

    //store the new hash value used for the update
    modify_field_with_hash_based_offset(openstate.update_state_index, 0, u_hash, STATE_TABLE_SIZE);
    //Using the new hash, we perform the lookup reading the reg_state[idx]
    //NB: WE ARE DOING A LOOKUP EVEN IF WE ARE GOING TO PERFORM AN UPDATE!
    register_read(openstate.active1,reg_active1, openstate.update_state_index);
    register_read(openstate.key1,reg_key1, openstate.update_state_index);
    register_read(openstate.state1,reg_state1, openstate.update_state_index);
    register_read(openstate.active2,reg_active2, openstate.update_state_index);
    register_read(openstate.key2,reg_key2, openstate.update_state_index);
    register_read(openstate.state2,reg_state2, openstate.update_state_index);
}

table state_lookup {
    actions { 
        lookup_state_table; 
    }
}

table load_state1 {
    actions { 
        load_state1_in_state; 
    }
}

table load_state2 {
    actions { 
        load_state2_in_state; 
    }
}

table write_state1 {
    actions { 
        write_state_in_state1; 
    }
}

table write_state2 {
    actions { 
        write_state_in_state2; 
    }
}

table pre_state_update {
    actions {
        preupdate_state_table; 
    }
}

table handle_collision {
    actions {
        do_something_for_the_collision; 
    }
}
