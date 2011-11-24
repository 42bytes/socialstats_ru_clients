class SSTracker
  constructor: (@api_id, @api_key, @viewer_id) ->

  trackEvent: (name, value = null) ->
    data = meth : 'track_event', act : name
    if value
      data.val = value
      data.agg = 'count'
    this.send_request data

  trackNumber: (name, value) ->
    data =
      meth : 'track_event'
      act : name,
      val : value,
      agg : 'number'
    this.send_request data

  sendUserInfo: (gender, age, nFriends, nAppFriends) ->
    data =
      meth : 'send_user_info',
      g : gender,
      a : age,
      nfr : nFriends,
      nafr : nAppFriends
    this.send_request data

  send_request: (data) ->
    params =
      vid: @viewer_id,
      rid: Math.random().toString(),
      batch: JSON.stringify [data]

    url = "http://socialstats.ru/api/v2/#{@api_id}/#{@api_key}/post_batch"
    $.post url, params
