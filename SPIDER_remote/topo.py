#!/usr/bin/python

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

from mininet.net import Mininet
from mininet.topo import Topo
from mininet.log import setLogLevel, info
from mininet.cli import CLI
from mininet.link import TCLink

from p4_mininet import P4Switch, P4Host
from mininet.term import makeTerm

import argparse
from time import sleep
import os
import subprocess

_THIS_DIR = os.path.dirname(os.path.realpath(__file__))
_THRIFT_BASE_PORT = 9090

parser = argparse.ArgumentParser(description='Mininet demo')
parser.add_argument('--behavioral-exe', help='Path to behavioral executable',
                    type=str, action="store", required=True)
parser.add_argument('--json', help='Path to JSON config file',
                    type=str, action="store", required=True)
parser.add_argument('--cli', help='Path to BM CLI',
                    type=str, action="store", required=True)

args = parser.parse_args()

class MyTopo(Topo):
    def __init__(self, sw_path, json_path, nb_hosts, nb_switches, links, **opts):
        # Initialize topology and default options
        Topo.__init__(self, **opts)

        for i in xrange(nb_switches):
            switch = self.addSwitch('s%d' % (i + 1),
                                    sw_path = sw_path,
                                    json_path = json_path,
                                    thrift_port = _THRIFT_BASE_PORT + i,
                                    pcap_dump = False,
                                    device_id = i)
        
        for h in xrange(nb_hosts):
            host = self.addHost('h%d' % (h + 1))

        for a, b in links:
            self.addLink(a, b)

def read_topo():
    nb_hosts = 0
    nb_switches = 0
    links = []
    with open("topo.txt", "r") as f:
        line = f.readline()[:-1]
        w, nb_switches = line.split()
        assert(w == "switches")
        line = f.readline()[:-1]
        w, nb_hosts = line.split()
        assert(w == "hosts")
        for line in f:
            if not f: break
            a, b = line.split()
            links.append( (a, b) )
    return int(nb_hosts), int(nb_switches), links
            

def main():
    nb_hosts, nb_switches, links = read_topo()

    topo = MyTopo(args.behavioral_exe,
                  args.json,
                  nb_hosts, nb_switches, links)

    net = Mininet(topo = topo,
                  host = P4Host,
                  switch = P4Switch,
                  autoStaticArp = True,
                  controller = None,
                  autoSetMacs = True)
    net.start()

    for n in xrange(nb_hosts):
        h = net.get('h%d' % (n + 1))
        for off in ["rx", "tx", "sg"]:
            cmd = "/sbin/ethtool --offload eth0 %s off" % off
            print cmd
            h.cmd(cmd)
        print "disable ipv6"
        h.cmd("sysctl -w net.ipv6.conf.all.disable_ipv6=1")
        h.cmd("sysctl -w net.ipv6.conf.default.disable_ipv6=1")
        h.cmd("sysctl -w net.ipv6.conf.lo.disable_ipv6=1")
        h.cmd("sysctl -w net.ipv4.tcp_congestion_control=reno")
        h.cmd("iptables -I OUTPUT -p icmp --icmp-type destination-unreachable -j DROP")
        h.cmd("sh h%d.vlan" % (n + 1)) # Create interface eth0.16 and add static ARP entries

    sleep(1)

    for i in xrange(nb_switches):
        # Create mirror_id j to clone packets towards j-th port
        for j in range(len(topo.ports['s'+str(i+1)])):
            cmd = ['echo "mirroring_add',str(j+1),str(j+1),'" | ~/bmv2/targets/simple_switch/sswitch_CLI',args.json, str(_THRIFT_BASE_PORT + i)]
            print " ".join(cmd)
            subprocess.call(" ".join(cmd), shell=True)
        
        # added "--pre SimplePreLAG" refer to https://github.com/p4lang/behavioral-model
        cmd = [args.cli, "--json", args.json,
               "--thrift-port", str(_THRIFT_BASE_PORT + i), "--pre", "SimplePreLAG"]
        with open("commands_%d.txt" % (i+1), "r") as f:
            print " ".join(cmd)
            try:
                output = subprocess.check_output(cmd, stdin = f)
                print output
            except subprocess.CalledProcessError as e:
                print e
                print e.output

    sleep(1)

    print "Ready !"

    makeTerm(net['s1'],title="Redirect node - Primary path",cmd="tcpdump -n -i s1-eth2 -Uw - | tcpdump -en -r - vlan;echo;echo;echo Last command: \x1B[32m'tcpdump -n -i s1-eth2 -Uw - | tcpdump -en -r - vlan'\x1B[0m; bash")
    makeTerm(net['s1'],title="Redirect node - Backup path",cmd="tcpdump -n -i s1-eth3 -Uw - | tcpdump -en -r - vlan;echo;echo;echo Last command: \x1B[32m'tcpdump -n -i s1-eth3 -Uw - | tcpdump -en -r - vlan'\x1B[0m; bash")
    makeTerm(net['s2'],title="Detect node - Detected link",cmd="tcpdump -n -i s2-eth2 -Uw - | tcpdump -en -r - vlan;echo;echo;echo Last command: \x1B[32m'tcpdump -n -i s2-eth2 -Uw - | tcpdump -en -r - vlan'\x1B[0m; bash")
    makeTerm(net['h1'],title="Host H1",cmd="ping 192.168.100.2;echo;echo;echo Last command: \x1B[32mping 192.168.100.2 -i 1\x1B[0m; bash")

    CLI( net )
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )
    main()
