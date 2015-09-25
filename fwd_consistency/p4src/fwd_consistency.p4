#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/intrinsic.p4"

#define STATE_MAP_SIZE 13    // 13 bits = 8192 state entries
#define STATE_TABLE_SIZE 8192
#include "../../openstate.p4"


header_type routing_metadata_t {
    fields {
        nhop_ipv4 : 32;
        ipv4Length : 16;
        tcpLength : 16;
    }
}

metadata routing_metadata_t routing_metadata;


// Definition of the lookup and update scope
field_list lookup_hash_field {
        ipv4.srcAddr;
        ipv4.dstAddr;
        ipv4.protocol;
        tcp.srcPort;
        tcp.dstPort;
}

field_list update_hash_field {
        ipv4.srcAddr;
        ipv4.dstAddr;
        ipv4.protocol;
        tcp.srcPort;
        tcp.dstPort;
}

// hash field list used to choose a random port
field_list random_port {
        ipv4.srcAddr;
        ipv4.dstAddr;
        ipv4.protocol;
        tcp.srcPort;
        tcp.dstPort;
        intrinsic_metadata.ingress_global_timestamp;
}

field_list_calculation port {
    input {
        random_port;
    }
    algorithm : csum16;
    output_width : 16;
}


action random(){
    //the modify_field_with_hash_based_offset works in this way (base + (hash_value % size))
    //since we want to choose a port between 2 and 4 we use: (2 + (hash_value % 3))
    modify_field_with_hash_based_offset(openstate.state, 2, port, 3);
}


action forward(eth_dst,ip_dst,tcp_dst) {
    //We need to change the eth_dst, ip_dst and tcp_dst
    modify_field(ethernet.dstAddr, eth_dst);
    modify_field(ipv4.dstAddr, ip_dst);
    modify_field(tcp.dstPort, tcp_dst);
    //since the tcp packet has been modified, the checksum has to be recalculated
    //The tcp checksum takes into consideration some ipv4 header and a tcpLength that cannot be retrieved from the packet header
    //tcpLength il the length in bytes of header tcp + payload tcp
    //we know that ipv4.totalLen gives the length in byte of the ip header + ip payload (in our case the tcp incapsulated in it)
    //Thus we need to subtract from ipv4.totalLen the length in byte of the ip header.
    //the ip header can be calculated in this way:
    //ipv4Length = ipv4.ihl * 4 [bytes] (in p4 we can't make a multiplication inside a modify_field: the following solution is ugly)
    modify_field(routing_metadata.ipv4Length, ipv4.ihl);
    add_to_field(routing_metadata.ipv4Length, ipv4.ihl);
    add_to_field(routing_metadata.ipv4Length, ipv4.ihl);
    add_to_field(routing_metadata.ipv4Length, ipv4.ihl);
    modify_field(routing_metadata.tcpLength, ipv4.totalLen);
    subtract_from_field(routing_metadata.tcpLength, routing_metadata.ipv4Length);
    //the packet is forwarded towards the port pointed by the state
    modify_field(standard_metadata.egress_spec, openstate.state);
}

action forward_back(eth_src,ip_src,tcp_src) {
    //We need to change the eth_src, ip_src and tcp_src
    modify_field(ethernet.srcAddr, eth_src);
    modify_field(ipv4.srcAddr, ip_src);
    modify_field(tcp.srcPort, tcp_src);
    //As stated il the forward action, we need to calculate tcpLength 
    modify_field(routing_metadata.ipv4Length, ipv4.ihl);
    add_to_field(routing_metadata.ipv4Length, ipv4.ihl);
    add_to_field(routing_metadata.ipv4Length, ipv4.ihl);
    add_to_field(routing_metadata.ipv4Length, ipv4.ihl);
    modify_field(routing_metadata.tcpLength, ipv4.totalLen);
    subtract_from_field(routing_metadata.tcpLength, routing_metadata.ipv4Length);
    //the packet is always forwarded towards port 1 (1-to-many)
    modify_field(standard_metadata.egress_spec, 1);
}

action broadcast() {
    modify_field(intrinsic_metadata.mcast_grp, 1);
}


/*********** TABLES *************/

table port_selection {
    actions{
        random;
    }
}

table update_state {
    reads{
        openstate.state : exact;
    }
    actions {
        update_state_table;
    }
}

table output {
    reads {
        openstate.state : exact;
    }
    actions {
        forward;
    }
}

table reply {
    actions {
        forward_back;
    }
}

table arp_manager {
    actions { 
        broadcast;
    }
}

/***********************************/

control ingress {
    //in case of tcp packet
    if(valid(ethernet) and ethernet.etherType == ETHERTYPE_IPV4 and valid(ipv4) and ipv4.protocol == IP_PROTOCOLS_TCP and valid(tcp))
    {
        if(tcp.dstPort == 80)
        {
            //state lookup
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
            //in case of state = 0 a random port has to be chosen
            if (openstate.state == 0)
            {
                apply(port_selection);
                apply(update_state);
            }
            //the packet is forwarded
            apply(output);
        }
        //replies managment: all the replies have to be forwarded towards port 1 (client)
        if(tcp.srcPort == 200 or tcp.srcPort == 300 or tcp.srcPort == 400)
        {
            apply(reply);   
        }       
    }
    //in case of arp packet: flood
    if(valid(ethernet) and ethernet.etherType == ETHERTYPE_ARP)
    {
        apply(arp_manager);
    }
}