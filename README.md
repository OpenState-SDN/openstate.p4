# openstate.p4

Guide to test the P4 OpenState applications

#SSH key pair generation

Some P4 submodules require you have a SSH key pair attached to your GitHub account.

Open a shell in your Mininet VM.

Generate a new SSH key:

    ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

Start the ssh-agent in the background:

    eval "$(ssh-agent -s)"

Add your SSH key to the ssh-agent:

    ssh-add ~/.ssh/id_rsa

Copy your public key in the clipboard:

    cat ~/.ssh/id_rsa.pub

Go to https://github.com/settings/ssh

Click on [Add SSH key], choose a title and paste your public key. Finally click on [Add key].

#P4 download

Get the last version of p4factory:

    cd ~
    git clone https://github.com/p4lang/p4factory.git

    cd p4factory
    git submodule update --init --recursive
    ./install_deps.sh
    ./autogen.sh
    ./configure

#P4 OpenState applications download

Clone the P4 OpenState repository:
    
    cd ~
    git clone https://github.com/OpenState-SDN/openstate.p4

Copy the openstate.p4 library inside the p4factory/targets folder:

    cp ~/openstate.p4/openstate.p4 ~/p4factory/targets/

Now you can compile and test the following OpenState-based applications:

* mac_learning
* portknocking
* fwd_consistency

#Target creation

Create a P4 target:

    python ~/p4factory/tools/newtarget.py {app_name}

Copy from the {app_name} folder the entire contents and paste them into:

    cp -r ~/openstate.p4/{app_name}/* ~/p4factory/targets/{app_name}

Compile the P4 program:

    cd ~/p4factory/targets/{app_name}
    make

Run the program:

    ./run_demo.bash

Once Mininet is started, you can populate the flow tables using the Mininet shell:

    mininet> sh ./add_demo_entries.bash
