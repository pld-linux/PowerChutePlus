#!/bin/sh
# @(#)xpowerchute	1.12
#         Copyright 1992, American Power Conversion, Inc.
#

PWRCHUTE=/usr/lib/powerchute
export PWRCHUTE

# we need to determine if powerchute is running
# and if it is, are we in local or network mode?

if [ "`ps ax | grep pwrchu | grep -v grep 2>/dev/null`" != "" ]; then
	#powerchute is running
	#check to see if usetcp is set to no

	if grep -iqs "usetcp.*no" /etc/powerchute.ini >/dev/null 2>/dev/null; then
		# usetcp is set to no.
		echo "Can't run more than one version of "
		echo "PowerChute Client in Local Mode."
	else
		exec $PWRCHUTE/_xpwrchute
	fi
else
	# powerchute is not running.  Go ahead and launch it.
	exec $PWRCHUTE/_xpwrchute
fi
