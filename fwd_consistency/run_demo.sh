#!/bin/bash

# Copyright 2013-present Barefoot Networks, Inc. 
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source $THIS_DIR/../env.sh

P4C_BM_SCRIPT=$P4C_BM_PATH/p4c_bm/__main__.py

SWITCH_PATH=$BMV2_PATH/targets/simple_switch/simple_switch

CLI_PATH=$BMV2_PATH/tools/runtime_CLI.py

# Probably not very elegant but it works nice here: we enable interactive mode
# to be able to use fg. We start the switch in the background, sleep for 2
# minutes to give it time to start, then add the entries and put the switch
# process back in the foreground
set -m
$P4C_BM_SCRIPT p4src/fwd_consistency.p4 --json fwd_consistency.json
sudo echo "sudo" > /dev/null
sudo PYTHONPATH=$PYTHONPATH:$BMV2_PATH/mininet/ python topo.py \
    --behavioral-exe $BMV2_PATH/targets/simple_switch/simple_switch \
    --json fwd_consistency.json \
    --cli $CLI_PATH

echo "READY!!!"
fg