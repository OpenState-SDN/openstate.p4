# openstate.p4

Guide to test the P4 OpenState applications

#P4 download

You will need to clone 2 p4lang Github repositories and install their dependencies. To clone the repositories:

    cd ~
    git clone https://github.com/p4lang/behavioral-model.git bmv2
    git clone https://github.com/p4lang/p4c-bm.git p4c-bmv2

Each of these repositories come with dependencies.

    sudo pip install -r ~/p4c-bmv2/requirements.txt
    ~/bmv2/install_deps.sh
    
Do not forget to build the code once all the dependencies have been installed:

    cd ~/bmv2
    ./install_deps.sh
    ./autogen.sh
    ./configure

#P4 OpenState applications download

Clone the P4 OpenState repository:

    cd ~
    git clone https://github.com/OpenState-SDN/openstate.p4

Now you can test the following OpenState-based applications:

* mac_learning
* portknocking

To run an application:

    ~/openstate.p4/{app_name}/run_demo.sh
    
Each application's folder has its own README file.
