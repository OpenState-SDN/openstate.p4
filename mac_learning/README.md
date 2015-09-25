# mac_learning.p4

Guide to test the mac learning application

To start the application write in the command line
./run_demo.bash

Once the mininet is started, you can populate the table from the mininet shell
sh ./add*

Now open the following terminals
xterm h1 h1 h2 h2 h3

On the terminal h3 execute tcpdump as follows

tcpdump -i eth0 arp or dst port 80

On the terminal h2 execute Netcat in listening mode over port UDP 80 

nc -luv 80

Perform the same for host 1

nc -luv 80

Execute Netcat in client mode on host 1 and write something
nc -u 10.0.1.1 80

Since we are using UDP, we do not have any reply from h2 to h1, thus the learning of the h2 position is not perform and the packets will be always broadcasted. (see tcpdump in h3)

If within 10 seconds h2 talks to h1, h3 will do not receive any message anymore.
h3 will see messages again after the timeout expiration (hard_to 10 sec)

You can try it by executing Netcat in client mode on host 2 and write something
nc -u 10.0.0.1 80
