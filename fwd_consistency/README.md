# fwd_consistency.p4

Guide to test the forwarding consistency application

To start the application write in the command line
./run_demo.bash

Once the mininet is started, you can populate the table from the mininet shell
sh ./add_demo_entries.bash

Now open the following terminals
xterm h1 h2 h3 h4

On the terminal h2 h3 and h4 execute an echo server as follows

[h2]
sudo python echo_server.py 200
[h3]
sudo python echo_server.py 300
[h4]
sudo python echo_server.py 400

Now, on the terminal h1 we can execute netcat in client mode

nc 10.0.1.1 80

The connection will be set up randomly with one of the 3 servers.
To test the timeouts functionality, a 5 sec idle timeout has been set. If the user does not talk for 5 sec the connection is lost