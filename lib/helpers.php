<?php 
if(!defined("APP")) die("HTTP 404 Error - Not Found");

function randomString($length = 6) {
  $str = "";
  $characters = array_merge(range('A','Z'), range('a','z'), range('0','9'));
  $max = count($characters) - 1;
  for ($i = 0; $i < $length; $i++) {
    $rand = mt_rand(0, $max);
    $str .= $characters[$rand];
  }
  return $str;
}

function findCode() {
  global $pdo;
  $code = randomString(6);

  try {
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM entry WHERE code = :code LIMIT 1");
    $stmt->bindParam(':code',$code);
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    $count = is_null($result) ? 0 : intval($result['count']);
  } catch(PDOException $e){
    error_log(print_r($e,true));
  } catch(Exception $e){
    error_log(print_r($e,true));
  }

  if($count == 1) {
    return findCode();
  } else {
    return $code;
  }
}

function checkDbForUrl($url){
  global $pdo;
  $found = false;

  try {
    $stmt = $pdo->prepare('SELECT `code`, `url` FROM `entry` WHERE `url` = :url AND `enabled` = 1 LIMIT 1');
    $stmt->execute([
      "url" => $url
    ]);
    $found = $stmt->fetch(PDO::FETCH_ASSOC);
  } catch(PDOException $e){
    error_log(print_r($e,true));
  } catch(Exception $e){
    error_log(print_r($e,true));
  }
  
  if(empty($found) or $found == false){
    return null;
  } else {
    return ["code" => $found['code'], "url" => $found['url']];
  }
}

function checkDbForCode($code){
  global $pdo;
  $found = false;

  try {
    $stmt = $pdo->prepare('SELECT `code`, `url` FROM `entry` WHERE `code` = :code AND `enabled` = 1 LIMIT 1');
    $stmt->execute([
      "code" => $code
    ]);
    $found = $stmt->fetch(PDO::FETCH_ASSOC);
  } catch(PDOException $e){
    error_log(print_r($e,true));
  } catch(Exception $e){
    error_log(print_r($e,true));
  }

  if(empty($found) or $found == false){
    return null;
  } else {
    return ["code" => $found['code'], "url" => $found['url']];
  }
}