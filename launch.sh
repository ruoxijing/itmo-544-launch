#!/usr/local/bin/bash
#declare an array in bash 
./cleanup.sh

declare -a instanceARR

mapfile -t instanceARR < <(aws ec2 run-instances --image-id $1 --count $2 --instance-type $3 --key-name $6 --security-group-ids $4 --subnet-id $5 --associate-public-ip-address --iam-instance-profile Name=$7 --user-data file://../itmo-544-env/install-webserver.sh --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g")
echo ${instanceARR[@]}

aws ec2 wait instance-running --instance-ids ${instanceARR[@]}
echo "instances are running"

ELBURL=(`aws elb create-load-balancer --load-balancer-name itmo544jrx-lb --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --security-groups $4 --subnets $5 --output=text`)
echo $ELBURL

echo -e "\nFinished launching ELB and sleeping 20 seconds"
for i in {0..20}; do echo -ne '.'; sleep 1;done
echo "\n"

aws elb register-instances-with-load-balancer --load-balancer-name itmo544jrx-lb --instances ${instanceARR[@]}

aws elb configure-health-check --load-balancer-name itmo544jrx-lb --health-check Target=HTTP:80/index.html,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3

echo -e "\nWaiting an additional 3 minutes - before opening the ELB in a webbrowser"
for i in {0..180}; do echo -ne '.'; sleep 1;done

#create launch configuration
aws autoscaling create-launch-configuration --launch-configuration-name itmo544-launch-config --image-id $1 --key-name $6 --security-groups $4 --instance-type $3 --user-data file://../itmo-544-env/install-webserver.sh --iam-instance-profile $7

#create autoscaling group
aws autoscaling create-auto-scaling-group --auto-scaling-group-name itmo-544-extended-auto-scaling-group-2 --launch-configuration-name itmo544-launch-config --load-balancer-names itmo544jrx-lb --health-check-type ELB --min-size 3 --max-size 6 --desired-capacity 3 --default-cooldown 600 --health-check-grace-period 120 --vpc-zone-identifier $5
