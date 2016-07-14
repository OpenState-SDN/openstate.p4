#include "includes/parser.p4"
#include "includes/headers.p4"
#include "includes/intrinsic.p4"

#define STATE_MAP_SIZE 1    // 13 bits = 8192 state entries
#define STATE_TABLE_SIZE 2
#include "../../openstate.p4"

/*
How to test collisions handling?

Set STATE_MAP_SIZE to 1 and STATE_TABLE_SIZE to 2 to obtain a 2x2 state table.
Start the switch
~/openstate.p4.chaining/mac_learning$ rm mac_learning.json ; ./run_demo.sh
Start the log
$ cd ~/bmv2/tools/;sudo ./nanomsg_client.py
Finally
mininet> pingall

If the hash function is perfectly uniform, state table will be filled without collisions, otherwise there will be at least 1 collision.

[...]
type: TABLE_MISS, switch_id: 0, cxt_id : 0, sig: 2089485495442116685, id: 11, copy_id: 0, table_id: 6 (handle_collision)
type: ACTION_EXECUTE, switch_id: 0, cxt_id : 0, sig: 2089485495442116685, id: 11, copy_id: 0, action_id: 5 (do_something_for_the_collision)
[...]
*/

field_list lookup_hash_field {
    ethernet.dstAddr;
}

field_list update_hash_field {
    ethernet.srcAddr;
}

action unicast() {
    // <<Actions across different tables are assumed to execute sequentially, where the sequence is determined by the control flow.
    // [...] The body of a compound action is also assumed to execute sequentially.>>
    // Without this assumption we should create a separated 'next_state' metadata
    modify_field(standard_metadata.egress_spec, openstate.state);
    modify_field(openstate.state,standard_metadata.ingress_port);
}

action broadcast_and_learn() {
    modify_field(intrinsic_metadata.mcast_grp, standard_metadata.ingress_port);
    modify_field(openstate.state,standard_metadata.ingress_port);
}

action broadcast() {
    modify_field(intrinsic_metadata.mcast_grp, standard_metadata.ingress_port);
}

/*********** TABLES *************/

table forward {
    reads {
        openstate.state : exact;
    }
    actions {
        unicast; 
        broadcast_and_learn;
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

        if ((openstate.key_from_pkt == openstate.key1) and (openstate.active1 == 1)){
            apply(load_state1);
        } else if ((openstate.key_from_pkt == openstate.key2) and (openstate.active2 == 1)){
            apply(load_state2);
        } /* else {
            We should return default state, so we can just keep the metadata 'state' to its value 0
        } */
        ///////////////////// User defined code START ///////////////////////////////////////////////

        apply(forward);

        ///////////////////// User defined code END// ///////////////////////////////////////////////
        apply(pre_state_update);

        if ((openstate.active1 == 0) or ((openstate.key_from_pkt == openstate.key1) and (openstate.active1 == 1))){
            apply(write_state1);
        } else if ((openstate.active2 == 0) or ((openstate.key_from_pkt == openstate.key2) and (openstate.active2 == 1))){
            apply(write_state2);
        } else {
            apply(handle_collision);
        } 
    }
    if(valid(ethernet) and ethernet.etherType == ETHERTYPE_ARP)
    {
        apply(arp_manager);
    }
}