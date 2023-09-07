require 'socket'
require 'awesome_print'
require 'net/http'
require 'nmap/command'
require 'nmap/xml'

local_ip = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }
ap "Your local IP is: #{local_ip.ip_address if local_ip}"

def get_public_ip
  uri = URI('http://api.ipify.org')
  response = Net::HTTP.get(uri)
  response.strip
end

ap "Your public IP is: #{get_public_ip}"
ap '..................................................................'
ap '..................................................................'
ap '..................................................................'
ap 'scan ports?'

def scan_network(targets)
  ap "target: #{targets}"
  Nmap::Command.run do |nmap|
    nmap.connect_scan = true
    nmap.service_scan   = true
    nmap.output_xml     = 'scan.xml'
    nmap.verbose        = true
    nmap.ports   = [20, 21, 22, 23, 25, 80, 110, 443, 512, 522, 8080, 1080]
    nmap.targets = targets.to_s
  end
end

def display_results
  Nmap::XML.new('scan_results.xml') do |xml|
    xml.each_host do |host|
      puts "IP: #{host.ip}"
      host.each_port do |port|
        puts "  Port: #{port.number} (#{port.protocol}) - #{port.state}"
      end
    end
  end
end

# Ask the operator for confirmation
puts 'This script will scan the range of IP addresses. Do you want to proceed? (network/public/no)'
answer = gets.chomp.downcase

if answer == 'network'
  puts 'Starting the scan...'
  targets = '192.168.1.*'
  scan_network(targets)
  puts 'Scan completed. Displaying results:'
  display_results
elsif answer == 'public'
  puts 'Scan operation cancelled by user.'
  puts 'Starting the scan...'
  targets = get_public_ip
  scan_network(targets)
  puts 'Scan completed. Displaying results:'
  display_results
else
  'Exiting...'
end
