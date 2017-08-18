#!/usr/bin/env bash
#
# Push custom metrics to Cloudwatch.
# 
# Note this script requires a /etc/aws/instance-name file

# When testing on a vagrant box, echo the cloudwatch commands instead of submitting them.
if ! test -d "/vagrant"
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

# Memory (ignored space used by buffers/cache)
MEMORY_STATS=$(free -m)
MEMORY_USED=$(printf "$MEMORY_STATS" | awk '/+ buffers/ {print $3}')
MEMORY_FREE=$(printf "$MEMORY_STATS" | awk '/+ buffers/ {print $4}')
MEMORY_USED_PERCENTAGE=$(echo "100*$MEMORY_USED/($MEMORY_FREE+$MEMORY_USED)" | bc -l)
SWAP_USED=$(printf "$MEMORY_STATS" | awk '/Swap/ {print $3}')

# Disk usage
DISK_USAGE=$(df | grep "^/dev")
DISK_USED_PERCENTAGE=$(echo "$DISK_USAGE" | awk '{print substr($5, 1, length($5 - 1))}')
DISK_USED=$(echo "$DISK_USAGE" | awk '{print $3}')
DISK_AVAILABLE=$(echo "$DISK_USAGE" | awk '{print $4}')

# Push to cloudwatch
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
