python ../../cli/pd_cli.py -p portknocking -i p4_pd_rpc.portknocking -s $PWD/tests/pd_thrift:$PWD/../../testutils -m "set_default_action state_lookup lookup_state_table" -c localhost:22222
python ../../cli/pd_cli.py -p portknocking -i p4_pd_rpc.portknocking -s $PWD/tests/pd_thrift:$PWD/../../testutils -m "set_default_action hard_to_expired set_hard_rb_state" -c localhost:22222
python ../../cli/pd_cli.py -p portknocking -i p4_pd_rpc.portknocking -s $PWD/tests/pd_thrift:$PWD/../../testutils -m "set_default_action idle_to_expired set_idle_rb_state" -c localhost:22222
python ../../cli/pd_cli.py -p portknocking -i p4_pd_rpc.portknocking -s $PWD/tests/pd_thrift:$PWD/../../testutils -m "set_default_action arp_manager broadcast" -c localhost:22222

mgrphdl=`python ../../cli/pd_cli.py -p portknocking -i p4_pd_rpc.portknocking -s $PWD/tests/pd_thrift:$PWD/../../testutils -m "mc_mgrp_create 1" -c localhost:22222 | awk '{print $NF;}'`
echo $mgrphdl > mgrp.hdl
l1hdl=`python ../../cli/pd_cli.py -p portknocking -i p4_pd_rpc.portknocking -s $PWD/tests/pd_thrift:$PWD/../../testutils -m "mc_node_create 0 30 -1" -c localhost:22222 | awk '{print $NF;}'`
echo $l1hdl > l1.hdl
python ../../cli/pd_cli.py -p portknocking -i p4_pd_rpc.portknocking -s $PWD/tests/pd_thrift:$PWD/../../testutils -m "mc_associate_node $mgrphdl $l1hdl" -c localhost:22222
python ../../cli/pd_cli.py -p portknocking -i p4_pd_rpc.portknocking -s $PWD/tests/pd_thrift:$PWD/../../testutils -m "set_default_action knock_sequence _reset" -c localhost:22222
python ../../cli/pd_cli.py -p portknocking -i p4_pd_rpc.portknocking -s $PWD/tests/pd_thrift:$PWD/../../testutils -m "add_entry knock_sequence 10 0 update_state_table 1 5000000 0 0 0" -c localhost:22222
python ../../cli/pd_cli.py -p portknocking -i p4_pd_rpc.portknocking -s $PWD/tests/pd_thrift:$PWD/../../testutils -m "add_entry knock_sequence 11 1 update_state_table 2 5000000 0 0 0" -c localhost:22222
python ../../cli/pd_cli.py -p portknocking -i p4_pd_rpc.portknocking -s $PWD/tests/pd_thrift:$PWD/../../testutils -m "add_entry knock_sequence 12 2 update_state_table 3 5000000 0 0 0" -c localhost:22222
python ../../cli/pd_cli.py -p portknocking -i p4_pd_rpc.portknocking -s $PWD/tests/pd_thrift:$PWD/../../testutils -m "add_entry knock_sequence 13 3 update_state_table 4 5000000 0 10000000 0" -c localhost:22222
python ../../cli/pd_cli.py -p portknocking -i p4_pd_rpc.portknocking -s $PWD/tests/pd_thrift:$PWD/../../testutils -m "add_entry knock_sequence 22 4 _nop" -c localhost:22222

python ../../cli/pd_cli.py -p portknocking -i p4_pd_rpc.portknocking -s $PWD/tests/pd_thrift:$PWD/../../testutils -m "set_default_action output _drop" -c localhost:22222
python ../../cli/pd_cli.py -p portknocking -i p4_pd_rpc.portknocking -s $PWD/tests/pd_thrift:$PWD/../../testutils -m "add_entry output 22 4 forward 2" -c localhost:22222
python ../../cli/pd_cli.py -p portknocking -i p4_pd_rpc.portknocking -s $PWD/tests/pd_thrift:$PWD/../../testutils -m "add_entry output 1300 0 forward 2" -c localhost:22222

