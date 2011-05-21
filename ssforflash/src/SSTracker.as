package {
import external_libs.MD5;
import external_libs.json.JSON;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.TimerEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLVariables;

import flash.utils.Timer;

import org.osmf.events.TimeEvent;

public class SSTracker extends EventDispatcher {
    // events
    public static const ERROR:String = 'sstracker_request_error';
    public static const IO_ERROR:String = 'io_error';

    public static const INITIALIZED : String = 'sstracker_initialized';

    private const SSTRACKER_URL:String = "http://socialstats.ru/flash/";

    private var _viewer_id:String;
    private var _swf_id:String;
    private var _api_key:String;
    private var _sid : String;

    public static var FLUSH_INTERVAL : int = 10000;
    public static var FLUSH_CHANGES : int = 10;

    private var _timer:Timer = new Timer(FLUSH_INTERVAL);

    private var _global_options:Object = new Object();
    private var _buffer : Array;

    public function SSTracker(swf_id:String, api_key:String, viewer_id:String) {
        _swf_id = swf_id;
        _api_key = api_key;
        _viewer_id = viewer_id;

        _global_options.onError = function (evt:Event):void {
            dispatchEvent(new Event(IO_ERROR));
        };
        _global_options.onComplete = function (data:Object):void {
        };

        _timer.addEventListener(TimerEvent.TIMER, onBufferTimerElapsed);
    }

    private function onBufferTimerElapsed(event : TimerEvent) : void {
        _flushBuffer();
    }

    public function flushBuffers() : void {
        _flushBuffer();
    }

    private function _flushBuffer() : void {
        var req : URLRequest = _getRequestObject('post_batch', 'POST');
        req.data['batch'] = JSON.encode(_buffer);
        _fireAndForget(req);

        _buffer = [];
        _timer.stop();
    }

    public function init() : void {
        var req:URLRequest = _getRequestObject('init', 'POST');

        _sendRequest2(req, null, function(data : Object) : void {
            if(data.ok == 'ok' && data.sid) {
                _sid = data.sid;
                dispatchEvent(new Event(INITIALIZED));
            } else {
                dispatchEvent(new Event(ERROR));
            }
        });
    }

    public function trackEvent(eventName:String, value:String = null):void {
        var data : Object = {
            meth : 'track_event',
            act : eventName
        };
        if(value) {
            data.val = value;
            data.agg = 'count';
        }

        enqueueRequest(data);
    }

    public function trackNumber(eventName:String, value:Number):void {
        var req:URLRequest = _getRequestObject('track_event', 'POST');
        var data : Object = {
            meth : 'track_event',
            act : eventName,
            val : value,
            agg : 'number'
        };

        enqueueRequest(data);
    }

    private function enqueueRequest(data : Object) : void {
        if(!_buffer) {
            _buffer = [];
        }

        _buffer.push(data);

        if(_buffer.length >= FLUSH_CHANGES) {
            _flushBuffer();
        } else {
            startTimer();
        }
    }

    private function startTimer() : void {
        if(!_timer.running) {
            _timer.start();
        }
    }

    private function _getRequestObject(method_name:String, req_type:String = 'GET'):URLRequest {
        var req:URLRequest = new URLRequest(SSTRACKER_URL + method_name);
        req.method = req_type;
        var params:URLVariables = new URLVariables();
        params['vid'] = _viewer_id;
        params['swf_id'] = _swf_id;
        params['sid'] = _sid;
        params['rid'] = Math.random().toString();

        req.data = params;
        return req;
    }

    private function _sendRequest2(request:URLRequest, options:Object = null, success_handler:Function = null):void {
        if (success_handler == null)
            success_handler = do_nothing;

        _sendRequest(request, {onComplete : options && options.onComplete ? options.onComplete : success_handler});
    }

    private function _fireAndForget(request:URLRequest):void {
        _sendRequest(request, {onComplete : do_nothing_with_evt,
            onError : do_nothing_with_evt});
    }

    private function _sendRequest(request:URLRequest, options:Object = null):void {
        var loader:URLLoader = new URLLoader();

        loader.addEventListener(Event.COMPLETE,
                function(evt:Event):void {
                    var data:Object = decodeResponse(evt);

                    if (options && options.onComplete)
                        options.onComplete(data);
                    else
                        _global_options.onComplete(data);
                });

        request.data['sig'] = _generate_signature_my(request.data);

        loader.addEventListener(IOErrorEvent.IO_ERROR,
                function(evt:IOErrorEvent):void {
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
        catch (error:Error) {
            var handler:Function = options && options.onError ?
                    options.onError :
                    _global_options.onError;
            handler(error);
        }
    }

    private function decodeResponse(evt:Event):Object {
        if (!evt || !evt.target)
            return null;

        try {
            var res:Object = JSON.decode(evt.target.data);
        }
        catch(e:Error) {
            res = {};
        }
        return res;
    }

    private function _generate_signature_my(request_params:Object):String {
        var signature:String = "";
        var sorted_array:Array = new Array();
        for (var key:* in request_params) {
            if(key != 'sig') {
                sorted_array.push(key + "=" + request_params[key]);
            }
        }
        sorted_array.sort();

        // Note: make sure that the signature parameter is not already included in
        //       request_params array.
        for (key in sorted_array) {
            signature += sorted_array[key];
        }
        signature = _viewer_id + signature + _api_key;
        return MD5.encrypt(signature);
    }

    private function do_nothing():void {

    }

    private function do_nothing_with_evt(evt:Object):void {

    }

}
}



