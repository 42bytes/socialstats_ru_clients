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

    //
    //Create and initialize object.
    //
    public function __construct($swf_id, $swf_key)
    {
        $this->swf_id = $swf_id;
        $this->swf_key = $swf_key;
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

        return $this->sendSecureRequest('track_event', $params);
    }

    //
    //Send request to SocialStats server and get answer.
    //
    private function sendSecureRequest($methodName, $additionalParams = array())
    {
        $params = array(
            "swf_id" => $this->swf_id,
            "vid" => "server",
            "rid" => rand()
        );

        $params = array_merge($params, $additionalParams);

        $params["sig"] = $this->getSignature($params);
        $url = "http://socialstats.ru/flash/" . $methodName;

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

    //
    //Calculate signature
    //
    private function getSignature($params)
    {
        ksort($params);

        $sig = 'server';
        foreach ($params as $key => $value) {
            $sig .= "$key=$value";
        }
        $sig .= $this->swf_key;

        return md5($sig);
    }
}

?>
