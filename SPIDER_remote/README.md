###Introduction
The scope of this application is to demonstrate how it is possible to create a detection mechanism in P4 by exploiting the stateful abstraction provided by OpenState. 
A specific switch is in charge to drive packets towards a backup path in case of failure, without relying on the controller.

![Topology](https://bitbucket.org/openstate-sdn/p4-openstate/raw/master/SPIDER_remote/images/remote.png)

In the image is depicted the topology in use. It consists of 4 switches and 2 hosts. In normal conditions, the traffic from H1 to H2 is forwarded in the below path and the replies from H2 to H1 pass through the above switch.
If a failure is detected, both requests and replies are forwarded on the above path, called backup path.

The detection is done by means of heart beat packets (HB) to evaluate the link liveness.
The interarrival of HB request is set to 50 ms (20 HB_req/sec ). If the rate of traffic generated is lower than 20 pkt/sec, each data packet is marked as HB by changing its VLAN tag to 20.
A timeout of 50 ms is set up as time limit for the HB reply to come back (the reply is the same packet with VLAN tag set to 21).
If no reply comes back within the thresold, the link is considered down.
In case of failure, the switch, periodically, checks if the link becomes again available by sending probe messages.
Each 5 sec a packet forwarded on the backup path is also duplicated on the primary path and tagged with a special VLAN ID tag (22). If this message comes back, the link can be considered up.

###Guide to test the Failure Recovery application

To start the application write in the command line

	./run_demo.sh

Four xterms will appear:

Two of them are tcpdump instances running on switch S1 on primary path and detour path respectively

One xterm runs tcpdump on the monitored link (S2's xterm)

The last one is a H1 xterm that performs ping towards H2 (1 pkt/sec)

In absence of failure, by looking at both S1's and S2's terminals, we can appreciate the following things:

1) Since the Heart Beat rate (20 pkt/sec) is greater than the ping rate, each data packet is exploited as Heart Beat (see S2 xterm). The tcpdump on S2-eth2 shows HB_req tagged with VLAN ID 20 and their replies tagged with ID 21.

2) The tcpdump on S1-eth3 (backup path) shows the ICMP replies from H2 to H1 with VLAN ID field set to 16

3) The tcpdump on S1-eth2 (primary path) shows the ICMP requests from H1 to H2 with VLAN ID field set to 16

We can trigger a link failure by putting down a switch port.
In the Mininet prompt write

	mininet> sh ifconfig s3-eth2 down

In this scenario, by looking at S1's and S2's terminals, we can notice that:

1) On the S2's terminal there are no more packets (link down)

2) On the backup path (tcpdump on S1-eth3) you can see ICMP requests tagged with VLAN ID 17 (failure tag) and the replies tagged with VLAN ID 16

3) On the primary path (tcpdump on S1-eth2) every 5 sec a probe packet is sent to check the path availability

The failure can be solved with the following command in the Mininet prompt

	mininet> sh ifconfig s3-eth2 up

By looking at the tcpdump on the primary path, it is possible to see the back and forth of the sent probe packet (VLAN ID 22) that triggers the forwarding of the traffic H1->H2 back to the primary path.
