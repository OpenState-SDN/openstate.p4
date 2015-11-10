# mac_learning.p4

Guide to test the Mac Learning application

To start the application run the following command:

    ./run_demo.bash

Now open the following terminals

    mininet> xterm h1 h1 h2 h2 h3

On the terminal h3 execute tcpdump as follows

    h3# tcpdump -n -i eth0 arp or dst port 80

On the terminal h2 execute Netcat in listening mode on UDP port 80 

    h2# nc -luv 80

Do the same for host h1

    h1# nc -luv 80

Execute a Netcat client on host h1, write something and press ENTER:

    h1# nc -u 10.0.0.2 80

The switch learns the position of h1 but, since we are using UDP and we do not have any reply from h2 to h1, the position of h2 is not learned and the packets from h1 to h2 will be always broadcasted. (see tcpdump output in h3).

The association host-port lasts 10 seconds: if within 10 seconds h2 communicates to h1, no packets will be received by h3. h3 will see messages again after the timeout expiration (hard_to is set 10 sec).

Try it by executing Netcat in client mode on host h2

    h2# nc -u 10.0.0.1 80
    
Wait more than 10 seconds and repeat

    h2# nc -u 10.0.0.1 80
