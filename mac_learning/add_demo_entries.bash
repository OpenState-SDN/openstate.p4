python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "set_default_action lookup lookup_state_table" -c localhost:22222
python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "set_default_action hard_to_expired set_hard_rb_state" -c localhost:22222
python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "set_default_action idle_to_expired set_idle_rb_state" -c localhost:22222

mgrphdl=`python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "mc_mgrp_create 1" -c localhost:22222 | awk '{print $NF;}'`
echo $mgrphdl > mgrp.hdl
l1hdl=`python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "mc_l1_node_create 0" -c localhost:22222 | awk '{print $NF;}'`
echo $l1hdl > l1.hdl
python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "mc_l1_associate_node $mgrphdl $l1hdl" -c localhost:22222
l2hdl=`python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "mc_l2_node_create $l1hdl 30 -1" -c localhost:22222 | awk '{print $NF;}'`
echo $l2hdl > l2.hdl

python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "add_entry update_state 1 update_state_table 1 0 0 10000000 0" -c localhost:22222
python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "add_entry update_state 2 update_state_table 2 0 0 10000000 0" -c localhost:22222
python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "add_entry update_state 3 update_state_table 3 0 0 10000000 0" -c localhost:22222
python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "add_entry update_state 4 update_state_table 4 0 0 10000000 0" -c localhost:22222

python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "set_default_action forward broadcast" -c localhost:22222
python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "add_entry forward 1 unicast" -c localhost:22222
python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "add_entry forward 2 unicast" -c localhost:22222
python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "add_entry forward 3 unicast" -c localhost:22222
python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "add_entry forward 4 unicast" -c localhost:22222

python ../../cli/pd_cli.py -p mac_learning -i p4_pd_rpc.mac_learning -s $PWD/of-tests/pd_thrift:$PWD/../../submodules/oft-infra -m "set_default_action arp_manager broadcast" -c localhost:22222