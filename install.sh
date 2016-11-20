#!/bin/bash
# 
# install stuff required for url-shorterner project to function
#
# @version @package_version@
# @author Michael A. Trimm
# @website https://github.com/michaeltrimm
#
#

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
WHITE='\033[1;33m'
LIGHTBLUE='\033[1;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m'

command -v git >/dev/null 2>&1 || { echo >&2 "Required package git not installed.  Aborting."; exit 1; }
command -v php >/dev/null 2>&1 || { echo >&2 "Required package php not installed.  Aborting."; exit 1; }
command -v mysql >/dev/null 2>&1 || { echo >&2 "Required package mysql not installed.  Aborting."; exit 1; }

printf "Installing required components for url-shortener...\n\n"

printf "${BLUE}Composer${NC}\n"
if [ ! -f "composer.phar" ]
then
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  if [ -a "composer-setup.php" ]
  then php composer-setup.php
  else exit;
  fi
  rm -f composer-setup.php
  if [ ! -a "composer.phar" ]
  then printf "${GREEN}✓${NC} Successfully installed composer\n"
  else printf "${RED}X${NC} Failed to install composer\n"; exit;
  fi
else
  printf "${GREEN}✓${NC} Already installed composer\n"
fi

printf "\n"


printf "${BLUE}Dependencies${NC}\n"
php composer.phar install
printf "${GREEN}✓${NC} Installed dependencies\n"

printf "\n"

printf "${BLUE}Configurations${NC}\n"
ENCRYPTION_KEY=""
CONFIGS_OK=0
DATABASE_HOST=""
DATABASE_NAME=""
DATABASE_USER=""
DATABASE_PASS=""
DOMAIN=""

function ask_domain {
  read -p "- URL Shortner Domain (omit http:// or https://): " DOMAIN
}

function ask_db_host {
  read -p "- Database host location [localhost]: " DATABASE_HOST
}

function ask_db_name {
  read -p "- Database name [urlshort_dev]: " DATABASE_NAME
}

function ask_db_user {
  read -p "- Username to access ${DATABASE_NAME}: " DATABASE_USER
}

function ask_db_pass {
  read -p "- ${DATABASE_USER}'s password: " DATABASE_PASS
}

function ask_configs {
  ask_domain
  if [ "${DOMAIN}" == "" ]
  then printf "${RED}You must supply a domain for this URL shortener installation.${NC}\n"; ask_domain
  fi
  printf "  Installing on ${GREEN}${DOMAIN}${NC}\n"
  
  ask_db_host
  if [ "${DATABASE_HOST}" == "" ]
  then DATABASE_HOST="localhost"
  fi
  printf "  Using ${GREEN}${DATABASE_HOST}${NC}\n"
  
  ask_db_name
  if [ "${DATABASE_NAME}" == "" ]
  then DATABASE_NAME="urlshort_dev"
  fi
  printf "  Using ${GREEN}${DATABASE_NAME}${NC}\n"
  
  ask_db_user
  if [ "${DATABASE_USER}" == "" ]
  then printf "  ${RED}You must supply a database username, use root if you are unsure.${NC}\n"; ask_db_user
  fi
  printf "  Using ${GREEN}${DATABASE_USER}${NC}\n"
  
  ask_db_pass
  if [ "${DATABASE_PASS}" == "" ]
  then printf "  ${RED}You must spply a database password, use root if you are unsure.${NC}\n"; ask_db_pass
  fi
}

function reask_pass {
  ask_db_pass
  check_configs
}

function write_configs {
  
  printf "${GREEN}✓${NC} Connected to MySQL Server\n"
  
  PHP_CONFIGS=" define('APP',1); include 'lib/encryption.php';"
  DB_HOST=$(php -r "${PHP_CONFIGS} print_r(Encryption::encrypt('${DATABASE_HOST}','${ENCRYPTION_KEY}'));")
  DB_NAME=$(php -r "${PHP_CONFIGS} print_r(Encryption::encrypt('${DATABASE_NAME}','${ENCRYPTION_KEY}'));")
  DB_USER=$(php -r "${PHP_CONFIGS} print_r(Encryption::encrypt('${DATABASE_USER}','${ENCRYPTION_KEY}'));")
  DB_PASS=$(php -r "${PHP_CONFIGS} print_r(Encryption::encrypt('${DATABASE_PASS}','${ENCRYPTION_KEY}'));")
  
  # Encrypt the data and store inside config.php
  read -r -d '' CONFIGS <<EOM
<?php
\$DB_HOST = "${DB_HOST}";
\$DB_NAME = "${DB_NAME}";
\$DB_USER = "${DB_USER}";
\$DB_PASS = "${DB_PASS}";
\$DOMAIN = "${DOMAIN}";

EOM

  echo "${CONFIGS}" > config.inc.php
  printf "${GREEN}✓${NC} Installed configs to config.inc.php\n"
  
  echo ${ENCRYPTION_KEY} > .key
  printf "${GREEN}✓${NC} Installed encryption key to .key\n"
}

