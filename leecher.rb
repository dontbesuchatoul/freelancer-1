# encoding: utf-8
require 'open-uri'
require 'pp'
require 'nokogiri'

i = 0
page_size = 10
puts "CompanyName,Phone,Email,Website,Street,City,Province,Postal Code,Country,Badges,CitrixRelationship"

the_end = false
while ! the_end
  url = "http://www.citrix.com/buy/partnerlocator/results.nextpage.html?countryCode=CA&offset=#{i}"
  doc = Nokogiri::HTML(open("#{url}"))
  break if doc.text.empty? || i > 10000

  doc.css('#pl-results-company').each do |item|
    companyName = item.at('.partner-header a').text
    badges = item.css('.pl-results-overview>strong').map { |i| i.text.gsub(/[\t\n\r]/, '') }
    phone = item.css('div[1]/div[3]/text()').text.gsub(/[\t\n\r]/, '')
    if item.css('.pl-email').any?
      email = item.css('.pl-results-contact > div:nth-child(5) > pre > a').text
      website = if item.css('.pl-website').any? 
        item.css('div[1]/div[3]/div[7] a').text
      else
        ""
      end
    else
      email = ""
      website = if item.css('.pl-website').any? 
        item.css('.pl-results-contact > div:nth-child(5) > pre > a').text
      else
        ""
      end
    end
    url_address = item.css('.pl-results-contact:last pre a').last.attributes['href'].text.gsub(/\n/, ' ')
    address = /.*q=(.*)/.match(url_address)[1].split(',')
    postalCode = address.pop
    country = address.pop
    province = address.pop
    city = address.pop
    street = address.join(',')

    # relationship
    r_values = item.css(".stats > div")[0].css('strong').map { |e| e.text.strip }
    r_titles = []
    item.css(".stats > div")[1].children.each do |e|
      next if e.name == "br"
      text = e.text.strip
      r_titles << text unless text.empty?
    end
    relationship = []
    r_values.each_with_index {|v, k| relationship << "#{r_titles[k]}: #{v}"}

    puts "#{companyName};#{phone};#{email};#{website};#{street};#{city};#{province};#{postalCode};#{country};#{badges.join(', ')};#{relationship.join(', ')}".gsub('"', '""').split(";").map {|i| "\"#{i}\"" }.join(',') + "\n"
  end

  i += 10
end