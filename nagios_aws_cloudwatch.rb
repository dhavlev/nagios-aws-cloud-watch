require 'optparse'
require 'json'
require 'time'
require 'aws-sdk'

## EC2
#options = {:region => "ap-south-1", :namespace => "AWS/EC2", :metric_name => "CPUUtilization", :dimensions => "InstanceId:i-02fedXXX08X0fb50b", :statistics => "Average", :unit => "Percent", :critical => 0.3, :warning => 0.55}

## ALB
#options = {:region => "ap-south-1", :namespace => "AWS/ApplicationELB", :metric_name => "UnHealthyHostCount", :dimensions => "LoadBalancer:app/ALB-1/511ccxxx2caxeb7d4,TargetGroup:targetgroup/Agentalb/6xxc9xxxd99xxad4", :statistics => "Average", :unit => "Count", :critical => 1, :warning =>1}

## ELB
#options = {:region => "ap-south-1", :namespace => "AWS/ELB", :metric_name => "UnHealthyHostCount", :dimensions => "LoadBalancerName:profiling-service", :statistics => "Average", :unit => "Count", :critical => 1, :warning => 1}

options = {:region => nil, :namespace => nil, :metric_name => nil, :dimensions => nil, :statistics => nil, :unit => nil, :critical => nil, :warning => nil}


NAGIOS_CODE_OK = 0		# UP
NAGIOS_CODE_WARNING = 1		# UP or DOWN/UNREACHABLE*
NAGIOS_CODE_CRITICAL = 2	# DOWN/UNREACHABLE
NAGIOS_CODE_UNKNOWN = 3		# DOWN/UNREACHABLE

def threshold_check(namespace, statistics, critical_val, warning_val, datapoints = {})
	case namespace
	when "AWS/EC2"
		if datapoints[statistics.to_sym] >= warning_val && datapoints[statistics.to_sym] < critical_val
			puts "NAGIOS_CODE_WARNING"
			return NAGIOS_CODE_WARNING
		elsif datapoints[statistics.to_sym] >= critical_val
			puts "NAGIOS_CODE_CRITICAL"
			return NAGIOS_CODE_CRITICAL
		else
			puts "NAGIOS_CODE_OK"
			NAGIOS_CODE_OK
		end

	when "AWS/ELB", "AWS/ApplicationELB"
		if warning_val != critical_val && datapoints[statistics.to_sym] >= warning_val && datapoints[statistics.to_sym] > critical_val
			puts "NAGIOS_CODE_WARNING"
                        return NAGIOS_CODE_WARNING
                elsif datapoints[statistics.to_sym] >= critical_val
			puts "NAGIOS_CODE_CRITICAL"
                        return NAGIOS_CODE_CRITICAL
                else
			puts "NAGIOS_CODE_OK"
                        NAGIOS_CODE_OK
                end
	else
		puts "Default case executed"
		return NAGIOS_CODE_UNKNOWN
	end
end

def analyse_response(namespace, statistics, critical_val, warning_val, resp = {})
	if !resp.nil? && !resp.datapoints[0].nil?
		threshold_check(namespace, statistics, critical_val, warning_val, resp.datapoints[0])
	else
		puts "Unable to retrieve reponse from CloudWatch"
		nagios_rsp = NAGIOS_CODE_UNKNOWN
	end	
end

parser = OptionParser.new do|opts|
			opts.banner = "Usage: aws_cloudwatch.rb [options]"

			opts.on('-r', '--region region', 'AWS Region') do |region|
                                options[:region] = region;
                        end
			
			opts.on('-n', '--namespace namespace', 'Namespace') do |namespace|
				options[:namespace] = namespace;
			end
			
			opts.on('-m', '--metric_name metric name', 'Metric Name') do |metric_name|
				options[:metric_name] = metric_name;
			end

			opts.on('-d', '--dimensions dimensions', 'Dimensions') do |dimensions|
				options[:dimensions] = dimensions;
			end
			
			opts.on('-s', '--statistics statistics', 'Statistics') do |statistics|
				options[:statistics] = statistics;
			end

			opts.on('-u', '--unit unit', 'Unit') do |statistics|
                                options[:unit] = statistics;
                        end
			
			opts.on('-c', '--critical critical', 'Critical values') do |critical|
				options[:critical] = critical;
			end
			
			opts.on('-w', '--warning warning', 'Warning values') do |warning|
				options[:warning] = warning;
			end

			opts.on('-h', '--help', 'Displays Help') do
				puts opts
				exit
		end
end

parser.parse!


if options[:region] == nil
        print 'Specify region: '
    options[:region] = gets.chomp
end


if options[:namespace] == nil
        print 'Enter namespace: '
    options[:namespace] = gets.chomp
end

if options[:metric_name] == nil
        print 'Enter metric name: '
    options[:metric_name] = gets.chomp
end

if options[:dimensions] == nil
        print 'Enter dimensions: '
    options[:dimensions] = gets.chomp
else
    puts options[:dimensions]
end

if options[:statistics] == nil
        print 'Enter statistics: '
    options[:statistics] = gets.chomp
end

if options[:unit] == nil
        print 'Enter unit: '
    options[:unit] = gets.chomp
end


if options[:critical] == nil
        print 'Enter critical value: '
    options[:critical] = gets.chomp
end

if options[:warning] == nil
        print 'Enter warning value: '
    options[:warning] = gets.chomp
end



alb_request = Hash.new
alb_request[:namespace] = options[:namespace]
alb_request[:metric_name] = options[:metric_name]
alb_request[:dimensions] = []
alb_request[:start_time] = Time.now().utc - 60*10 
alb_request[:end_time] = Time.now().utc
alb_request[:period] = 3600
alb_request[:statistics] = []
alb_request[:statistics] << options[:statistics]
alb_request[:unit] = options[:unit]

d_array = options[:dimensions].split(',')

d_array.each do |item|
  dm = Hash.new
  dm[:name] = item.split(':')[0]
  dm[:value] = item.split(':')[1]
  alb_request[:dimensions] << dm
end

client = Aws::CloudWatch::Client.new(
        region: options[:region]
)

response = client.get_metric_statistics(alb_request)
datapoint = response.datapoints[0]

flag = analyse_response(options[:namespace], options[:statistics].downcase, options[:critical].to_f, options[:warning].to_f, response)
puts "CloudWatch Metric: #{response.label}, Average: #{datapoint.average}, Maximum: #{datapoint.maximum}, Minimum: #{datapoint.minimum}, Sum: #{datapoint.sum}"
exit flag
