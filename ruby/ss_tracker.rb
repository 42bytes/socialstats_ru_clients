require 'uri'
require 'json'

class SSTracker
  attr_accessor :vid

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
             :val => value,
             :agg => 'number'}

    send_secure_request 'track_event', parms
  end

  def send_user_info gender, age, n_friends, n_app_friends
    parms = {:g => gender,
             :a => age,
             :nfr => n_friends,
             :nafr => n_app_friends}

    send_secure_request 'user_data', parms
  end

  private
  def send_secure_request method_name, additional_params = {}
    parms = {:app_id => @swf_id,
             :app_key => @swf_key,
             :vid => vid || 'server',
             :rid => rand}.merge(additional_params)

    url = "http://api.socialstats.ru/api/v2"
    JSON.parse(Net::HTTP.post_form(URI.parse(url), parms.stringify_keys).body)
  end
end