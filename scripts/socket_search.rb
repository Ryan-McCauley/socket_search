require 'socket'
require 'json'
require 'net/http'
require 'nmap/command'
require 'nmap/xml'

local_ip = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }
puts "Your local IP is: #{local_ip.ip_address if local_ip}"

def get_public_ip
  uri = URI('http://api.ipify.org')
  response = Net::HTTP.get(uri)
  response.strip
end

puts "Your public IP is: #{get_public_ip}"
puts '..................................................................'

def scan_network(targets)
  puts "target: #{targets}"
  Nmap::Command.run do |nmap|
    nmap.connect_scan = true
    nmap.service_scan   = true
    nmap.output_xml     = 'scan.xml'
    nmap.verbose        = true
    nmap.ports   = [20, 21, 22, 23, 25, 53, 69, 139, 137, 445, 80, 110, 443, 512, 522, 8080, 1080, 8443]
    nmap.targets = targets.to_s
  end
end

def display_results
  results = {}
  Nmap::XML.new('scan.xml') do |xml|
    xml.each_host do |host|
      results[host.ip] = host.ports.map do |port|
        { 'Port' => port.number, 'Protocol' => port.protocol, 'State' => port.state }
      end
    end
  end

  File.open('results.json', 'w') do |f|
    f.write(results.to_json)
  end

  puts 'Results saved to results.json'
end

puts 'This script will scan the range of IP addresses. Do you want to proceed? ((n)etwork/(p)ublic/(e)scape)'
answer = gets.chomp.downcase

if answer == 'network' || answer == 'n'
  puts 'Starting the scan...'
  targets = '192.168.1.*'
  scan_network(targets)
  puts 'Scan completed. Displaying results:'
  analyze_results
elsif answer == 'public' || answer == 'p'
  puts 'Starting the scan...'
  targets = get_public_ip
  scan_network(targets)
  puts 'Scan completed. Displaying results:'
  analyze_results
elsif answer == 'custom' || answer == 'c'
else
  puts 'Exiting...'
end

# runs inpect script
def analyze_results
  display_results
  system('ruby', './scripts/inspect.rb')
end