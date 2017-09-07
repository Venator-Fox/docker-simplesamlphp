#!/usr/bin/with-contenv /bin/bash

#Default runtime variables if none are supplied at Docker container creation

DOCKER_REDIRECTLOGS=${DOCKER_REDIRECTLOGS:=false}

CONFIG_BASEURLPATH=${CONFIG_BASEURLPATH:=simplesaml/}

#This SSHA256 hash is '123' for the default password.
CONFIG_AUTHADMINPASSWORD=${CONFIG_AUTHADMINPASSWORD:=\{SSHA256\}MjJSiMlkQLa+fqI+CmQ1x1oUJ7OGucYpznKxBBHpgfC+Oh+7B9vgGw==}
CONFIG_SECRETSALT=${CONFIG_SECRETSALT:=defaultsecretsalt}
CONFIG_TECHNICALCONTACT_NAME=${CONFIG_TECHNICALCONTACT_NAME:=Administrator}
CONFIG_TECHNICALCONTACT_EMAIL=${CONFIG_TECHNICALCONTACT_EMAIL:=na@example.org}
CONFIG_LANGUAGEDEFAULT=${CONFIG_LANGUAGEDEFAULT:=en}
CONFIG_TIMEZONE=${CONFIG_TIMEZONE:=America/Chicago}

CONFIG_TEMPDIR=${CONFIG_TEMPDIR:=/tmp/simplesaml}
CONFIG_SHOWERRORS=${CONFIG_SHOWERRORS:=true}
CONFIG_ERRORREPORTING=${CONFIG_ERRORREPORTING:=true}
CONFIG_ADMINPROTECTINDEXPAGE=${CONFIG_ADMINPROTECTINDEXPAGE:=false}
CONFIG_ADMINPROTECTMETADATA=${CONFIG_ADMINPROTECTMETADATA:=false}

CONFIG_DEBUG=${CONFIG_DEBUG:=false}
CONFIG_LOGGINGLEVEL=${CONFIG_LOGGINGLEVEL:=NOTICE}
CONFIG_LOGGINGHANDLER=${CONFIG_LOGGINGLHANDLER:=file}
CONFIG_LOGFILE=${CONFIG_LOGFILE:='simplesamlphp.log'}

CONFIG_ENABLESAML20IDP=${CONFIG_ENABLESAML20IDP:=false}
CONFIG_ENABLESHIB13IDP=${CONFIG_ENABLESHIB13IDP:=false}
CONFIG_ENABLEADFSIDP=${CONFIG_ENABLEADFSIDP:=false}
CONFIG_ENABLEWSFEDSP=${CONFIG_ENABLEWSFEDSP:=false}
CONFIG_ENABLEAUTHMEMCOOKIE=${CONFIG_ENABLEAUTHMEMCOOKIE:=false}

CONFIG_SESSIONDURATION=${CONFIG_SESSIONDURATION:=8 * (60 * 60)}
CONFIG_SESSIONDATASTORETIMEOUT=${CONFIG_SESSIONDATASTORETIMEOUT:=(4 * 60 * 60)}
CONFIG_SESSIONSTATETIMEOUT=${CONFIG_SESSIONSTATETIMEOUT:=(60 * 60)}
CONFIG_SESSIONCOOKIELIFETIME=${CONFIG_SESSIONCOOKIELIFETIME:=0}

CONFIG_SESSIONREMEMBERMEENABLE=${CONFIG_SESSIONREMEMBERMEENABLE:=false}
CONFIG_SESSIONREMEMBERMECHECKED=${CONFIG_SESSIONREMEMBERMECHECKED:=false}
CONFIG_SESSIONREMEMBERMELIFETIME=${CONFIG_SESSIONREMEMBERMELIFETIME:=(14 * 86400)}

CONFIG_SESSIONCOOKIESECURE=${CONFIG_SESSIONCOOKIESECURE:=false}
CONFIG_ENABLEHTTPPOST=${CONFIG_ENABLEHTTPPOST:=false}
CONFIG_THEMEUSE=${CONFIG_THEMEUSE:=default}
CONFIG_STORETYPE=${CONFIG_STORETYPE:=phpsession}

WWW_INDEX=${WWW_INDEX:=core/frontpage_welcome.php}
OPENLDAP_TLS_REQCERT=${OPENLDAP_TLS_REQCERT:=demand}

