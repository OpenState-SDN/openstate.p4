header_type openstate_t {
    fields {
        lookup_state_index : STATE_MAP_SIZE; // state map index
        update_state_index : STATE_MAP_SIZE; // state map index
        state : 32;                          // state        
        hard_to: 32;                         // hard timeout
        hard_rb: 32;                         // hard rollback
        idle_to: 32;                         // idle timeout
        idle_rb: 32;                         // idle rollback
        hard_to_expiration : 32;             // it is the sum of hard_to and the timestamp of when it has been set
        idle_to_expiration : 32;             // last reference time
        new_idle_to_expiration : 32;         // new reference time
    }
}