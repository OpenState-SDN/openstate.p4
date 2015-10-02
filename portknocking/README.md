# portknocking.p4

Guide to test the port knocking application

To start the application write in the command line

    ./run_demo.bash

Once the mininet is started, you can populate the table from the mininet shell

    mininet> sh ./add_demo_entries.bash

Now open the following terminals

    mininet> xterm h1 h2

On the terminal h2 execute a UDP echo server on port 22 as follows

    h2# python udpserv.py -s 22

Now, on the terminal h1 we can try different knocking sequence

    # Wrong sequence
    echo -n "*" | nc -q1 -u 10.0.1.1 10
    echo -n "*" | nc -q1 -u 10.0.1.1 11
    echo -n "*" | nc -q1 -u 10.0.1.1 40
    nc -u 10.0.1.1 22

    # Correct sequence but too slow (idle_to=5sec between each knock)
    echo -n "*" | nc -q1 -u 10.0.1.1 10
    echo -n "*" | nc -q1 -u 10.0.1.1 11
    echo -n "*" | nc -q1 -u 10.0.1.1 12
    sleep 7
    echo -n "*" | nc -q1 -u 10.0.1.1 13
    nc -u 10.0.1.1 22

    # Correct sequence
    echo -n "*" | nc -q1 -u 10.0.1.1 10
    echo -n "*" | nc -q1 -u 10.0.1.1 11
    echo -n "*" | nc -q1 -u 10.0.1.1 12
    echo -n "*" | nc -q1 -u 10.0.1.1 13
    nc -u 10.0.1.1 22

Write something. Now it is possible to see the messages at server side.
In this application we have an idle timeout of 5 sec set between each knock. If the time between two consecuve knocks overcames the timeout threshold, the knock sequence is considered invalid.
An idle timeout of 5 seconds and an hard timeout of 10 seconds are set when the port 22 is open.
Try to wait 5 seconds between the 1st and the 2nd message: the idle timeout will expire and the port will be locked again.
Try to send messages every second: the hard timeout will expire (10 sec) even if I was sending messages.
