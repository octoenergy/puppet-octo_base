#!/usr/bin/env bash
#
# Push custom metrics to Cloudwatch.
# 
# Note this script requires a /etc/aws/instance-name file which should be put in place with
# userdata.

set -eu -o pipefail
exec 1> >(logger --stderr --tag $(basename $0)) 2>&1

# Use a lockfile to prevent this script running in parallel processes (which can overload the server
# if too many get started).
LOCKFILE=/tmp/`basename "$0"`.lock
lockfile-create --retry=0 --lock-name "$LOCKFILE"
function remove_lock {
    lockfile-remove --lock-name "$LOCKFILE"
}
trap remove_lock EXIT

# When testing on a vagrant box, echo the cloudwatch commands instead of submitting them.
if ! test -d "/vagrant" && [ -z "${DEBUG+x}" ]
then
    REGION=$(ec2metadata --availability-zone | awk '{print substr($1, 1, length($1) - 1)}')
    INSTANCE_ID=$(ec2metadata --instance-id)
    INSTANCE_NAME=$(cat /etc/aws/instance-name)
    AWS_EXECUTABLE="/usr/local/bin/aws"
else
    REGION=""
    INSTANCE_ID=""
    INSTANCE_NAME=""
    AWS_EXECUTABLE="echo aws"
fi
    
TIMESTAMP=$(date +%FT%T)
NAMESPACE="EC2/Custom"

# Collect metrics
# ---------------

# System load
LOAD=$(cut -d" " -f1 /proc/loadavg)

# System CPU (=100 - IDLE)
CPU=$(top -bn1 | grep "^%Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

# Memory (ignoring space used by buffers/cache)
MEMORY_STATS=$(free -m)

# The output of `free -m` changes between Ubuntu releases
UBUNTU_VERSION=`lsb_release -rs`
if [[ "$UBUNTU_VERSION" == "14.04" ]]
then
    MEMORY_USED=$(printf "$MEMORY_STATS" | awk '/+ buffers/ {print $3}')
    MEMORY_FREE=$(printf "$MEMORY_STATS" | awk '/+ buffers/ {print $4}')
elif [[ "$UBUNTU_VERSION" == "16.04" ]]
then
    MEMORY_USED=$(printf "$MEMORY_STATS" | awk '/Mem:/ {print $3}')
    MEMORY_FREE=$(printf "$MEMORY_STATS" | awk '/Mem:/ {print $4}')
else
    # Assumed 18:04
    MEMORY_USED=$(printf "$MEMORY_STATS" | awk '/Mem:/ {print $3}')
    # Take free memory from the "available" column
    MEMORY_FREE=$(printf "$MEMORY_STATS" | awk '/Mem:/ {print $7}')
fi
MEMORY_USED_PERCENTAGE=$(echo "100*$MEMORY_USED/($MEMORY_FREE+$MEMORY_USED)" | bc -l)
SWAP_USED=$(printf "$MEMORY_STATS" | awk '/Swap/ {print $3}')

# Disk usage - take the df line mounted on /
DISK_USAGE=$(df | grep " /$")
DISK_USED_PERCENTAGE=$(echo "$DISK_USAGE" | awk '{print substr($5, 1, length($5) - 1)}')
DISK_USED=$(echo "$DISK_USAGE" | awk '{print $3}')
DISK_AVAILABLE=$(echo "$DISK_USAGE" | awk '{print $4}')

# Push to Cloudwatch
# ------------------

# CPU
$AWS_EXECUTABLE --region=$REGION cloudwatch put-metric-data --namespace $NAMESPACE --metric-name "CPUUtilization" --unit "Percent" --value $CPU --dimensions "InstanceName=$INSTANCE_NAME" --timestamp $TIMESTAMP

# Load
$AWS_EXECUTABLE --region=$REGION cloudwatch put-metric-data --namespace $NAMESPACE --metric-name "SystemLoad" --value $LOAD --dimensions "InstanceId=$INSTANCE_ID" --timestamp $TIMESTAMP
$AWS_EXECUTABLE --region=$REGION cloudwatch put-metric-data --namespace $NAMESPACE --metric-name "SystemLoad" --value $LOAD --dimensions "InstanceName=$INSTANCE_NAME" --timestamp $TIMESTAMP

# Memory
$AWS_EXECUTABLE --region=$REGION cloudwatch put-metric-data --namespace $NAMESPACE --metric-name "MemoryUsed" --unit "Megabytes" --value $MEMORY_USED --dimensions "InstanceId=$INSTANCE_ID" --timestamp $TIMESTAMP
$AWS_EXECUTABLE --region=$REGION cloudwatch put-metric-data --namespace $NAMESPACE --metric-name "MemoryUsedPercentage" --unit "Percent" --value $MEMORY_USED_PERCENTAGE --dimensions "InstanceId=$INSTANCE_ID" --timestamp $TIMESTAMP
$AWS_EXECUTABLE --region=$REGION cloudwatch put-metric-data --namespace $NAMESPACE --metric-name "MemoryUsedPercentage" --unit "Percent" --value $MEMORY_USED_PERCENTAGE --dimensions "InstanceName=$INSTANCE_NAME" --timestamp $TIMESTAMP
$AWS_EXECUTABLE --region=$REGION cloudwatch put-metric-data --namespace $NAMESPACE --metric-name "MemoryFree" --unit "Megabytes" --value $MEMORY_FREE --dimensions "InstanceId=$INSTANCE_ID" --timestamp $TIMESTAMP

# Swap
$AWS_EXECUTABLE --region=$REGION cloudwatch put-metric-data --namespace $NAMESPACE --metric-name "SwapUsed" --unit "Megabytes" --value $SWAP_USED --dimensions "InstanceId=$INSTANCE_ID" --timestamp $TIMESTAMP

# Disk
$AWS_EXECUTABLE --region=$REGION cloudwatch put-metric-data --namespace $NAMESPACE --metric-name "DiskUsedPercentage" --unit "Percent" --value $DISK_USED_PERCENTAGE --dimensions "InstanceId=$INSTANCE_ID" --timestamp $TIMESTAMP
$AWS_EXECUTABLE --region=$REGION cloudwatch put-metric-data --namespace $NAMESPACE --metric-name "DiskUsedPercentage" --unit "Percent" --value $DISK_USED_PERCENTAGE --dimensions "InstanceName=$INSTANCE_NAME" --timestamp $TIMESTAMP
$AWS_EXECUTABLE --region=$REGION cloudwatch put-metric-data --namespace $NAMESPACE --metric-name "DiskUsed" --unit "Bytes" --value $DISK_USED --dimensions "InstanceId=$INSTANCE_ID" --timestamp $TIMESTAMP
$AWS_EXECUTABLE --region=$REGION cloudwatch put-metric-data --namespace $NAMESPACE --metric-name "DiskAvailable" --unit "Bytes" --value $DISK_AVAILABLE --dimensions "InstanceId=$INSTANCE_ID" --timestamp $TIMESTAMP