if [ "$DOCKER_REDIRECTLOGS" = "true" ]; then
  echo "[$0] DOCKER_REDIRECTLOGS was set to 'true', so setting CONFIG_LOGGINGHANDLER to 'file'"
  CONFIG_LOGGINGHANDLER=file
  if [ "$CONFIG_LOGFILE" != "simplesamlphp.log" ]; then
    echo "[$0] [WARN] DOCKER_REDIRECTLOGS was set to true, but CONFIG_LOGFILE was set away from the default. It makes no sense to do this as logs are redirected to a pipe."
    echo "[$0] If a simplesamlphp logfile is desired instead of docker logs, set DOCKER_REDIRECTLOGS to 'false' and volume mount the logs directory to the host."
    echo "[$0] Pausing 5 seconds due to above warning."
    sleep 5
  fi
  if [ -z "$(ls -A /var/simplesamlphp/log/)" ]; then
    if [ "$DOCKER_REDIRECTLOGS" = "true" ]; then
      echo "[$0] [WARN] DOCKER_REDIRECTLOGS is set to true but the log directory is volume mounted. It makes no sense to do this as logs are redirected to a pipe."
      echo "[$0] If a simplesamlphp logfile is desired instead of docker logs, set DOCKER_REDIRECTLOGS to 'false'."
      echo "[$0] Pausing 5 seconds due to above warning."
    sleep 5
    fi
  else
    if [ "$CONFIG_LOGGINGHANDLER" = "file" ]; then
      echo "[$0] [WARN] CONFIG_LOGGINGHANDLER is set to 'file'  but the log directory is not volume mounted."
      echo "[$0] [WARN] This will cause the container to grow with a logfile and is in most cases very undesirable."
      echo "[$0] Pausing 5 seconds due to above warning."
    fi
  fi
  ln -sf /proc/1/fd/1 /var/simplesamlphp/log/$CONFIG_LOGFILE
fi

#Only set memcache vars if storetype is memcache
if [ "$CONFIG_STORETYPE" == "memcache" ]; then
  CONFIG_MEMCACHESTORESERVERS=${CONFIG_MEMCACHESTORESERVERS:="    'memcache_store.servers' => array(\n        array(\n             array('hostname' => 'mc_a1'),\n             array('hostname' => 'mc_a2'),\n        ),\n        array(\n             array('hostname' => 'mc_b1'),\n             array('hostname' => 'mc_b2'),\n        ),"}
  CONFIG_MEMCACHESTOREPREFIX=${CONFIG_MEMCACHESTOREPREFIX:=null}
fi

