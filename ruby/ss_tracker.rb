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
  
  def track_number name, value
    parms = {:act => name,
      :val = value,
      :agg => 'number'}
    
    send_secure_request 'track_event', parms
  end

  private
  def send_secure_request method_name, additional_params = {}
    parms = {:app_id => @swf_id,
             :app_key => @swf_key,
             :vid => 'server',
             :rid => rand}.merge(additional_params)
             
    url = "http://api.socialstats.ru/api/v2"
    JSON.parse(Net::HTTP.post_form(URI.parse(url), parms.stringify_keys).body)
  end
end
