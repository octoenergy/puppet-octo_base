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

# JSON Metrics
METRICS_FILENAME=/usr/local/sbin/current_metrics.json
METRICS_JSON=$(
    jq -n \
        --arg INSTANCE_ID "$INSTANCE_ID" \
        --arg INSTANCE_NAME "$INSTANCE_NAME" \
        --arg TIMESTAMP "$TIMESTAMP" \
        --argjson CPU "$CPU" \
        --argjson LOAD "$LOAD" \
        --argjson MEMORY_USED "$MEMORY_USED" \
        --argjson MEMORY_USED_PERCENTAGE "$MEMORY_USED_PERCENTAGE" \
        --argjson MEMORY_FREE "$MEMORY_FREE" \
        --argjson SWAP_USED "$SWAP_USED" \
        --argjson DISK_USED_PERCENTAGE "$DISK_USED_PERCENTAGE" \
        --argjson DISK_USED "$DISK_USED" \
        --argjson DISK_AVAILABLE "$DISK_AVAILABLE" \
        "$(cat /usr/local/sbin/metrics.json)" \
        >$METRICS_FILENAME
)

# Push to Cloudwatch
# ------------------

$AWS_EXECUTABLE --region=$REGION cloudwatch put-metric-data --namespace $NAMESPACE --metric-data file://$METRICS_FILENAME
