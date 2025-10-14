<?php

use GuzzleHttp\Client;
use Illuminate\Support\Facades\Log;

if(!function_exists('jsonRpcRequest')){
    function jsonRpcRequest($url, $payload){
    
        try {

            $client = new \GuzzleHttp\Client([
                'verify' => false,
                'headers' => [
                    'Content-Type' => 'application/json',
                    'Accept-Encoding' => 'gzip, deflate, br'
                ],
                'timeout' => 30,
                'connect_timeout' => 10,
            ]);
            
            $response = $client->post($url, [
                'body' => json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
                'decode_content' => true,

            ]);

            $rawBody = (string) $response->getBody();

            $cleanBody = trim($rawBody);
            $lastBrace = strrpos($cleanBody, '}');
            if ($lastBrace !== false) {
                $cleanBody = substr($cleanBody, 0, $lastBrace + 1);
            }

            $decoded = json_decode($cleanBody, true);

            if(json_last_error() !== JSON_ERROR_NONE){
                Log::error('X JSON_RPC Invalid JSON Response', [
                    'url' => $url,
                    'error' => json_last_error_msg(),
                    'raw' => substr($cleanBody, -500),
                ]);
                return ['error' => 'Malformed JSON response'];
            }

            return $decoded;

        } catch (\GuzzleHttp\Exception\RequestException $e) {
            // ✅ More specific catch for network errors
            Log::error('X JSON_RPC Network Error', [
                'url' => $url,
                'payload' => $payload,
                'error' => $e->getMessage(),
                'code' => $e->getCode(),
            ]);
            return ['error' => 'Network error'];
        } catch (\Exception $e) {
            Log::error('X JSON_RPC Request Failed', [
                'url' => $url,
                'payload' => $payload,
                'error' => $e->getMessage(),
            ]);
            return ['error' => 'Unexpected error'];
        }

    }
}