function check_configs {
  ERROR=0
  while ! mysql -h $DATABASE_HOST -u $DATABASE_USER -p$DATABASE_PASS -e ";" ; do
    ERROR=1
    printf "${RED}Invalid password provided!${NC}\n"
    read -p "Do you want to retry the password or the entire config? [password|config]: " redo_choice
    if [ "${redo_choice}" == "password" ]
    then reask_pass; break;
    else ask_configs
    fi
  done
  if [ "${ERROR}" == "0" ]
  then
    write_configs
  fi
}

function install_sql {

  if [ "${DATABASE_NAME}" == "" ]
  then
    
    # script is running from an already installed instance, didn't collect db credentials here...
    printf "${GREEN}✓${NC} Already installed database and tables inside of MySQL server!"
    
  else

    CHECK="USE ${DATABASE_NAME}; SHOW TABLES;"
    CHECK_INSTALLED=$(mysql -h ${DATABASE_HOST} -u ${DATABASE_USER} -p${DATABASE_PASS} -e "${CMD}" | grep entry_click)
    if [ "entry_click" == "${CHECK_INSTALLED}" ]
    then 
      printf "${GREEN}✓${NC} Already installed database and tables inside of MySQL server!"
    
    else
      read -r -d '' INSTALL_TABLES_SQL <<EOM
USE ${DATABASE_NAME};
CREATE TABLE IF NOT EXISTS entry (
  id int(11) NOT NULL AUTO_INCREMENT,
  code varchar(45) NOT NULL,
  url varchar(2048) NOT NULL,
  clicks int(11) DEFAULT '0',
  created_on datetime DEFAULT NULL,
  last_accessed_on datetime DEFAULT NULL,
  enabled tinyint(4) DEFAULT NULL,
  ip varchar(45) DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY code_UNIQUE (code),
  KEY code_url (code,url(767)),
  KEY code_ip (code,ip),
  KEY code_clicks (code,clicks),
  KEY url_clicks (url(767),clicks),
  KEY id (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE IF NOT EXISTS entry_click (
  id int(11) NOT NULL,
  entry_id int(11) DEFAULT NULL,
  date_clicked datetime DEFAULT NULL,
  ip_address varchar(45) DEFAULT NULL,
  user_agent varchar(255) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY entry_id (entry_id),
  KEY ip_agent (ip_address,user_agent)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
EOM
  
      # if we can create the database...
      CMD="CREATE DATABASE IF NOT EXISTS ${DATABASE_NAME}; SHOW DATABASES;"
      CREATE_DB=$(mysql -h ${DATABASE_HOST} -u ${DATABASE_USER} -p${DATABASE_PASS} -e "${CMD}" | grep ${DATABASE_NAME})
      if [ "${CREATE_DB}" == "${DATABASE_NAME}" ]
      then
        # success
        mysql -h ${DATABASE_HOST} -u ${DATABASE_USER} -p${DATABASE_PASS} -e "${INSTALL_TABLES_SQL}"
        printf "${GREEN}✓${NC} Installed tables inside of your MySQL server\n"
      else
        # can't create database, so write the install to a SQL file and output the instructions
        read -r -d '' DB_INSTALL <<EOM
CREATE DATABASE IF NOT EXISTS ${DATABASE_NAME};
CREATE USER IF NOT EXISTS '${DATABASE_USER}'@'${DATABASE_HOST}' IDENTIFIED BY '${DATABASE_PASS}';
GRANT ALL ON ${DATABASE_NAME}.* TO '${DATABASE_USER}'@'${DATABASE_HOST}' IDENTIFIED BY '${DATABASE_PASS}';
FLUSH PRIVILEGES;

${INSTALL_TABLES_SQL}

EOM
        echo "${DB_INSTALL}" > ./install-url-shortener.sql
        printf "${GREEN}✓${NC} Generated MySQL install script ${RED}!requires you to run (as a mysql administrative user) "
        printf "${RED}mysql -h ${DATABASE_HOST} -u administrator -p < install-url-shortener.sql${NC}\n"
    
      fi
    
    fi
  
  fi
  
}

if [ ! -f ".key" ]
then 
  ENCRYPTION_KEY=$(php -r "require 'vendor/autoload.php'; echo substr(bin2hex(random_bytes(32)),0,32);")
  printf "Random password generated ${RED}${ENCRYPTION_KEY}${NC} which will be used for encryption\n"
  printf "${GREEN}✓${NC} Generated secure encryption key\n"
  
  ask_configs
  
  check_configs
  
else
  printf "${GREEN}✓${NC} Already installed encryption key\n"
fi

printf "\n"

install_sql

echo $NOW > .installed

printf "${GREEN}DONE!\n\n";