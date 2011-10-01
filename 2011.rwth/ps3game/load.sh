#!/bin/bash

modparams="sym_udp_protocol=0x$(egrep \\Wudp_protocol$ /boot/System.map-`uname -r` | awk '{print $1}')"

echo -n Loading module with \"$modparams\"...


if insmod codeserv.ko $modparams 2>/dev/null; then
	echo ' success.'
	exit 0
else
	echo ' failed.'
	echo -n Trying to remove existing module...

	if rmmod codeserv.ko 2>/dev/null; then
		echo ' success.'

		echo -n Trying to load module again...

		if insmod codeserv.ko $modparams 2>/dev/null; then
		        echo ' success.'
			exit 0
		else
		        echo ' failed.'
		fi
	else
		echo ' failed.'
	fi
fi

exit -1
