# URL Shortener

This PHP Slim application will create a URL shortener that allows anyone to input a long URL and receive a generated URL that is `domain.io/i/uniqueCode` (assuming `domain.io` is your domain of course).

## Installation

The application requires you to install some stuff first. Since this application is GPLv3, the dependencies cannot be
shipped with this application. You must "acquire them" on your own, by using the installer.

### Requirements

This application requires:

1. `apache` or `httpd` (either `2.2.x` or `2.4.x`)
2. `php` (minimum `v5.6`, recommended `v7.0`)
3. `mysql` (via `mysql-client`) (minimum `5.1.x` recommended `5.5.x`)
4. `php5-mcrypt` or `php7-mcrypt`

You must also have access to the following: 

1. A command line interface with `bash` capabilities (`sudo` or `root` is not required)
2. A LAMP stack (macOS = MAMP, Windows = WAMP)
3. MySQL administrative privileges

### Installer

1. Install composer

    1. The application installs composer by downloading `https://getcomposer.org/installer` to `setup-composer.php`.
    
    2. PHP executes `setup-composer.php` which checks dependencies and downloads a file called `composer.phar`

2. Compose Packages Are Installed

    1. The installer reads the `composer.json` file and downloads each of the dependencies into the `vendor/` directory

3. The installer generates the configuration

    1. A randomly generated password using PHP7's `random_bytes()` function (or `random_compact` for PHP 5.6+)
    
    2. A domain is required - enter the name of your shortened domain, for dev, use something like: `myshort.local`
    
    3. You will need to specify the `database host`, `database name`, `database username` and `database password`.
    
    4. Saving the configuration: 
    
        iv.1. If the installer is able to access the MySQL server, the host, database, username, and password are encrypted with the randomly generated password (from 3.i) and stored as a `base64` hash inside the `config.inc.php` file. 
        
        iv.2. If the installer cannot access then the installation script will keep prompting for a combination that works. 
    
    5. SQL table/database installation 
    
        v.1. If the installer is able to create the database, it will attempt to install the necessary tables
        
        v.2. If the installer is unable to create the database, it will generate a file called `install-url-shortener.sql`
        
        v.3. If `install-url-shortener.sql` is created, you must, with a privileged mysql user run the following command
        
            
            mysql -u root -p < install-url-shortener.sql
            

## Disclaimer

This software is provided "as-is" and comes with absolutely no warranty or guarantee. Please use at your own discretion. No contributor to this project shall be responsible for any issues caused as a result of executing this software. That being said, the software is fully open-source, so have at it... look it over, understand it, and determine on your own merits whether or not you should use it.
