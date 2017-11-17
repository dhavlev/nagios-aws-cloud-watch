# nagios-aws-cloud-watch 
This script will help you collect the datapoints from cloud watch

#### Things to consider
1. Make sure Access key ID and Secret access key is configured
2. Appropriate version of ruby is installed
3. aws-sdk for ruby is installed

#### How to call script
nagios_aws_cloudwatch.rb [options]

#### Help
nagios_aws_cloudwatch.rb --help

##### AWS/EC2
--region "ap-south-1" --namespace "AWS/EC2" --metric_name "CPUUtilization" --dimension "InstanceId:i-02fexxxxxxxxxx870fb50b" --statistics "Average" --unit "Percent" --critical 90 --warning 60

##### AWS/ELB
--region "ap-south-1" --namespace "AWS/ELB" --metric_name "UnHealthyHostCount" --dimensions "LoadBalancerName:xxxxxx-loadbalancer-name" --statistics "Average" --unit "Count" --critical 1, --warning 1

##### AWS/ApplicationELB
--region "ap-south-1" --namespace "AWS/ApplicationELB" --metric_name "UnHealthyHostCount" --dimension "LoadBalancer:app/ALB-1/511cxxxxa2eb7d4,TargetGroup:targetgroup/Agentalb/6dfxxxxxed99aad4" --statistics "Average" --unit "Count" --critical 1 --warning 1


