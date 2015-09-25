// Template parser.p4 file for mac_learning
// Edit this file as needed for your P4 program

// This parses an ethernet header

#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_ARP 0x0806

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : ingress;
        ETHERTYPE_ARP: ingress;
    }
}
