header_type intrinsic_metadata_t {
    fields {
        mcast_grp : 4;
        egress_rid : 4;
        mcast_hash : 16;
        lf_field_list: 32;
        deq_timedelta : 32;
        enq_timestamp : 32;
        ingress_global_timestamp : 32;
    }
}

metadata intrinsic_metadata_t intrinsic_metadata;