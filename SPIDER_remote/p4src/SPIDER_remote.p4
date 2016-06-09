#include "includes/headers.p4"
#include "includes/intrinsic.p4"
#include "includes/parser.p4"

#define STATE_MAP_SIZE 13    // 13 bits = 8192 state entries
#define STATE_TABLE_SIZE 8192
#include "../os_metadata.p4"
#include "../os_detect.p4"
#include "../os_redirect.p4"


/*
REDIRECT NODE -> per-flow states
DETECT NODE   -> per-port states

REDIRECT NODE
For each flow [eth.src,eth.dest] there's an associated state which indicates the availability or not of the primary path
DETECT NODE
Sometimes the state is updated for the input port, some other for the output port.
In FRIP with OpenState we used lookup-scope=update-scope=METADATA.
We can apply the same trick here: using a custom metadata as scope and setting it to inport/outport value before updating the state
*/

/*lookup/update scope for Detect FSM*/
header_type scope_t {
    fields {
        port : 9;
    }
}

metadata scope_t scope;

field_list lookup_hash_field_det {
        scope.port;
}

field_list update_hash_field_det {
        scope.port;
}

/*lookup/update scope for Redirect FSM*/

field_list lookup_hash_field_red {
        ethernet.dstAddr;
        ethernet.srcAddr;
}

field_list update_hash_field_red {
        ethernet.dstAddr;
        ethernet.srcAddr;
}


field_list clone_fields {
    standard_metadata;
}

action _nop() {   
}

action broadcast() {
    //pkt is sent to the i-th multicast group containing all the ports except the i-th
    modify_field(intrinsic_metadata.mcast_grp, standard_metadata.ingress_port);
}

action unicast(port){
    //pkt is forwarded to 'port'
    modify_field(standard_metadata.egress_spec, port);
}

action HB_req(port){
    //pkt is tagged 20 (HB_req) and forwarded to 'port'
    modify_field(vlan_tag.vid, 20);
    modify_field(standard_metadata.egress_spec, port);
}

action primary_and_HB_reply(port){
    //pkt is cloned to egress pipeline (we can match on instance_type=1) and forwarded to 2
    /*AGGIUNGERE PARAMETRO ALL'AZIONE*/
    clone_ingress_pkt_to_egress(2,clone_fields);
    //the original pkt is forwarded to port 'port' (primary path)
    modify_field(vlan_tag.vid, 16);
    modify_field(standard_metadata.egress_spec, port);
}

action HB_reply(){
    //actions for cloned packet
    //NB: output port cannot be changed in the egress tables => output port is selected by means of mirror_id
    modify_field(vlan_tag.vid, 21);
}

action fwd_back(){
    //detect_node: in case of failure pkt is tagged 17 and forwarded back
    modify_field(vlan_tag.vid, 17);
    modify_field(standard_metadata.egress_spec, standard_metadata.ingress_port);
}

action backup(port){
    //pkt is tagged 17 (fault) and forwarded to 'port'
    modify_field(vlan_tag.vid, 17);
    modify_field(standard_metadata.egress_spec, port);
}

action backup_and_probe(port){
    //pkt is cloned to egress pipeline (we can match on instance_type=1) and forwarded to port 2
    clone_ingress_pkt_to_egress(2,clone_fields);
    //the original pkt is tagged 17 (fault) and forwarded to 'port' (backup path)
    modify_field(vlan_tag.vid, 17);
    modify_field(standard_metadata.egress_spec, port);
}

action send_probe(){
    //actions for cloned packet
    //NB: output port cannot be changed in the egress tables => output port is selected by means of mirror_id
    modify_field(vlan_tag.vid, 22);
}

action reply_probe(){
    //pkt is forwarded back to the inport (node after detect)
    modify_field(standard_metadata.egress_spec, standard_metadata.ingress_port);
}

action write_metadata_inport(){
    //ingress port is stored in metadata scope
    modify_field(scope.port, standard_metadata.ingress_port);
}

action write_metadata_outport(port){
    //outport port is stored in metadata scope
    modify_field(scope.port, port);
}

action reset_tag_and_primary(port){
    //pkt is tagged 16 and forwarded to 'port' (last detour node/edge node)
    modify_field(vlan_tag.vid, 16);
    modify_field(standard_metadata.egress_spec, port);
}



/********** Control ingress tables **********/

table arp_manager {
    actions { 
        broadcast;
    }
}

/************** Redirect node ***************/
//forward table used by redirect node
table forward_red {
    reads{
        redirect.state: ternary;
        standard_metadata.ingress_port: exact;
        vlan_tag.vid: exact;
    }
    actions {
        unicast;
        backup;
        backup_and_probe;
        reset_tag_and_primary;
        _nop;
    }
}

