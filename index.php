<?php 
session_start();
define("APP",1);

error_reporting(E_ALL);
ini_alter("display_errors","on");

if(!file_exists(__DIR__."/.installed") || !file_exists(__DIR__."/config.inc.php")){
  header("Location: install.html");
  die;
}

require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/lib/encryption.php';
require_once __DIR__ . '/lib/helpers.php';

global $DOMAIN;

$key = file_get_contents(__DIR__."/.key");
$key = substr($key,0,32);
include __DIR__."/config.inc.php";

# PDO
$host = strval("mysql:host=".Encryption::decrypt($DB_HOST,$key).";dbname=".Encryption::decrypt($DB_NAME,$key));
$user = strval(Encryption::decrypt($DB_USER,$key));
$pass = strval(Encryption::decrypt($DB_PASS,$key));
$pdo = new PDO($host, $user, $pass);

# Protect from accessing later, should only use the $pdo object
$key = null;
$host = null;
$user = null;
$pass = null;
$DB_HOST = null;
$DB_NAME = null;
$DB_USER = null;
$DB_PASS = null;
unset($key);
unset($host);
unset($user);
unset($pass);
unset($DB_HOST);
unset($DB_NAME);
unset($DB_USER);
unset($DB_PASS);

# APP
$app = new \Slim\App([
  "settings"  => [
     "determineRouteBeforeAppMiddleware" => true,
     'displayErrorDetails' => true,
  ]
]);

# CORS
$app->options('/{routes:.+}', function ($request, $response, $args) {
  return $response;
});

$app->add(function ($req, $res, $next) {
  $response = $next($req, $res);
  global $DOMAIN;
  return $response
          ->withHeader('Access-Control-Allow-Origin', 'https://'.$DOMAIN)
          ->withHeader('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type, Accept, Origin, Authorization')
          ->withHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
});

# TEMPLATES
$container = $app->getContainer();

// Register component on container
$container['view'] = function ($container) {
    $view = new \Slim\Views\Twig('templates', [
        'cache' => 'templates/cache'
    ]);
    $view->addExtension(
      new Slim\Views\TwigExtension(
        $container['router'], 
        $container['request']->getUri()
      )
    );
    return $view;
};

$container['notFoundHandler'] = function ($c) {
    return function ($request, $response) use ($c) {
        return $c['view']->render($response, "404.twig");
    };
};
$container['notAllowedHandler'] = function ($c) {
    return function ($request, $response, $methods) use ($c) {
        return $c['view']->render($response, "404.twig");;
    };
};

# csrf
$container['csrf'] = function ($c) {
    return new \Slim\Csrf\Guard;
};

$app->get('/', function($request, $response, $args){
  $csfr_nameKey = $this->csrf->getTokenNameKey();
  $csfr_valueKey = $this->csrf->getTokenValueKey();
  $csfr_name = $request->getAttribute($csfr_nameKey);
  $csfr_value = $request->getAttribute($csfr_valueKey);
  return $this->view->render($response, 'index.twig', [
      "csfr_nameKey" => $csfr_nameKey,
      "csfr_valueKey" => $csfr_valueKey,
      "csfr_name" => $csfr_name,
      "csfr_value" => $csfr_value
  ]);
})->add($container->get('csrf'));

$app->post('/new', function($request, $response, $args) use ($pdo) {
  $data = $request->getParsedBody();
  if(!isset($data['url']) || strlen($data['url']) <= 5){
    return $this->view->render($response, 'nourl.twig');
  }

  $url = base64_encode(filter_var($data['url'], FILTER_SANITIZE_URL));
  $code = findCode();
  $results = checkDbForUrl($url);
  $found = false;

  if(is_null($results)){
    $stmt = $pdo->prepare("INSERT INTO `entry` (`code`, `url`, `created_on`, `enabled`, `ip`) VALUES (:code, :url, :created_on, :enabled, :ip);");
    $stmt->bindParam(':code', $code);
    $stmt->bindParam(':url', $url);
    $enabled = 1;
    $stmt->bindParam(':enabled', $enabled);
    $date = date("Y-m-d H:i:s");
    $stmt->bindParam(':created_on', $date);
    $stmt->bindParam(':ip', $ip);
    $ip = $_SERVER['REMOTE_ADDR'];
    $stmt->execute();
  } else {
    $found = true;
    $url = $results['url'];
    $code = $results['code'];
  }

  $s_for_https = $_SERVER['SERVER_PORT'] == 443 ? "s" : "";
  $domain = $_SERVER['HTTP_HOST'];
  return $this->view->render($response, 'view.twig', [
      'code' => $code,
      'url' => base64_decode($url),
      'found' => $found,
      "domain" => $domain,
      "s_for_https" => $s_for_https
  ]);
})->add($container->get('csrf'));


$app->get('/i/{code:[A-Za-z0-9]+}', function ($request, $response, $args) {
  $code = $args['code'];
  $results = checkDbForCode($code);
  if(is_null($results)){
    return $this->view->render($response, 'error.twig');
  } else {
    header("Location: ". base64_decode($results['url']));
  }
  return $response->withStatus(302);
});

$app->post('/i/{code:[A-Za-z0-9]+}', function ($request, $response, $args) {
  $code = $args['code'];
  $results = checkDbForCode($code);
  $s_for_https = $_SERVER['SERVER_PORT'] == 443 ? "s" : "";
  $domain = $_SERVER['HTTP_HOST'];
  return $this->view->render($response, 'view.twig', [
      'code' => $code,
      'url' => base64_decode($results['url']),
      "domain" => $domain,
      "s_for_https" => $s_for_https
  ]);
});

// Run application
$app->run();