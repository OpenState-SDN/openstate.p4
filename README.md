# openstate.p4

How to test the P4 OpenState applications?

##P4 download

Download a clean Mininet 2.2.1 VM on Ubuntu 14.04 (64 bit) at [this link](https://github.com/mininet/mininet/wiki/Mininet-VM-Images).

You need to clone two p4lang Github repositories:

    cd ~
    git clone https://github.com/p4lang/behavioral-model.git bmv2
    git clone https://github.com/p4lang/p4c-bm.git p4c-bmv2

Install the following Python packages:

    sudo apt-get update && sudo apt-get install python-pip
    sudo pip install scapy thrift networkx

Each of these repositories comes with dependencies:

    cd ~/p4c-bmv2
    sudo pip install -r requirements.txt
    
    cd ~/bmv2
    ./install_deps.sh
    
Do not forget to build the code once all the dependencies have been installed:

    cd ~/bmv2
    ./autogen.sh
    ./configure
    make

##P4 OpenState applications download

Clone the P4 OpenState repository:

    cd ~
    git clone https://github.com/OpenState-SDN/openstate.p4

Now you can test the following OpenState-based applications:

* mac_learning
* portknocking
* fwd_consistency
* SPIDER: Fault Resilient SDN Pipeline with Recovery Delay Guarantees

To run an application:

    cd ~/openstate.p4/{app_name}
    ./run_demo.sh
    
Each application's folder has its own README file.
