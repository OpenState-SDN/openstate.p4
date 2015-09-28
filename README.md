# openstate.p4

Guide to configure the P4 OpenState Applications

Get the last version of p4factory

    git clone https://github.com/p4lang/p4factory.git

    cd p4factory
    git submodule update --init --recursive
    ./install_deps.sh
    ./autogen.sh
    ./configure

Clone the P4 OpenState repository

    git clone https://github.com/OpenState-SDN/openstate.p4

copy the openstate.p4 library inside the p4factory/targets folder

    cp ~/openstate.p4/openstate.p4 ~/p4factory/targets/

Now we have to create 3 new targets:

*mac_learning
*portknocking
*fwd_consistency

#Target creation
    python ~/p4factory/tools/newtarget.py {app_name}

copy from the repository's {app_name} folder the entire contents and paste them into :

    cp -r ~/openstate.p4/{app_name}/* ~/p4factory/targets/{app_name}

to compile the P4 program

    cd ~/p4factory/targets/{app_name}
    make

to run the program

    ./run_demo.bash

Once the mininet is started, you can populate the table from the mininet shell

    mininet> sh ./add_demo_entries.bash
