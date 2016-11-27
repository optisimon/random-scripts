#!/bin/bash
#
# Usage: log_line_at_keypress [-l logfile] command [parameters...]
#
# Description:
#   Will run command with specified parameters, and whenever any key have
#   been pressed, log the last line to the optional logfile.
#     Assumes that you have a vt100 compatible terminal. The
#   last line will always be visible at the bottom of the screen,
#   but the screen will only scroll on keypress.
#
# Limitations:
#   This tool is suitable for programs not printing too many lines per second.
#   You need a VT100 compatible terminal (most terminals will be compatible).
#
# Known bugs:
#   May occassionally give the error
#   "echo: write error: Interrupted system call"
#   Just press any key once more. This hasn't mattered for what I've been using
#   it for, so may not be fixed.
#
# License:
#   Copyright (c) 2016 Simon Gustafsson (www.optisimon.com)
#   Do whatever you like with this code, but please refer to me as the
#   original author.
#

wait_for_anykey()
{
	while true ; do
		read -n1 -r -s key
		break
		#[ "$key" == "l" ] && break
		#echo "key=\"$key\""
	done
}

LOGFILE=""

line=""
eraseAndGoback="\033[2K\r"
bold1="\033[1m";
bold0="\033[0m";
sigusr1()
{
	echo -e -n "$eraseAndGoback$bold1"
	echo -n "$line"
	echo -e "$bold0"
	[ -n "$LOGFILE" ] && {
		echo "$line" >> "$LOGFILE";
	}
}

handle_cmd_output()
{
	trap sigusr1 SIGUSR1

	while read -r -s line ; do
		#Erase from the beginning of line to cursor, then back to beginning
		echo -e -n "$eraseAndGoback$line"
	done
}

[ "$#" -eq 0 ] && {
	echo "Usage: $(basename "$0") [-l logfile] command [parameters...]"
	echo
	echo "Will run command with specified parameters, and whenever"
	echo "any key have been pressed, log the last line to logfile"
	echo
	echo "Assumes that you have a vt100 compatible terminal. The"
	echo "last line will always be visible at the bottom of the screen,"
	echo "but the screen will only scroll on keypress."
	echo
	echo "This tool is only suitable for programs not printing too many"
	echo "lines per second."
	exit 1
}

[ "$#" -gt 2 ] && {
	[ "$1" == "-l" ] && {
		LOGFILE="$2" ;
	}
	shift
	shift
}

"$@" | handle_cmd_output &
ourpid=$!

while true ; do
	wait_for_anykey ;
	kill -SIGUSR1 $ourpid 2>/dev/null || break;
done
echo
