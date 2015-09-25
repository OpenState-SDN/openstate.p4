python ../../cli/pd_cli.py -p fwd_consistency -i p4_pd_rpc.fwd_consistency -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "set_default_action state_lookup lookup_state_table" -c localhost:22222
python ../../cli/pd_cli.py -p fwd_consistency -i p4_pd_rpc.fwd_consistency -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "set_default_action hard_to_expired set_hard_rb_state" -c localhost:22222
python ../../cli/pd_cli.py -p fwd_consistency -i p4_pd_rpc.fwd_consistency -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "set_default_action idle_to_expired set_idle_rb_state" -c localhost:22222
python ../../cli/pd_cli.py -p fwd_consistency -i p4_pd_rpc.fwd_consistency -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "set_default_action port_selection random" -c localhost:22222

mgrphdl=`python ../../cli/pd_cli.py -p fwd_consistency -i p4_pd_rpc.fwd_consistency -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "mc_mgrp_create 1" -c localhost:22222 | awk '{print $NF;}'`
echo $mgrphdl > mgrp.hdl
l1hdl=`python ../../cli/pd_cli.py -p fwd_consistency -i p4_pd_rpc.fwd_consistency -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "mc_l1_node_create 0" -c localhost:22222 | awk '{print $NF;}'`
echo $l1hdl > l1.hdl
python ../../cli/pd_cli.py -p fwd_consistency -i p4_pd_rpc.fwd_consistency -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "mc_l1_associate_node $mgrphdl $l1hdl" -c localhost:22222
l2hdl=`python ../../cli/pd_cli.py -p fwd_consistency -i p4_pd_rpc.fwd_consistency -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "mc_l2_node_create $l1hdl 30 -1" -c localhost:22222 | awk '{print $NF;}'`
echo $l2hdl > l2.hdl
python ../../cli/pd_cli.py -p fwd_consistency -i p4_pd_rpc.fwd_consistency -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "set_default_action arp_manager broadcast" -c localhost:22222

python ../../cli/pd_cli.py -p fwd_consistency -i p4_pd_rpc.fwd_consistency -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "add_entry update_state 2 update_state_table 2 0 0 5000000 0" -c localhost:22222
python ../../cli/pd_cli.py -p fwd_consistency -i p4_pd_rpc.fwd_consistency -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "add_entry update_state 3 update_state_table 3 0 0 5000000 0" -c localhost:22222
python ../../cli/pd_cli.py -p fwd_consistency -i p4_pd_rpc.fwd_consistency -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "add_entry update_state 4 update_state_table 4 0 0 5000000 0" -c localhost:22222

python ../../cli/pd_cli.py -p fwd_consistency -i p4_pd_rpc.fwd_consistency -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "add_entry output 2 forward 00:04:00:00:00:01 10.0.1.1 200" -c localhost:22222
python ../../cli/pd_cli.py -p fwd_consistency -i p4_pd_rpc.fwd_consistency -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "add_entry output 3 forward 00:04:00:00:00:02 10.0.2.1 300" -c localhost:22222
python ../../cli/pd_cli.py -p fwd_consistency -i p4_pd_rpc.fwd_consistency -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "add_entry output 4 forward 00:04:00:00:00:03 10.0.3.1 400" -c localhost:22222

python ../../cli/pd_cli.py -p fwd_consistency -i p4_pd_rpc.fwd_consistency -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "set_default_action reply forward_back 00:04:00:00:00:01 10.0.1.1 80" -c localhost:22222