#Check to see what directories were volume mounted
if [ -z "$(ls -A /var/simplesamlphp/)" ]; then
  echo "[$0] [WARN] New install, The entire SimpleSAMLphp directory seems to be Docker volume mounted as it is empty. This is fine for testing but highly not recommended in production. Please see the Dockerfile README for more info." >&2
  tar xf /var/simplesamlphp.tar.gz -C /var/ > /dev/null
  mv /var/simplesamlphp-*/* /var/simplesamlphp/ > /dev/null
  rm -rf /var/simplesamlphp-* > /dev/null
  echo "[$0] [WARN] Install Complete. Nothing is ephemeral in the SimpleSAMLphp install so updates need done manually from the host volume this point forward." >&2
else
  if [ -z "$(ls -A /var/simplesamlphp/attributemap/)" ]; then
    echo "[$0] attributemap directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/attributemap > /dev/null
    mv /simplesamlphp-1.*/attributemap/* /var/simplesamlphp/attributemap/
    echo "[$0] Seed complete. Directory attributemap will not be part of future upgrades and will need upgraded manually."
  fi
  if [ -z "$(ls -A /var/simplesamlphp/bin/)" ]; then
    echo "[$0] bin directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/bin > /dev/null
    mv /simplesamlphp-1.*/bin/* /var/simplesamlphp/bin/
    echo "[$0] Seed complete. Directory bin will not be part of future upgrades and will need upgraded manually."
  fi
  ls -A /var/simplesamlphp/cert/breadcrumb &> /dev/null
  if ! [ $? -ne 0 ]; then
    echo "[$0] [WARN] cert directory is not volume mounted and probably should be."
    echo "[$0] Pausing 3 seconds due to above warning."
    sleep 3
  fi
  if [ -z "$(ls -A /var/simplesamlphp/config/)" ]; then
    echo "[$0] config directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/config > /dev/null
    mv /simplesamlphp-1.*/config/* /var/simplesamlphp/config/
    echo "[$0] Seed complete. Directory config will not be part of future upgrades and will need upgraded manually."
  fi
  if [ -z "$(ls -A /var/simplesamlphp/config-templates/)" ]; then
    echo "[$0] config-templates directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/config-templates > /dev/null
    mv /simplesamlphp-1.*/config-templates/* /var/simplesamlphp/config-templates/
    echo "[$0] Seed complete. Directory config-templates will not be part of future upgrades and will need upgraded manually."
  fi
  if [ -z "$(ls -A /var/simplesamlphp/dictionaries/)" ]; then
    echo "[$0] dictionaries directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/dictionaries > /dev/null
    mv /simplesamlphp-1.*/dictionaries/* /var/simplesamlphp/dictionaries/
    echo "[$0] Seed complete. Directory dictionaries will not be part of future upgrades and will need upgraded manually."
  fi
  if [ -z "$(ls -A /var/simplesamlphp/docs/)" ]; then
    echo "[$0] docs directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/docs > /dev/null
    mv /simplesamlphp-1.*/docs/* /var/simplesamlphp/docs/
    echo "[$0] Seed complete. Directory docs will not be part of future upgrades and will need upgraded manually."
  fi
  if [ -z "$(ls -A /var/simplesamlphp/extra/)" ]; then
    echo "[$0] extra directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/extra > /dev/null
    mv /simplesamlphp-1.*/extra/* /var/simplesamlphp/extra/
    echo "[$0] Seed complete. Directory extra will not be part of future upgrades and will need upgraded manually."
  fi
  if [ -z "$(ls -A /var/simplesamlphp/lib/)" ]; then
    echo "[$0] lib directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/lib > /dev/null
    mv /simplesamlphp-1.*/lib/* /var/simplesamlphp/lib/
    echo "[$0] Seed complete. Directory lib will not be part of future upgrades and will need upgraded manually."
  fi
  if [ -z "$(ls -A /var/simplesamlphp/metadata/)" ]; then
    echo "[$0] metadata directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/metadata > /dev/null
    mv /simplesamlphp-1.*/metadata/* /var/simplesamlphp/metadata/
    echo "[$0] Seed complete. Directory metadata will not be part of future upgrades and will need upgraded manually."
  fi
  if [ -z "$(ls -A /var/simplesamlphp/metadata-templates/)" ]; then
    echo "[$0] metadata-templates directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/metadata-templates > /dev/null
    mv /simplesamlphp-1.*/metadata-templates/* /var/simplesamlphp/metadata-templates/
    echo "[$0] Seed complete. Directory metadata-templates will not be part of future upgrades and will need upgraded manually."
  fi
  if [ -z "$(ls -A /var/simplesamlphp/modules/)" ]; then
    echo "[$0] modules directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/modules > /dev/null
    mv /simplesamlphp-1.*/modules/* /var/simplesamlphp/modules/
    echo "[$0] Seed complete. Directory modules will not be part of future upgrades and will need upgraded manually."
  fi
  if [ -z "$(ls -A /var/simplesamlphp/schemas/)" ]; then
    echo "[$0] schemas directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/schemas > /dev/null
    mv /simplesamlphp-1.*/schemas/* /var/simplesamlphp/schemas/
    echo "[$0] Seed complete. Directory schemas will not be part of future upgrades and will need upgraded manually."
  fi
  if [ -z "$(ls -A /var/simplesamlphp/templates/)" ]; then
    echo "[$0] templates directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/templates > /dev/null
    mv /simplesamlphp-1.*/templates/* /var/simplesamlphp/templates/
    echo "[$0] Seed complete. Directory templates will not be part of future upgrades and will need upgraded manually."
  fi
  if [ -z "$(ls -A /var/simplesamlphp/tests/)" ]; then
    echo "[$0] tests directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/tests > /dev/null
    mv /simplesamlphp-1.*/tests/* /var/simplesamlphp/tests/
    echo "[$0] Seed complete. Directory tests will not be part of future upgrades and will need upgraded manually."
  fi
  if [ -z "$(ls -A /var/simplesamlphp/tools/)" ]; then
    echo "[$0] tools directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/tools > /dev/null
    mv /simplesamlphp-1.*/tools/* /var/simplesamlphp/tools/
    echo "[$0] Seed complete. Directory tools will not be part of future upgrades and will need upgraded manually."
  fi
  if [ -z "$(ls -A /var/simplesamlphp/vendor/)" ]; then
    echo "[$0] vendor directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/vendor > /dev/null
    mv /simplesamlphp-1.*/vendor/* /var/simplesamlphp/vendor/
    echo "[$0] Seed complete. Directory vendor will not be part of future upgrades and will need upgraded manually."
  fi
  if [ -z "$(ls -A /var/simplesamlphp/www/)" ]; then
    echo "[$0] www directory seems to be Docker volume mounted as it is empty. Seeding."
    tar xzvf /var/simplesamlphp.tar.gz simplesamlphp*/www > /dev/null
    mv /simplesamlphp-1.*/www/* /var/simplesamlphp/www/
    echo "[$0] Seed complete. Directory www will not be part of future upgrades and will need upgraded manually."
  fi
 rm -rf /simplesamlphp-*/
