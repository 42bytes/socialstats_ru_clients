class SSTracker
  constructor: (@app_id, @app_key, @viewer_id) ->

  begin: () ->
    @batch = []
    this

  commit: () ->
    if @batch
      this.send_batch @batch
    @batch = null

  trackEvent: (name, value = null) ->
    data = meth : 'track_event', act : name
    if value || value == 0
      data.val = value
      data.agg = 'count'

    this.send_request data
    this

  trackNumber: (name, value) ->
    data =
      meth : 'track_event'
      act : name
      val : value
      agg : 'number'

    this.send_request data
    this

  sendUserInfo: (gender, age, nFriends, nAppFriends) ->
    data = 
      meth : 'send_user_info'
      g : gender
      a : age
      nfr : nFriends
      nafr : nAppFriends

    this.send_request data
    this

  send_request: (data) ->
    if @batch
      @batch.push data
    else
      this.send_batch [data]

  send_batch: (data) ->
    params =
      vid: @viewer_id
      rid: Math.random().toString()
      batch: JSON.stringify data
      app_id: @app_id
      app_key: @app_key

    url = "http://api.socialstats.ru/api/v2/batch"
    $.post url, params
