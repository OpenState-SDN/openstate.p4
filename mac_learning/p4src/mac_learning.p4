#include "includes/parser.p4"
#include "includes/headers.p4"
#include "includes/intrinsic.p4"

#define STATE_MAP_SIZE 13    // 13 bits = 8192 state entries
#define STATE_TABLE_SIZE 8192
#include "../../openstate.p4"

field_list lookup_hash_field {
    ethernet.dstAddr;
}

field_list update_hash_field {
    ethernet.srcAddr;
}

action unicast() {
    modify_field(standard_metadata.egress_spec, openstate.state);
}

action broadcast() {
    modify_field(intrinsic_metadata.mcast_grp, 1);
}

/*********** TABLES *************/

table forward {
    reads {
        openstate.state : exact;
    }
    actions {
        unicast; 
        broadcast;
    }
}

table update_state {
    reads{
        standard_metadata.ingress_port: exact;
    }
    actions {
        update_state_table;
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
        apply(state_lookup);
        //check if the hard timeout is set. If yes, check if it will expire before the idle_to (if present)
        if ((openstate.hard_to > 0 and openstate.idle_to == 0) or (openstate.hard_to > 0 and openstate.idle_to > 0 and openstate.hard_to_expiration < openstate.idle_to_expiration))
        {    
            //check if the current packet timestamp is greater than the timeout expiration time
            if(intrinsic_metadata.ingress_global_timestamp >= openstate.hard_to_expiration)
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
        apply(forward);
        apply(update_state);
    }
    if(valid(ethernet) and ethernet.etherType == ETHERTYPE_ARP)
    {
        apply(arp_manager);
    }
}