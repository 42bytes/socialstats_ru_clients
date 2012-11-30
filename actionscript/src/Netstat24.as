package {
import external_libs.json.JSON;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.TimerEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLVariables;

import flash.utils.Timer;

public class Netstat24 extends EventDispatcher {

  public static const IO_ERROR: String = 'netstat_io_error';

  private var _viewer_id: String;
  private var _app_id: String;
  private var _token: String;

  private var _flush_interval: int;
  private var _flush_size: int;

  private var _flush_timer: Timer;

  private var _global_options: Object = new Object();
  private var _buffer: Array;

  public function Netstat24(app_id: String, token: String, viewer_id: String,
                            flush_interval: Number = 1000, flush_size: Number = 10) {
    _app_id = app_id;
    _token = token;
    _viewer_id = viewer_id;
    
    _flush_interval = flush_interval;
    _flush_size = flush_size;
    _flush_timer = new Timer(_flush_interval);
    

    _global_options.onError = function (evt: Event) : void {
      dispatchEvent(new Event(IO_ERROR));
    };
    
    _global_options.onComplete = function (data: Object) : void {};

    _flush_timer.addEventListener(TimerEvent.TIMER, onBufferTimerElapsed);
  }
  

  // Track arbitrary events (button clicks, questions asked, etc.)
  //   
  // Examples: 
  //  trackEvent('greenButtonClick')
  public function trackEvent(eventName: String) : void {
    var data: Object = {
      method: 'track_event',
      event: eventName
    };

    enqueueRequest(data);
  }
  // Track arbitrary events (button clicks, flowers sold, questions asked, etc.)
  // Remember that value should belong to a smallish set of discrete values (up to 
  //   several dozens is ok). DO NOT pass an arbitrary number or otherwise unbounded value.
  //   
  // Examples: 
  //  trackEvent('greenButtonClick')
  //  trackEvent('soldFlower', 'rose')  
  
  public function trackValue(eventName: String, value: String) : void {
    var data: Object = {
      method: 'track_value',
      event: eventName,
      value: value
    };

    enqueueRequest(data);
  }
  

  // Track arbitrary numbers (XP gained, or whatever). For tracking revenue/payments,
  // there is special method, payment(amount)
  public function trackNumber(eventName: String, value: Number) : void {
    var data: Object = {
      method: 'track_number',
      event: eventName,
      value: value
    };

    enqueueRequest(data);
  }
  
  // Send as soon as you get user's information.
  // Without this data the system won't be able to filter your charts.
  // NOTE: gender should be either 'f' or 'm' (female and male, respectively).
  public function userData(gender: String, age: Number, friends: Number, appFriends: Number, level: Number) : void {
    var data: Object = {
      method: 'user_data',

      g: gender,
      a: age,
      nfr: friends,
      nafr: appFriends,
      lvl: level
    };

    enqueueRequest(data);
  }
  
  
  // Call on app startup
  public function visit(source: String = null): void {
    var data: Object = {
      method: 'visit',
      value: source
    };

    enqueueRequest(data);
  }
  
  // Call when user installs the app
  public function install(source: String = null): void {
    var data: Object = {
      method: 'install',
      value: source
    };

    enqueueRequest(data);
  }
  
  // Call when user makes a payment in the game
  public function revenue(amount: Number): void {
    var data: Object = {
      method: 'revenue', 
      value: amount
    };
    
    enqueueRequest(data);
  }
  
  // Call when you send an invite in the game
  public function inviteSent(): void {
    var data: Object = {
      method: 'invite_sent'
    };
    
    enqueueRequest(data);
  }
    
  
  
  
  // Don't wait for timer to tick, flush buffers and send data out immediately.
  public function flushBuffers() : void {
    _flushBuffer();
  }


  // PRIVATE API


  private function onBufferTimerElapsed(event: TimerEvent) : void {
    _flushBuffer();
  }

  private function _flushBuffer() : void {
    var req2: URLRequest = _getRequestObject2();
    req2.data['batch'] = JSON.encode(_buffer);
    _fireAndForget(req2);

    _buffer = [];
    _flush_timer.stop();
  }


  private function enqueueRequest(data: Object) : void {
    if (!_buffer) {
      _buffer = [];
    }

    _buffer.push(data);

    if (_buffer.length >= _flush_size) {
      _flushBuffer();
    } else {
      startTimer();
    }
  }

  private function startTimer() : void {
    if (!_flush_timer.running) {
      _flush_timer.start();
    }
  }

  private function _getRequestObject2(req_type: String = 'POST') : URLRequest {
      var params:URLVariables = new URLVariables();
      params['vid'] = _viewer_id;
      params['app_id'] = _app_id;
      params['access_token'] = _token;

      var COLLECTOR_URL: String = "http://collector.netstat24.com/api/v2";
      var req: URLRequest = new URLRequest(COLLECTOR_URL);

      req.method = req_type;
      req.data = params;
      return req;
  }

  private function _fireAndForget(request: URLRequest) : void {
    _sendRequest(request, {onComplete: do_nothing,
      onError: do_nothing});
  }

  private function _sendRequest(request: URLRequest, options: Object = null) : void {
    var loader: URLLoader = new URLLoader();

    loader.addEventListener(Event.COMPLETE,
            function(evt: Event) : void {
              var data: Object = decodeResponse(evt);

              if (options && options.onComplete)
                options.onComplete(data);
              else
                _global_options.onComplete(data);
            });

    loader.addEventListener(IOErrorEvent.IO_ERROR,
            function(evt: IOErrorEvent) : void {
              if (options && options.onError) {
                options.onError(evt)
              }
              else {
                dispatchEvent(new Event(IO_ERROR));
              }
            });

    try {
      loader.load(request);
    }
    catch (error: Error) {
      var handler: Function = options && options.onError ?
              options.onError:
              _global_options.onError;
      handler(error);
    }
  }

  private function decodeResponse(evt: Event) : Object {
    if (!evt || !evt.target)
      return null;

    try {
      var res: Object = JSON.decode(evt.target.data);
    }
    catch(e: Error) {
      res = {};
    }
    return res;
  }

  private function do_nothing(evt: Object = null) : void {

  }
}
}



