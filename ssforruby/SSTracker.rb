require 'uri'
require 'json'

class SSTracker
  def initialize swf_id, swf_key
    @swf_id = swf_id
    @swf_key = swf_key
  end

  def track_event name, value = nil
    parms = {:act => name}

    if value
      parms[:val] = value
      parms[:agg] = 'count'
    end

    send_secure_request 'track_event', parms
  end


  private
  def send_secure_request method_name, additional_params = {}
    parms = {:swf_id => @swf_id,
             :vid => 'server',
             :rid => rand}.merge(additional_params)
    parms[:sig] = get_signature(parms)
    url = "http://socialstats.ru/flash/#{method_name}"
    JSON.parse(Net::HTTP.post_form(URI.parse(url), parms.stringify_keys).body)
  end


  def get_signature parameters = {}
    str = "server"
    parameters.stringify_keys.sort.each do |k, v|
      str << "#{k}=#{v}"
    end
    str << @swf_key

    Digest::MD5.hexdigest(str)
  end
end
