
#!/usr/local/bin/bash 
#for mac
./cleanup.sh

#declare an array in bash 
declare -a instanceARR

#$1 ami image-id
#$2 count
#$3 instance-type
#$4 security-group-ids
#$5 subnet
#$6 key-name
#$7 iam-profile

mapfile -t instanceARR < <(aws ec2 run-instances --image-id $1 --count $2 --instance-type $3 --key-name $6 --security-group-ids $4 --subnet-id $5 --associate-public-ip-address --iam-instance-profile Name=$7 --user-data file://../itmo-544-env/install-webserver.sh --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g")
echo ${instanceARR[@]}

aws ec2 wait instance-running --instance-ids ${instanceARR[@]}
echo "instances are running"

ELBURL=(`aws elb create-load-balancer --load-balancer-name itmo544jrx-lb --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --security-groups $4 --subnets $5 --output=text`)
echo $ELBURL

echo -e "\nFinished launching ELB and sleeping 20 seconds"
for i in {0..20}; do echo -ne '.'; sleep 1;done
echo -e "\n"

aws elb register-instances-with-load-balancer --load-balancer-name itmo544jrx-lb --instances ${instanceARR[@]}

aws elb configure-health-check --load-balancer-name itmo544jrx-lb --health-check Target=HTTP:80/index.html,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3

echo -e "\nWaiting an additional 20 seconds - before opening the ELB in a webbrowser"
for i in {0..30}; do echo -ne '.'; sleep 1;done

#create launch configuration
echo -e "\n-create launch-configuration"
aws autoscaling create-launch-configuration --launch-configuration-name itmo544-launch-config --image-id $1 --key-name $6 --security-groups $4 --instance-type $3 --user-data file://../itmo-544-env/install-webserver.sh --iam-instance-profile $7

#create autoscaling group
echo -e "\n-create auto-scaling-group"
aws autoscaling create-auto-scaling-group --auto-scaling-group-name itmo-544-extended-auto-scaling-group-2 --launch-configuration-name itmo544-launch-config --load-balancer-names itmo544jrx-lb --health-check-type ELB --min-size 3 --max-size 6 --desired-capacity 3 --default-cooldown 600 --health-check-grace-period 120 --vpc-zone-identifier $5

#create rds-instances
echo -e "\n-create db"
aws rds create-db-subnet-group --db-subnet-group-name itmo544 --db-subnet-group-description "itmo544" --subnet-ids $5 subnet-16adbe4f
mapfile -t dbInstanceARR < <(aws rds describe-db-instances --output json | grep "\"DBInstanceIdentifier" | sed "s/[\"\:\, ]//g" | sed "s/DBInstanceIdentifier//g" )
#if [ ${#dbInstanceARR[@]} -gt 0 ]
#   then 
#echo ${#dbInstanceARR[@]}
   LENGTH=${#dbInstanceARR[@]}
#echo $LENGTH	
       for (( i=0; i<=${LENGTH}; i++));
      do
      if [[ ${dbInstanceARR[i]} == "jrxdb" ]]
     then 
      echo "db exists"
     else
     aws rds create-db-instance --db-name itmo544mp1 --db-instance-identifier jrxdb --db-instance-class db.t1.micro --engine MySQL --master-username rjing --master-user-password mypoorphp --allocated-storage 5 --db-subnet-group-name itmo544 --publicly-accessible
      fi  
      aws rds wait db-instance-available --db-instance-identifier jrxdb
     done  
#fi

#sns service
ARN=(`aws sns create-topic --name mp2`)
echo "This is the ARN: $ARN"

aws sns set-topic-attributes --topic-arn $ARN --attribute-name DisplayName --attribute-value mp2
aws sns subscribe --topic-arn $ARN --protocol sms --notification-endpoint 13127215036
aws sns publish --topic-arn $ARN --message "best code"

#cloudwatch AddCapacity
aws cloudwatch put-metric-alarm --alarm-name AddCapacity-mp2 --alarm-description "Alarm when CPU exceeds 30 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 120 --threshold 30 --comparison-operator GreaterThanOrEqualToThreshold --dimensions Name=LoadBalancerName,Value=itmo544jrx-lb --evaluation-periods 2 --alarm-actions $ARN --unit Percent
#cloudwatch RemoveCapacity
aws cloudwatch put-metric-alarm --alarm-name RemoveCapacity-mp2 --alarm-description "Alarm when CPU recedes 10 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 120 --threshold 10 --comparison-operator LessThanOrEqualToThreshold --dimensions Name=LoadBalancerName,Value=itmo544jrx-lb --evaluation-periods 2 --alarm-actions $ARN --unit Percent
