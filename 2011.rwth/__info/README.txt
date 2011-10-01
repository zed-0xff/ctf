Hello rwthCTF participant!

With this file, we want to give you some first basic guidelines for
participating in our CTF. Please have a look at the following files.
You should get your setup up and running in the next few days so
you don't lose valuable time in the actual CTF.

The event will be built around a classic Vulnbox-based CTF game, however there
will be a higher goal to pursue. This goal must be reached via several consecutive
challenges which involve several hacking skills. As a prerequisite for solving
the challenges, one has to gain points through attacking and defending the team's
vulnerable system.

More details will be available once the CTF starts. For the moment you can mentally
prepare yourself for the obstacles to come and take a look at the test-vulnbox
described below. This virtual image serves as a test endpoint in the VPN until the
actual CTF starts. VPN credentials are listed below, too, but are not yet available.
We will distribute the files in the next days.

Make sure to join #rwthctf on the freenode IRC network - we are hanging around that
channel in case anybody needs some low-latency discussions.


* testvuln.ova

  Every team is given a virtual machine image of a system they have to defend,
  a so called "vulnerable box" ("vulnbox", for short). The "testvuln.ova"
  file contains such an image, which you can use to test your VirtualBox
  setup. This is not the actual vulnbox of the CTF! You will receive the real
  one later.

  Go to http://www.virtualbox.org/wiki/Downloads, download and install VirtualBox.
  Go to "File", "Import Appliance" and select "testvuln.ova". You should
  now be able to boot the system.

  The VirtualBox network adapter should be set to "Bridged Adapter".

  The vulnbox will be a current stable 64-bit version of Debian GNU/Linux.
  The root password for the test vulnbox is "root".
  Edit /etc/network/interfaces and set

    address 10.11.X.2
    netmask 255.255.255.0
    gateway 10.11.X.1

  where "X" is your team ID.


* client.conf, rwthctfca.pem, ta.key, teamX.cert, teamX.key

  Those are your OpenVPN configurations, keys and certificates which you
  will need to connect to the CTF network.
  We highly discourage you from running OpenVPN from inside the vulnbox!
  You should get a single dedicated OpenVPN router box (see "network.png").
  In principle, you could also run VirtualBox and OpenVPN on the same
  machine, but we discourage it.

  After starting OpenVPN, you will have a tun0 interface on your box.
  Don't touch this interface, the configuration should be fine right away.
  In particular, don't change its IP address.

  Create a network interface with 10.11.X.1/255.255.255.0 on the router box
  (for example with "ifconfig eth0:1 10.11.X.1 netmask 255.255.255.0").

  Activate IP forwarding in your kernel!

  Ping 10.11.X.2 to see if your vulnbox is up.
  Ping 10.11.0.1 to check if your VPN connection is up.

  For every client (e.g., player laptops, etc.) in your team's network,
  you should create a network interface with a fixed IP address from
  your 10.11.X.0/24 network.


* network.png

  This is a rough (and incomplete) overview of how the CTF network looks like.

