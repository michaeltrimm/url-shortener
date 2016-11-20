<?php
if(!defined("APP")) die("HTTP 404 Error - Not Found");
class Encryption {
  public static function encrypt($str, $key){
    $block = mcrypt_get_block_size(MCRYPT_RIJNDAEL_128, 'ecb');
    $pad = $block - (strlen($str) % $block);
    $str .= str_repeat(chr($pad), $pad);
    return base64_encode(mcrypt_encrypt(MCRYPT_RIJNDAEL_128, $key, $str, MCRYPT_MODE_ECB));
  }
  public static function decrypt($str, $key){
    $str = base64_decode($str);
    $str = mcrypt_decrypt(MCRYPT_RIJNDAEL_128, $key, $str, MCRYPT_MODE_ECB);
    $pad = ord($str[($len = strlen($str)) - 1]);
    return substr($str, 0, strlen($str) - $pad);
  }
}