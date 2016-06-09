###Introduction

	NB: This P4 application is exactly the same of SPIDER_local. The pipeline specified in P4 langugage is the same,
	but the installed rules are different: packets from H2 to H1 are forwarded on path S3-S2-S1 instead of S3-S4-S1.
	In this way we can appreciate how FRIP avoids thw generation HB packets towards a port from which 
	packets are incoming at a rate greater than HB_req rate.

The scope of this application is to demonstrate how it is possible to create a detection mechanism in P4 by exploiting the stateful abstraction provided by OpenState. 

A specific switch is in charge to drive packets towards a backup path in case of failure, without relying on the controller.

![topology](https://github.com/OpenState-SDN/openstate.p4/blob/master/SPIDER_local/images/local.png)

In the image is depicted the topology in use. It consists of 4 switches and 2 hosts. In normal conditions, the traffic from H1 to H2 and from H2 to H1 is forwarded in the below path.

	NB: we do not provide backup path for request H2->H1 in case of failures.
	The aim of this application is just to show the smartness of FRIP FSM in the generation of HB packets.
	For this reason we are not going to take down link S1-S2.

The detection is done by means of heart beat packets (HB) to evaluate the link liveness.

The interarrival of HB request is set to 50 ms (20 HB_req/sec ). If the rate of traffic generated is lower than 20 pkt/sec, each data packet is marked as HB by changing its VLAN tag to 20.

###Guide to test the Failure Recovery application

To start the application write in the command line

	./run_demo.sh

Three xterms will appear: 

Two of them are tcpdump instances running on switch S1 on primary path and detour path respectively

The third is a H1 xterm that performs ping towards H2 (1 pkt/sec)

In absence of failure, by looking at S1's terminals, we can appreciate the following things:

1) Since the Heart Beat rate (20 pkt/sec) is greater than the ping rate, each data packet is exploited as Heart Beat. The tcpdump on s1-eth2 (primary path) shows HB_req tagged with VLAN ID 20, their replies tagged with ID 21 and ICMP replies from H2 to H1 with VLAN ID field set to 16.

2) The tcpdump on s1-eth3 (backup path) does not show any packet.

Now stop the ping H1->H2 with CTRL+C and try to decrease the interval between sending each packet:

	h1# ping 192.168.100.2 -i 0.04

	In SPIDER_local we observed that since HB rate (20 pkt/sec) was lower than the ping rate (25 pkt/sec), in tcpdump some data packets
	were sent unmodified (VLAN ID 16) while other were marked as Heart Beat packets).
	This does not hold anymore: ICMP replies will be received every 40 ms, the Heart Beat generation timeout won't expire (50 ms)
	and so no Heart Beat request will be generated!
