#/usr/bin/env ruby

require 'net/https'

path = File.expand_path('~/screensaver_tracker_pushover.txt')
exit 0 unless File.exist?(path)
user = IO.read(path).chomp.strip
exit 1 unless user.length > 0
url = URI.parse('https://api.pushover.net/1/messages.json')
req = Net::HTTP::Post.new(url.path)
req.set_form_data({
                      :token   => 'a2spq8JtjUp7fupRwYFPLDjynWr3mT',
                      :user    => user,
                      :message => ARGV[1],
                      :title   => ARGV[0]
                  })
res             = Net::HTTP.new(url.host, url.port)
res.use_ssl     = true
res.verify_mode = OpenSSL::SSL::VERIFY_PEER
res.start { |http| http.request(req) }