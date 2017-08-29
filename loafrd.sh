#!/bin/bash

# LOaFR, Low Overhead Flight Recorder, Pronounced Loafer
VERSION=1.0.0
SOCAT=0
NETCAT="nc"

# Sanity check
currentver="$(uname -r)"
requiredver='4.8.0'
if [ "$(printf "$requiredver\n$currentver" | sort -V | head -n1)" == "$currentver" ] && [ "$currentver" != "$requiredver" ]; then
    echo "Less than $requiredver, needs --perf --overwrite support in-kenel and perf"
    exit 1
fi

if ! type "perf" > /dev/null; then
    echo "This daemon requires perf to be installed."
    exit 1
fi

if ! type "socat" > /dev/null || ! type "nc" > /dev/null || ! type "netcat" > /dev/null; then
    echo "This daemon requires nc, netcat or socat to be installed."
    exit 1
fi

if  type "socat" > /dev/null; then
    SOCAT=1
fi

if type "netcat" > /dev/null; then
    NETCAT="netcat"
fi

RUNDIR=/var/run
KTRACEDIR=${RUNDIR}/loafr
PIDFILE=${KTRACEDIR}/loafr.pid
SOCKFILE=${KTRACEDIR}/loafr.sock

mkdir -p ${KTRACEDIR}

MANDATED_POLICY="--switch-output --overwrite -a --tail-synthesize -m 2048 -o loafr.data -r 1"
INPUT=$(mktemp -u)
mkfifo -m 660 "$INPUT"
OUTPUT=$(mktemp -u)
mkfifo -m 660 "$OUTPUT"

if [ ${SOCAT} -eq 1 ]; then
    rm -fr ${SOCKFILE}
    (umask 00002; cat ${INPUT} | socat UNIX-LISTEN:${SOCKFILE},fork - > "${OUTPUT}") &
else

    (umask 00002; cat ${INPUT} | ${NETCAT} -NlkU "${SOCKFILE}" > "${OUTPUT}") &
fi
NCPID=$!

exec 4>"${INPUT}"
exec 5<"${OUTPUT}"


# Allow the loafr group to have R/W access to socket.
# Daemon should run as root, with a trace user group where
# users should be members.

# Argument are unaltered, goes directly to perf
restart_perf () {
    cd ${KTRACEDIR}

    rm -fr ${KTRACEDIR}/loafr.data.*
    if [ -f ${PIDFILE} ]; then
	if ps -p $(cat ${PIDFILE}) > /dev/null 2>&1; then
	    kill -9 $(cat ${PIDFILE})
	    while ps -p $(cat ${PIDFILE}) > /dev/null; do sleep 1; done
	fi
    fi
    (perf record $@ ${MANDATED_POLICY} 2>&1) 1>&4 &
    PID=$!
    echo ${PID} > ${PIDFILE}
}

# Snapshot daemon, snapshot will end up in ${KTRACEDIR} as perf.data.$DATE
# echo 'SNAPSHOT' | nc -UN ${RUNDIR}/loafr/loafr.sock

# Change config and restart by:
# echo "-e syscalls:*/call-graph=no/" | nc -U ${RUNDIR}/loafr/loafr.sock

# Low Overhead Flight Recorder
echo "LOaFR(Loafer) daemon started and listening on ${SOCKFILE}"

# nohup
#trap "" SIGHUP
restart_perf '-e syscalls:*/call-graph=no/ -e sched:*/call-graph=no/ -e irq:*/call-graph=no/'

while true; do
    read -u 5 -r INPUT_DATA
    if [ "${INPUT_DATA}" = 'SNAPSHOT' ]; then
	kill -SIGUSR2 $(cat ${PIDFILE})
	continue
    fi

    if [ "${INPUT_DATA}" = 'VERSION' ]; then
	sleep 4
	echo ${VERSION} 1>&4
	continue
    fi
    echo "Re-starting: perf record ${INPUT_DATA} --switch-output --overwrite -a --tail-synthesize -m 2048 -o loafr.data -r 1" 1>&4
    echo "Re-starting: perf record ${INPUT_DATA} --switch-output --overwrite -a --tail-synthesize -m 2048 -o loafr.data -r 1" > /dev/kmsg
    restart_perf ${INPUT_DATA}
    sleep 1
done
