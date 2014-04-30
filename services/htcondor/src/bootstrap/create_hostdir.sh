#!/bin/bash

CFG=/etc/wlcg-mjf-htcondor.config

#
# Find the directory
#

MACHINEFEATURE=`awk '/^MACHINEFEATURE=/{split($0,a,"="); print a[2];}' $CFG`
if [ -z "$MACHINEFEATURE" ]; then
  echo "Could not find the MACHINEFEATURE param in $CFG" 1>&2
  exit 1
fi

#
# Put in place CPU info
#
NUM_CPUS=`awk '/^NUM_CPUS=/{split($0,a,"="); print a[2];}' $CFG`
if [ -z "${NUM_CPUS}" ]; then
  NUM_CPUS=`cat /proc/cpuinfo |grep '^processor' |wc -l`
fi

NUM_HT_CPUS=`awk '/^NUM_HT_CPUS=/{split($0,a,"="); print a[2];}' $CFG`
if [ -z "${NUM_HT_CPUS}" ]; then
  NUM_HT_CPUS=`cat /proc/cpuinfo |awk '/^siblings/{if (notfirst!=1) {split($0,a,": "); print a[2];}; notfirst=1;}'`
  if [ -z "${NUM_HT_CPUS}" ]; then
    NUM_HT_CPUS=${NUM_CPUS}
  fi
fi

#
# Find number of job slots
# Query HTCondor, if needed
#
NUM_SLOTS=`awk '/^NUM_SLOTS=/{split($0,a,"="); print a[2];}' $CFG`
if [ -z "${NUM_SLOTS}" ]; then
  NUM_SLOTS=`condor_config_val NUM_SLOTS`
  if [ -z "${NUM_SLOTS}" ]; then
    # make the best guess
    NUM_SLOTS=`condor_config_val NUM_CPUS`
    if [ -z "${NUM_SLOTS}" ]; then
      # just default to something, do not fail
      echo "Could not find the number of slots, defaulting to ${NUM_CPUS}" 1>&2
      NUM_SLOTS=${NUM_CPUS}
    fi
  fi
fi

#
# Find the HS06 number
#
HS06=`awk '/^HS06VAL=/{split($0,a,"="); print a[2];}' $CFG`
if [ -z "$HS06" ]; then
  HS06MAPFILE=`awk '/^HS06MAPFILE=/{split($0,a,"="); print a[2];}' $CFG`
  if [ -z "HS06MAPFILE" ]; then
   HS06MAPFILE=/etc/wlcg-mjf-hs06.map
  fi

  awk_expr='/^model name/{if (notfirst!=1) {split($0,a,": "); print "\""a[2]"\"";}; notfirst=1;}'
  CPUID="`cat /proc/cpuinfo |awk \"${awk_expr}\"`"
  HS06=`grep "^${CPUID} " "$HS06MAPFILE" | awk '{split($0,a,"\" "); print a[2]}'|head -1`
  if [ -z "$HS06" ]; then
    # too hard to guess a vlid default, fail
    echo "Cound not find a HS06 mapping in $HS06MAPFILE" 1>&2
    echo "CPUID ${CPUID}" 1>&2
    exit 1
  fi
fi

#
# Now that we have all the info, put it on disk
#

umask 0022
if [ ! -d $MACHINEFEATURE ]; then
  mkdir -p $MACHINEFEATURE && chmod 0755 $MACHINEFEATURE
  if [ $? -ne 0 ]; then
    echo "Failed to create $MACHINEFEATURE"1>&2
    exit 2
  fi
fi

echo ${NUM_CPUS} > $MACHINEFEATURE/log_cores 
echo ${NUM_HT_CPUS} > $MACHINEFEATURE/phys_cores 
echo ${NUM_SLOTS} > $MACHINEFEATURE/jobslots
echo ${HS06} > $MACHINEFEATURE/hs06