//redirect node's state table update
table update_flow_state {
    reads{
        redirect.state: exact;
        standard_metadata.ingress_port: exact;
        vlan_tag.vid: exact;
    }
    actions{
        update_state_table_red;
        _nop;
    }
}

/************** Detect node ***************/

/*The input port is stored in order to be used as update scope*/
table inport_write_metadata{
    actions {
        write_metadata_inport;
        _nop;
    }
}

/*If some traffic is received by a specific input port, the state of that port must be "up" */
table update_inport_state{
    actions{
        update_state_table_det;
        _nop;
    }
}

/* Depending on the destination, the output port is stored in order to be used as lookup/update scope*/
table output_write_metadata{
    reads{
        ipv4.srcAddr: exact;
        ipv4.dstAddr: exact;
    }
    actions{
        write_metadata_outport;
        _nop;
    }
}

//forward table used by detect/N.A.D/repeater nodes
table forward {
    reads{
        detect.state: ternary;
        standard_metadata.ingress_port: exact;
        vlan_tag.vid: exact;
    }
    actions {
        HB_req;
        unicast;
        primary_and_HB_reply;
        reply_probe;
        fwd_back;
        reset_tag_and_primary;
        _nop;
    }
}

//detect node's state table update
table update_outport_state {
    reads{
        detect.state: exact;
        standard_metadata.ingress_port: exact;
        vlan_tag.vid: exact;
    }
    actions{
        update_state_table_det;
        _nop;
    }
}

/********** Control egress table **********/

table clone_table_egress {
    reads {
        standard_metadata.instance_type:exact;
    }
    actions {
        send_probe;
        HB_reply;
        _nop;
    }
}



control ingress {
    if(valid(ethernet) and ethernet.etherType == ETHERTYPE_VLAN)
    { 
        if(valid(vlan_tag))
        {
            if(vlan_tag.etherType == ETHERTYPE_ARP)
            {
                apply(arp_manager);
            }
            else
            {
                //redirect node
                apply(state_lookup_red);
                //check if the hard timeout is set. If yes, check if it will expire before the idle_to (if present)
                if ((redirect.hard_to > 0 and redirect.idle_to == 0) or (redirect.hard_to > 0 and redirect.idle_to > 0 and redirect.hard_to_expiration < redirect.idle_to_expiration))
                {    
                    //check if the current packet timestamp is greater than the timeout expiration time
                    if(intrinsic_metadata.ingress_global_timestamp >= redirect.hard_to_expiration)
                    {      
                        apply(hard_to_expired_red);              
                    }
                }
                //check if the idle timeout is set. If yes, check if it will expire before the hard (if present)
                if ((redirect.idle_to > 0 and redirect.hard_to == 0) or (redirect.idle_to > 0 and redirect.hard_to > 0 and redirect.idle_to_expiration < redirect.hard_to_expiration))
                {
                    //check if the current packet timestamp is greater than the timeout expiration time
                    if(intrinsic_metadata.ingress_global_timestamp >= redirect.idle_to_expiration)
                    {      
                        apply(idle_to_expired_red);              
                    }
                }
                apply(forward_red);
                apply(update_flow_state);

                //detect node
                apply(inport_write_metadata);
                apply(update_inport_state);
                apply(output_write_metadata);
                apply(state_lookup_det);
                //check if the hard timeout is set. If yes, check if it will expire before the idle_to (if present)
                if ((detect.hard_to > 0 and detect.idle_to == 0) or (detect.hard_to > 0 and detect.idle_to > 0 and detect.hard_to_expiration < detect.idle_to_expiration))
                {    
                    //check if the current packet timestamp is greater than the timeout expiration time
                    if(intrinsic_metadata.ingress_global_timestamp >= detect.hard_to_expiration)
                    {      
                        apply(hard_to_expired_det);              
                    }
                }
                //check if the idle timeout is set. If yes, check if it will expire before the hard (if present)
                if ((detect.idle_to > 0 and detect.hard_to == 0) or (detect.idle_to > 0 and detect.hard_to > 0 and detect.idle_to_expiration < detect.hard_to_expiration))
                {
                    //check if the current packet timestamp is greater than the timeout expiration time
                    if(intrinsic_metadata.ingress_global_timestamp >= detect.idle_to_expiration)
                    {      
                        apply(idle_to_expired_det);              
                    }
                }
                apply(forward);
                apply(update_outport_state);

            }
        } 
    }
}

control egress {
    if(valid(ethernet) and ethernet.etherType == ETHERTYPE_VLAN)
    { 
        if(valid(vlan_tag) and  vlan_tag.etherType != ETHERTYPE_ARP)
        {
            apply(clone_table_egress);
        }
    }
}
