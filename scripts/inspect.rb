require 'nokogiri'

def parse_xml_to_html
  # Parse the XML file
  xml = File.read('scan.xml')
  doc = Nokogiri::XML(xml)

  # Start building the HTML structure
  builder = Nokogiri::HTML::Builder.new do |html|
    html.html {
      html.head {
        html.title "Nmap Scan Results"
        html.link(rel: 'stylesheet', href: 'styles.css')  # Linking to the external CSS file

        # JavaScript function to toggle dropdown visibility
        html.script %{
          function toggleDropdown(id) {
            var content = document.getElementById(id);
            content.style.display = content.style.display === 'none' ? 'block' : 'none';
          }
        }
      }
      html.body {
        html.h1 "Nmap Scan Results"
        
        closed_hosts = []

        # Iterate through each host in the XML to identify closed hosts first
        doc.xpath('//host').each do |host|
          if host.xpath('ports/port/state[@state="open"]').none? && host.xpath('ports/port/state[@state="filtered"]').none?
            closed_hosts << host
          end
        end

        # Create Closed dropdown if there are any closed hosts
        unless closed_hosts.empty?
          html.button(class: "dropdown-btn", onclick: "toggleDropdown('closedDropdown')") { html.text "Closed" }
          html.div(class: 'dropdown-content', id: "closedDropdown") {
            closed_hosts.each do |host|
              ip = host.at_xpath('address/@addr').value
              html.p { html.text "Host: #{ip}" }
            end
          }
        end

        # Iterate through each host in the XML for open and filtered hosts
        idx = 0
        doc.xpath('//host').each do |host|
          next if closed_hosts.include?(host)
          
          idx += 1
          ip = host.at_xpath('address/@addr').value

          # Determine host color based on port states
          host_state = if host.xpath('ports/port/state[@state="open"]').any?
                         'open-host'
                       elsif host.xpath('ports/port/state[@state="filtered"]').any?
                         'filtered-host'
                       else
                         ''
                       end

          html.button(class: "dropdown-btn #{host_state}", onclick: "toggleDropdown('dropdown#{idx}')") { html.text "Host: #{ip}" }
          html.div(class: 'dropdown-content', id: "dropdown#{idx}") {
            # Iterate through each port for the host
            host.xpath('ports/port').each do |port|
              port_id = port['portid']
              protocol = port['protocol']
              state = port.at_xpath('state/@state').value

              port_class = case state
                           when 'open'
                             'open-port'
                           when 'filtered'
                             'filtered-port'
                           else
                             ''
                           end

              html.p(class: port_class) {
                html.text "Port: #{port_id} (#{protocol}) - #{state.capitalize}"
              }
            end
          }
        end
      }
    }
  end

  # Write the HTML to a file
  File.open('scan.html', 'w') do |f|
    f.write(builder.to_html)
  end

  puts "XML has been successfully parsed into styled scan.html!"
  system("open scan.html") # open the HTML file in the default browser (works on macOS and some Linux systems)
end

parse_xml_to_html