fi

ls -A /var/simplesamlphp/config/.dockersetupdone &> /dev/null
if ! [ $? -ne 0 ]; then
  echo "[$0] Breadcrumb located, skipping firstime config."
  echo "[$0] Done"
  exit 0
fi

#Apply server certificate check in a TLS session
echo "TLS_REQCERT=$OPENLDAP_TLS_REQCERT" >> /etc/openldap/ldap.conf

#Configure SimpleSAMLphp from runtime variables.

echo "[$0] Apply Configuration to config.php..."

#Apply Configurations
sed -i "s|'baseurlpath' => 'simplesaml/'|'baseurlpath' => '$CONFIG_BASEURLPATH'|g" /var/simplesamlphp/config/config.php

sed -i "s|'auth.adminpassword' => '123'|'auth.adminpassword' => '$CONFIG_AUTHADMINPASSWORD'|g" /var/simplesamlphp/config/config.php
sed -i "s|'secretsalt' => 'defaultsecretsalt'|'secretsalt' => '$CONFIG_SECRETSALT'|g" /var/simplesamlphp/config/config.php
sed -i "s|'technicalcontact_name' => 'Administrator'|'technicalcontact_name' => '$CONFIG_TECHNICALCONTACT_NAME'|g" /var/simplesamlphp/config/config.php
sed -i "s|'technicalcontact_email' => 'na@example.org'|'technicalcontact_email' => '$CONFIG_TECHNICALCONTACT_EMAIL'|g" /var/simplesamlphp/config/config.php
sed -i "s|'language.default' => 'en'|'language.default' => '$CONFIG_LANGUAGEDEFAULT'|g" /var/simplesamlphp/config/config.php
sed -i "s|'timezone' => null|'timezone' => '$CONFIG_TIMEZONE'|g" /var/simplesamlphp/config/config.php

sed -i "s|'tempdir' => '/tmp/simplesaml'|'tempdir' => '$CONFIG_TEMPDIR'|g" /var/simplesamlphp/config/config.php
sed -i "s|'showerrors' => true|'showerrors' => $CONFIG_SHOWERRORS|g" /var/simplesamlphp/config/config.php
sed -i "s|'errorreporting' => true|'errorreporting' => $CONFIG_ERRORREPORTING|g" /var/simplesamlphp/config/config.php
sed -i "s|'admin.protectindexpage' => false|'admin.protectindexpage' => $CONFIG_ADMINPROTECTINDEXPAGE|g" /var/simplesamlphp/config/config.php
sed -i "s|'admin.protectmetadata' => false|'admin.protectmetadata' => $CONFIG_ADMINPROTECTMETADATA|g" /var/simplesamlphp/config/config.php

sed -i "s|'debug' => false|'debug' => $CONFIG_DEBUG|g" /var/simplesamlphp/config/config.php
sed -i "s|'logging.level' => SimpleSAML_Logger::NOTICE|'logging.level' => SimpleSAML_Logger::$CONFIG_LOGGINGLEVEL|g" /var/simplesamlphp/config/config.php
sed -i "s|'logging.handler' => 'syslog'|'logging.handler' => '$CONFIG_LOGGINGHANDLER'|g" /var/simplesamlphp/config/config.php
sed -i "s|'logging.logfile' => 'simplesamlphp.log'|'logging.logfile' => '$CONFIG_LOGFILE'|g" /var/simplesamlphp/config/config.php

