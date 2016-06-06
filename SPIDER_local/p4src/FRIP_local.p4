#include "includes/headers.p4"
#include "includes/intrinsic.p4"
#include "includes/parser.p4"

#define STATE_MAP_SIZE 13    // 13 bits = 8192 state entries
#define STATE_TABLE_SIZE 8192
#include "../../openstate.p4"


/*
Instead of considering states for 'flows', here we need to associate a FSM to a 'port'.
Sometimes the state is updated for the input port, some other for the output port.
In FRIP with OpenState we used lookup-scope=update-scope=METADATA.
We can apply the same trick here: using a custom metadata as scope and seting it to inport/outport value before updating the state

To sniff vlan packets -> tcpdump -n -i {switch}-{interface} -Uw - | tcpdump -en -r - vlan
*/
header_type scope_t {
    fields {
        port : 9;
    }
}

metadata scope_t scope;

field_list lookup_hash_field {
        scope.port;
}

field_list update_hash_field {
        scope.port;
}

field_list clone_fields {
    standard_metadata;
}

action broadcast() {
    //pkt is sent to the i-th multicast group containing all the ports except the i-th
    modify_field(intrinsic_metadata.mcast_grp, standard_metadata.ingress_port);
}

action _nop() {   
}

action unicast(port){
    //pkt is forwarded to port 'port'
    modify_field(standard_metadata.egress_spec, port);
}

action HB_req(){
    //pkt is tagged 20 (HB_req) and forwarded to port 2
    modify_field(vlan_tag.vid, 20);
    modify_field(standard_metadata.egress_spec, 2);
}

action primary_and_HB_reply(port){
    //pkt is cloned to egress pipeline (we can match on instance_type=1) and forwarded to port 1
    clone_ingress_pkt_to_egress(1,clone_fields);
    //the original pkt is forwarded to port 'port'
    modify_field(vlan_tag.vid, 16);
    modify_field(standard_metadata.egress_spec, port);
}

action reply_probe(){
    //pkt is forwarded back to the inport
    modify_field(standard_metadata.egress_spec, standard_metadata.ingress_port);
}

action backup(){
    //pkt is tagged 17 (fault) and forwarded to port 3
    modify_field(vlan_tag.vid, 17);
    modify_field(standard_metadata.egress_spec, 3);
}

action backup_and_probe(){
    //pkt is cloned to egress pipeline (we can match on instance_type=1) and forwarded to port 2
    clone_ingress_pkt_to_egress(2,clone_fields);
    //the original pkt is tagged 17 (fault) and forwarded to port 3
    modify_field(vlan_tag.vid, 17);
    modify_field(standard_metadata.egress_spec, 3);
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
    //pkt is tagged 16 and forwarded to port 'port'
    modify_field(vlan_tag.vid, 16);
    modify_field(standard_metadata.egress_spec, port);
}

action HB_reply(){
    //actions for cloned packet
    //NB: output port cannot be changed in the egress tables => output port is selected by means of mirror_id
    modify_field(vlan_tag.vid, 21);
}

action send_probe(){
    //actions for cloned packet
    //NB: output port cannot be changed in the egress tables => output port is selected by means of mirror_id
    modify_field(vlan_tag.vid, 22);
}

table forward {
    reads{
        openstate.state: ternary;
        standard_metadata.ingress_port: exact;
        vlan_tag.vid: exact;
    }
    actions {
        HB_req;
        unicast;
        backup;
        backup_and_probe;
        primary_and_HB_reply;
        reply_probe;
        reset_tag_and_primary;
        _nop;
    }
}

table update_outport_state {
    reads{
        openstate.state: exact;
        standard_metadata.ingress_port: exact;
        vlan_tag.vid: exact;
    }
    actions{
        update_state_table;
        _nop;
    }
}

table arp_manager {
    actions { 
        broadcast;
    }
}

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

table inport_write_metadata{
    actions {
        write_metadata_inport;
        _nop;
    }
}

table update_inport_state{
    actions{
        update_state_table;
        _nop;
    }
}

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
                apply(inport_write_metadata);
                apply(update_inport_state);
                apply(output_write_metadata);
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