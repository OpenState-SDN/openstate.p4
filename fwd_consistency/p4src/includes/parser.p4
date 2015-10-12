parser start {
    return parse_ethernet;
}

#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_ARP 0x0806

header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4;
        ETHERTYPE_ARP: ingress;
    }
}

header ipv4_t ipv4;

#define IP_PROTOCOLS_TCP  6

field_list ipv4_checksum_list {
        ipv4.version;
        ipv4.ihl;
        ipv4.diffserv;
        ipv4.totalLen;
        ipv4.identification;
        ipv4.flags;
        ipv4.fragOffset;
        ipv4.ttl;
        ipv4.protocol;
        ipv4.srcAddr;
        ipv4.dstAddr;
}

field_list_calculation ipv4_checksum {
    input {
        ipv4_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field ipv4.hdrChecksum  {
    verify ipv4_checksum;
    update ipv4_checksum;
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.fragOffset,latest.protocol) {
        IP_PROTOCOLS_TCP : parse_tcp;       
        default: ingress;
    }
}

header tcp_t tcp;

parser parse_tcp {
    extract(tcp);
    return ingress;
}

field_list tcp_int_checksum_list {
        ipv4.srcAddr;
        ipv4.dstAddr;
        8'0;
        ipv4.protocol;
        routing_metadata.tcpLength;
        tcp.srcPort;
        tcp.dstPort;
        tcp.seqNo;
        tcp.ackNo;
        tcp.dataOffset;
        tcp.res;
        tcp.ecn;
        tcp.ctrl;
        tcp.window;
        tcp.urgentPtr;       
        payload;
}

field_list_calculation tcpv4_calc {
    input {
        tcp_int_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field tcp.checksum {
    update tcpv4_calc if (valid(ipv4));
}