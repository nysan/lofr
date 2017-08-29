#!/bin/sh

RUNDIR=/var/run
KTRACEDIR=${RUNDIR}/loafr
PIDFILE=${KTRACEDIR}/loafr.pid
SOCKFILE=${KTRACEDIR}/loafr.sock

NETCAT="nc -U ${SOCKFILE}"

if type "netcat" > /dev/null; then
    NETCAT="netcat -U ${SOCKFILE}"
fi

# FIXME: socat terminated immediately on EOF on input stream,
#        which causes problems. fixit.
#if type "socat" > /dev/null; then
#    NETCAT="socat UNIX-CONNECT:${SOCKFILE} STDIO,shut-down"
#fi

usage () {
    cat <<EOF
Usage: $0 [options] [output_dir]

--help            This text..
--version         The version of the LOaFR Daemon
--kversion        The version of the Linux kernel
--snapshot        Snapshot the flight recorder with optional output dir.
--reconf          Reconfigure perf with new arguments, some are
		  mandated by daemon default policy.
		  Argument are unaltered, goes directly to perf

EOF
}


# Snapshot daemon, snapshot will end up in $KTRACEDIR as perf.data.$DATE
case "$1" in
    --version)
	echo 'VERSION' | ${NETCAT} | (read line; echo $line)
	;;
    --kversion)
	uname -r
	;;
    --pversion)
	perf --version
	;;
    --snapshot)
	echo 'SNAPSHOT' | ${NETCAT} | (read line; echo $line; read line; echo $line)
	if [ $# -eq 2 ]; then
	    shift
	    mv ${KTRACEDIR}/loafr.data.* $1/
	    echo "Wrote output to: $1"
	else
	    echo "Output dir: ${KTRACEDIR}"
	fi

	;;
    --snapshot2)
	# When you do not care when perf is finished writing to
	# output file.
	kill -SIGUSR2 $(cat ${PIDFILE})
	echo "Dumped to ${KTRACEDIR}"
	;;
    --reconf)
	shift
	echo "$@" | ${NETCAT}
	;;
    --help)
	usage
	exit 0
	;;
    *)
	usage
	exit 1
	;;
esac
