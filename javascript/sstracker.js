// This is a compiled version of CoffeeScript source.

window.SSTracker = (function() {

  function SSTracker(app_id, app_key, viewer_id) {
    this.app_id = app_id;
    this.app_key = app_key;
    this.viewer_id = viewer_id;
  }

  SSTracker.prototype.begin = function() {
    this.batch = [];
    return this;
  };

  SSTracker.prototype.commit = function() {
    if (this.batch) this.send_batch(this.batch);
    return this.batch = null;
  };

  SSTracker.prototype.trackEvent = function(name, value) {
    var data;
    if (value == null) value = null;
    data = {
      meth: 'track_event',
      act: name
    };
    if (value || value === 0) {
      data.val = value;
      data.agg = 'count';
    }
    this.send_request(data);
    return this;
  };

  SSTracker.prototype.trackNumber = function(name, value) {
    var data;
    data = {
      meth: 'track_event',
      act: name,
      val: value,
      agg: 'number'
    };
    this.send_request(data);
    return this;
  };

  SSTracker.prototype.sendUserInfo = function(gender, age, nFriends, nAppFriends) {
    var data;
    data = {
      meth: 'send_user_info',
      g: gender,
      a: age,
      nfr: nFriends,
      nafr: nAppFriends
    };
    this.send_request(data);
    return this;
  };

  SSTracker.prototype.send_request = function(data) {
    if (this.batch) {
      return this.batch.push(data);
    } else {
      return this.send_batch([data]);
    }
  };

  SSTracker.prototype.send_batch = function(data) {
    var params, url;
    params = {
      vid: this.viewer_id,
      rid: Math.random().toString(),
      batch: JSON.stringify(data),
      app_id: this.app_id,
      app_key: this.app_key
    };
    url = "http://api.socialstats.ru/api/v2/batch";
    return $.post(url, params);
  };

  return SSTracker;

})();