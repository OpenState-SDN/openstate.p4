# portknocking.p4

Guide to test the port knocking application

To start the application write in the command line

    ./run_demo.bash

Now open the following terminals

    mininet> xterm h1 h2

On the terminal h2 open an UDP server on port 22 as follows

    h2# python udpserv.py -s 22

Now, on the terminal h1 we can try different knocking sequences.

Run the following commands, write something in the Netcat client and press ENTER.

    echo -n "*" | nc -q1 -u 10.0.0.2 10
    echo -n "*" | nc -q1 -u 10.0.0.2 11
    echo -n "*" | nc -q1 -u 10.0.0.2 40
    nc -u 10.0.0.2 22
    
The sequence is wrong, so no message is shown at server side.
    
In this application there is an idle timeout of 5 sec set between each knock. If the time between two consecuve knocks exceeds the timeout threshold, the knock sequence is considered invalid.

    echo -n "*" | nc -q1 -u 10.0.0.2 10
    echo -n "*" | nc -q1 -u 10.0.0.2 11
    echo -n "*" | nc -q1 -u 10.0.0.2 12
    sleep 7
    echo -n "*" | nc -q1 -u 10.0.0.2 13
    nc -u 10.0.0.2 22

In this case the sequence is correct, but it is too slow.

    echo -n "*" | nc -q1 -u 10.0.0.2 10
    echo -n "*" | nc -q1 -u 10.0.0.2 11
    echo -n "*" | nc -q1 -u 10.0.0.2 12
    echo -n "*" | nc -q1 -u 10.0.0.2 13
    nc -u 10.0.0.2 22

In this last case is now possible to see the messages at server side.
Once port 22 is open, an idle timeout of 5 seconds and a hard timeout of 10 seconds are set.
Try to wait 5 seconds between the 1st and the 2nd message: the idle timeout will expire and the port will be locked again.
Repeat the knocking sequence and try to send messages every second: the idle timeout will not expire, but after 10 seconds (hard timeout) the port will be closed.
