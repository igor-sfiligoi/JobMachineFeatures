# This file should be sourced before the job starts
# It expects to run inside bash

WLCG_MJF_CFG=/etc/wlcg-mjf-htcondor.config

if [ -z "$_CONDOR_MACHINE_AD" ]; then
  # just so it is defined for grepping
  _CONDOR_MACHINE_AD="$PWD/.machine.ad"
fi

MACHINEFEATURES=`awk '/^MACHINEFEATURES=/{split($0,a,"="); print a[2];}' ${WLCG_MJF_CFG}`
if [ ! -z "$MACHINEFEATURES" ]; then
################################# MACHINE FEATURES #####################
LOCALJOBFEATURES=`awk '/^JOBFEATURES=/{split($0,a,"="); print a[2];}' ${WLCG_MJF_CFG}`
if [ -z "$LOCALJOBFEATURES" ]; then
    # easy to pick a valid default
    LOCALJOBFEATURES=wlcg-mjf-job-features
fi

JOBFEATURES="${PWD}/${LOCALJOBFEATURES}"
mkdir "${JOBFEATURES}"
if [ $? -eq 0 ]; then
################################# JOB FEATURES #####################

# make it /tmp like
chmod 1777 "${JOBFEATURES}"

# When needed values are not in the config file, look them up in the MachineAd
# If there is nothing there, put in reasonable defaults

START_TIME=`awk '/^EnteredCurrentActivity =/{split($0,a,"= "); print a[2];}' ${_CONDOR_MACHINE_AD}`
if [ -z "${START_TIME}" ]; then
  START_TIME=`date +%s`
fi

SLOT_CPUS=`awk '/^SLOT_CPUS=/{split($0,a,"="); print a[2];}' ${WLCG_MJF_CFG}`
if [ -z "${SLOT_CPUS}" ]; then
  SLOT_CPUS=`awk '/^Cpus =/{split($0,a,"= "); print a[2];}' ${_CONDOR_MACHINE_AD}`
  if [ -z "${SLOT_CPUS}" ]; then
    SLOT_CPUS=1
  fi
fi

SLOT_MEM=`awk '/^SLOT_MEM=/{split($0,a,"="); print a[2];}' ${WLCG_MJF_CFG}`
if [ -z "${SLOT_MEM}" ]; then
  SLOT_MEM=`awk '/^Memory =/{split($0,a,"= "); print a[2];}' ${_CONDOR_MACHINE_AD}`
  if [ -z "${SLOT_MEM}" ]; then
    SLOT_MEM=2500
  fi
fi

SLOT_DISK=`awk '/^SLOT_DISK=/{split($0,a,"="); print a[2];}' ${WLCG_MJF_CFG}`
if [ -z "${SLOT_DISK}" ]; then
  SLOT_DISK=`awk '/^Disk =/{split($0,a,"= "); print int(a[2]/1000000);}' ${_CONDOR_MACHINE_AD}`
  if [ -z "${SLOT_DISK}" ]; then
    SLOT_DISK=20
  fi
fi

SLOT_TIME=`awk '/^SLOT_TIME=/{split($0,a,"="); print a[2];}' ${WLCG_MJF_CFG}`
if [ -z "${SLOT_TIME}" ]; then
  SLOT_TIME_RAW=`awk '/^MaxJobRetirementTime =/{split($0,a,"= "); print a[2];}' ${_CONDOR_MACHINE_AD}`
  let SLOT_TIME="${SLOT_TIME_RAW}"
  if [ -z "${SLOT_TIME}" ]; then
    SLOT_TIME=250000
  fi
fi


echo $START_TIME > "${JOBFEATURES}/jobstart_secs"
echo $SLOT_CPUS > "${JOBFEATURES}/allocated_CPU"
echo $SLOT_MEM > "${JOBFEATURES}/mem_limit_MB"
echo $SLOT_DISK > "${JOBFEATURES}/disk_limit_GB"
echo $SLOT_TIME > "${JOBFEATURES}/wall_limit_secs"
echo $SLOT_TIME > "${JOBFEATURES}/wall_limit_secs_lrms"
echo 1 > "${JOBFEATURES}/cpufactor_lrms"

################################# JOB FEATURES #####################
export JOBFEATURES

LOCALJOBSTATUS=`awk '/^JOBSTATUS=/{split($0,a,"="); print a[2];}' ${WLCG_MJF_CFG}`
if [ -z "$LOCALJOBSTATUS" ]; then
    # easy to pick a valid default
    LOCALJOBSTATUS=wlcg-rmjf-job-status
fi

JOBSTATUS="${PWD}/${LOCALJOBSTATUS}"
mkdir "${JOBSTATUS}"
if [ $? -eq 0 ]; then
################################# JOB STATUS #####################

# make sure it is world readable
chmod 0755 "${JOBSTATUS}"

################################# JOB STATUS #####################
export JOBSTATUS
fi # if jobstatus created

fi # if jobfeatures created

################################# MACHINE FEATURES #####################
export MACHINEFEATURES
fi # if MACHINEFEATURES