sed -i "s|'enable.saml20-idp' => false|'enable.saml20-idp' => $CONFIG_ENABLESAML20IDP|g" /var/simplesamlphp/config/config.php
sed -i "s|'enable.shib13-idp' => false|'enable.shib13-idp' => $CONFIG_ENABLESHIB13IDP|g" /var/simplesamlphp/config/config.php
sed -i "s|'enable.adfs-idp' => false|'enable.adfs-idp' => $CONFIG_ENABLEADFSIDP|g" /var/simplesamlphp/config/config.php
sed -i "s|'enable.wsfed-sp' => false|'enable.wsfed-sp' => $CONFIG_ENABLEWSFEDSP|g" /var/simplesamlphp/config/config.php
sed -i "s|'enable.authmemcookie' => false|'enable.authmemcookie' => $CONFIG_ENABLEAUTHMEMCOOKIE|g" /var/simplesamlphp/config/config.php

sed -i "s|'session.duration' => 8 \* (60 \* 60)|'session.duration' => $CONFIG_SESSIONDURATION|g" /var/simplesamlphp/config/config.php
sed -i "s|'session.datastore.timeout' => (4 \* 60 \* 60)|'session.datastore.timeout' => $CONFIG_SESSIONDATASTORETIMEOUT|g" /var/simplesamlphp/config/config.php
sed -i "s|'session.state.timeout' => (60 \* 60)|'session.state.timeout' => $CONFIG_SESSIONSTATETIMEOUT|g" /var/simplesamlphp/config/config.php
sed -i "s|'session.cookie.lifetime' => 0|'session.cookie.lifetime' => $CONFIG_SESSIONCOOKIELIFETIME|g" /var/simplesamlphp/config/config.php

sed -i "s|'session.rememberme.enable' => false|'session.rememberme.enable' => $CONFIG_SESSIONREMEMBERMEENABLE|g" /var/simplesamlphp/config/config.php
sed -i "s|'session.rememberme.checked' => false|'session.rememberme.checked' => $CONFIG_SESSIONREMEMBERMECHECKED|g" /var/simplesamlphp/config/config.php
sed -i "s|'session.rememberme.lifetime' => (14 \* 86400)|'session.rememberme.lifetime' => $CONFIG_SESSIONREMEMBERMELIFETIME|g" /var/simplesamlphp/config/config.php

sed -i "s|'session.cookie.secure' => false|'session.cookie.secure' => $CONFIG_SESSIONCOOKIESECURE|g" /var/simplesamlphp/config/config.php
sed -i "s|'enable.http_post' => false|'enable.http_post' => $CONFIG_ENABLEHTTPPOST|g" /var/simplesamlphp/config/config.php

sed -i "s|'theme.use' => 'default'|'theme.use' => '$CONFIG_THEMEUSE'|g" /var/simplesamlphp/config/config.php

sed -i "s|'store.type'                    => 'phpsession',|'store.type'                    => '$CONFIG_STORETYPE',|g" /var/simplesamlphp/config/config.php

sed -i "s|'core/frontpage_welcome.php'|'$WWW_INDEX'|g" /var/simplesamlphp/www/index.php

#Only configure redundant memcache if storetype is set to memcache
if [ "$CONFIG_STORETYPE" == "memcache" ]; then
  sed -i "/    'memcache_store.servers' => array(/{n;N;N;d}" /var/simplesamlphp/config/config.php 
  sed -i "s|    'memcache_store.servers' => array(|$CONFIG_MEMCACHESTORESERVERS|g" /var/simplesamlphp/config/config.php
  sed -i "s|'memcache_store.prefix' => null|'memcache_store.prefix' => '$CONFIG_MEMCACHESTOREPREFIX'|g" /var/simplesamlphp/config/config.php
  if [ "$CONFIG_MEMCACHESTOREPREFIX" == "null" ]; then
    echo "[$0] [WARN] CONFIG_STORETYPE was set to 'memcache', but CONFIG_MEMCACHESTOREPREFIX was not set from null. This will not work. Setting CONFIG_MEMCACHESTOREPREFIX to 'simpleSAMLphp'."
    echo "[$0] To avoid this warning in the future, set CONFIG_MEMCACHESTOREPREFIX to something, 'simpleSAMLphp' is the suggested default if memcache is enabled."
    echo "[$0] Pausing 5 seconds due to above warning."
    sleep 5
    CONFIG_MEMCACHESTOREPREFIX=simplesamlphp
    sed -i "s|'memcache_store.prefix' => null|'memcache_store.prefix' => $CONFIG_MEMCACHESTOREPREFIX|g" /var/simplesamlphp/config/config.php
  fi
fi

chown php-fpm:php-fpm /var/simplesamlphp/log

touch /var/simplesamlphp/config/.dockersetupdone

echo "[$0] Configuration Complete. Saved .dockersetupdone breadcrumb to config directory to prevent config rerun."
