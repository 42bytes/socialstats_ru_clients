<?php
/**
 * Class to simplify using of SocialStats API.
 *
 *
 * Changelog
 * 1.0
 * (i) Release
 *
 *
 * @author Denis Peshekhonov
 * @copyright © 2011 Denis Peshekhonov
 * @version 1.0
 * @license http://www.gnu.org/licenses/lgpl.html GNU Lesser General Public License
 */
class SSTracker
{

    // a unique swf identifier for specific application
    private $swf_id;

    // secret key you can get on SocialStats admin panel
    private $swf_key;
	
	// a unique user identifier in social network
	private $viewer_id;

    //
    //Create and initialize object.
    //
    public function __construct($swf_id, $swf_key, $viewer_id = "server")
    {
        $this->swf_id = $swf_id;
        $this->swf_key = $swf_key;
	    $this->viewer_id = $viewer_id;	
    }

    //
    //Tracking event
    //
    public function trackEvent($name, $value = NULL)
    {
        $params = array("act" => $name);

        if ($value) {
            $params["val"] = $value;
            $params["agg"] = "count";
        }

        return $this->sendSecureRequest("track_event", $params);
    }
    
    //
    // Track information about user
    //
    public function sendUserInfo($gender, $age, $nFriends, $nAppFriends) 
    {
        $params = array("g" => $gender,
            "a" => $age,
            "nfr" => $nFriends,
            "nafr" => $nAppFriends
        );
        
        return $this->sendSecureRequest("user_data", $params);
    }

    //
    //Send request to SocialStats server and get answer.
    //
    private function sendSecureRequest($methodName, $additionalParams = array())
    {
        $params = array(
            "app_id" => $this->swf_id,
            "app_key" => $this->swf_key,
            "vid" => $this->viewer_id,
            "rid" => rand(),
            "method" => $methodName
        );

        $params = array_merge($params, $additionalParams);

        $url = "http://api.socialstats.ru/api/v2";

        //send request using POST method
        $curl_handle = curl_init();
        curl_setopt_array(
            $curl_handle,
            array(
                 CURLOPT_URL => $url,
                 CURLOPT_POST => true,
                 CURLOPT_POSTFIELDS => $params,
                 CURLOPT_RETURNTRANSFER => true
            )
        );
        $answer = curl_exec($curl_handle);
        curl_close($curl_handle);
        //

        return json_decode($answer);
    }
}

?>