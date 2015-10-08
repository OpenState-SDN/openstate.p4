#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/intrinsic.p4"

#define STATE_MAP_SIZE 13    // 13 bits = 8192 state entries
#define STATE_TABLE_SIZE 8192
#include "../../openstate.p4"

field_list lookup_hash_field {
        ipv4.srcAddr;
}

field_list update_hash_field {
        ipv4.srcAddr;
}

action forward(port) {
    modify_field(standard_metadata.egress_spec, port);  
}

action broadcast() {
    modify_field(intrinsic_metadata.mcast_grp, standard_metadata.ingress_port);
}

action _drop() {
    drop();
}

action _nop(){
}

action _reset() {
    //all the registers are reset to 0
    modify_field_with_hash_based_offset(openstate.update_state_index, 0, u_hash, STATE_TABLE_SIZE);
    register_write(reg_state, openstate.update_state_index, openstate.state);
    register_write(reg_hard_to_expiration, openstate.update_state_index, 0);
    register_write(reg_hard_rb, openstate.update_state_index, 0);
    register_write(reg_hard_to, openstate.update_state_index, 0);
    register_write(reg_idle_to_expiration, openstate.update_state_index, 0);
    register_write(reg_idle_to, openstate.update_state_index, 0);
    register_write(reg_idle_rb, openstate.update_state_index, 0);
}


/*********** TABLES *************/


table knock_sequence {
    reads {
        udp.dstPort: exact;
        openstate.state : exact;
    }
    actions {
        update_state_table; 
        _reset;
        _nop;
    }
}

table output {
    reads {
        udp.dstPort: exact;
        openstate.state : exact;     
    }
    actions {
        forward; 
        _drop;
    }
}

table arp_manager {
    actions { 
        broadcast;
    }
}

/***********************************/

control ingress {
    if(valid(ethernet) and ethernet.etherType == ETHERTYPE_IPV4)
    {
        if(valid(ipv4) and ipv4.protocol == IP_PROTOCOLS_UDP)
        {
            apply(state_lookup);
            //check if the hard timeout is set. If yes, check if it will expire before the idle_to (if present)
            if ((openstate.hard_to > 0 and openstate.idle_to == 0) or (openstate.hard_to > 0 and openstate.idle_to > 0 and openstate.hard_to_expiration < openstate.idle_to_expiration))
            {    
                //check if the current packet timestamp is greater than the timeout expiration time
                if(intrinsic_metadata.ingress_global_timestamp > openstate.hard_to_expiration)
                {      
                    apply(hard_to_expired);              
                }
            }
            //check if the idle timeout is set. If yes, check if it will expire before the hard (if present)
            if ((openstate.idle_to > 0 and openstate.hard_to == 0) or (openstate.idle_to > 0 and openstate.hard_to > 0 and openstate.idle_to_expiration < openstate.hard_to_expiration))
            {
                //check if the current packet timestamp is greater than the timeout expiration time
                if(intrinsic_metadata.ingress_global_timestamp >= openstate.idle_to_expiration)
                {      
                    apply(idle_to_expired);              
                }
            }
            apply(output); 
            apply(knock_sequence);
        }
    }
    if(valid(ethernet) and ethernet.etherType == ETHERTYPE_ARP)
    {
        apply(arp_manager);
    }
}