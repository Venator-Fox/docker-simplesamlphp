[![](https://images.microbadger.com/badges/version/venatorfox/simplesamlphp:1.17.3.svg)](https://github.com/Venator-Fox/docker-simplesamlphp/network "View Network") [![](https://images.microbadger.com/badges/image/venatorfox/simplesamlphp:1.17.3.svg)](https://microbadger.com/images/venatorfox/simplesamlphp:1.17.3 "View layer metadata on MicroBadger") [![Pulls on Docker Hub](https://img.shields.io/docker/pulls/venatorfox/simplesamlphp.svg)](https://hub.docker.com/r/venatorfox/simplesamlphp)  [![Stars on Docker Hub](https://img.shields.io/docker/stars/venatorfox/simplesamlphp.svg)](https://hub.docker.com/r/venatorfox/simplesamlphp) [![GitHub Open Issues](https://img.shields.io/github/issues/Venator-Fox/docker-simplesamlphp.svg)](https://github.com/Venator-Fox/docker-simplesamlphp/issues) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

### Examples

This directory contains some example files in order to run the [venatorfox/simplesamlphp](https://hub.docker.com/r/venatorfox/simplesamlphp/) in a more complex manner. (ie. with SSL termination, HAProxy, etc...) These examples assume this is installed in a non-orchestrated manner on a host.

The following examples are provided here:  
- Super basic with all the default options (basically just to look at the application)  
- HAProxy SSL Termination, Self Signed SSL, and common configurations via docker-compose (for development)  
- HAProxy SSL Termination, Let's Encrypt CA, and common configurations via systemd (for production)

#### Super basic with all the default options  
> 1 liner, just to see how SimpleSAMLphp looks.

Start a `venatorfox/simplesamlphp` instance, expose port 80.

```console
$ docker run --name some-simplesamlphp -p80:80 venatorfox/simplesamlphp:latest
```
Visit the site at http://localhost, default unconfigured username is "admin" and password is "123".

#### HAProxy SSL Termination, and common configurations via docker-compose  
> This is recommended for testing. Compose is not recommended for production.

This example will run HAProxy with snakeoil SSL termination for https://localhost.
It will also bring up 4 memcached containers, 2 pairs of 2, for session.
This is useful for running multiple SimpleSAMLphp instances for session sharing.

You will need the `haproxy.cfg` and `docker-compose.yml` files from the examples directory.

Since SimpleSAMLphp will not care about the webroot, an entry to the hosts file can be added to whatever for testing. HAProxy will handle SSL.
Be sure to adjust the HOST environment variable below for whatever localhost self-signed certificate desired.
Of course in production use a real CA, like LetsEncrypt.

This will be more in line with what would be seen in a production environment. (minus the demo 123 password, salt, etc)
Note the choices of volume mounts of what to keep ephemeral, and what to keep persistant.
The more volumes, the more manual labor will need to happen when upgrades occur.
Check SimpleSAMLphp's upgrade notes to see if updates occured in a specified directory.

Note that running this compose file will create files in `/srv/docker/volumes/` on your host.
You can remove this after toying with the example.

Run the following to generate a quick self-signed SSL certificate:
```console
mkdir -p /srv/docker/volumes/some-haproxy/config/ssl
docker run --rm -v /srv/docker/volumes/some-haproxy/config/ssl:/ssl -e HOST=localhost -e TYPE=pem project42/selfsignedcert
```

Copy the `haproxy.cfg` to `/srv/docker/volumes/some-haproxy/config`

~~~
Be sure to modify haproxy.cfg to use the `localhost.pem` instead of `priv-fullchain-bundle.pem`
~~~

Compose version in this example is v3.5  
Run `docker-compose -f docker-compose.yml up` to bring the stack up with your variables.
After install, visit https://localhost.  
Use `docker-compose -f docker-compose.yml down` to destroy all containers.

#### HAProxy SSL Termination, Let's Encrypt CA, and common configurations via systemd  
> This is recommended for production for non-orchestrated installs. These unit files will start containers utilizing, memcached, haproxy, simplesaml, and letsencrypt.

This example will accomplish all items as done in the compose example, but also setup a container for a LetsEncrypt SSL certificate. The haproxy container will cat over the keys.

Note that running these will create files in `/srv/docker/volumes/` on your host. Use these example files to your preference. Some examples are below tested with CentOS/RHEL

> Method 1 (Copy to local config dir `/etc/systemd/system/`)
>
```console
cp -rfv /some/location/docker-simplesamlphp/examples/systemd/*.service /etc/systemd/system/
```

or

> Method 2 (Symlink to vendor/pkg dir `/usr/lib/systemd/system/`) (use full paths)
>
```console
ln -s /some/location/docker-simplesamlphp/examples/systemd/some-haproxy.service /usr/lib/systemd/system/
ln -s /some/location/docker-simplesamlphp/examples/systemd/some-letsencrypt.service /usr/lib/systemd/system/
ln -s /some/location/docker-simplesamlphp/examples/systemd/some-memcacheda01.service /usr/lib/systemd/system/
ln -s /some/location/docker-simplesamlphp/examples/systemd/some-memcacheda02.service /usr/lib/systemd/system/
ln -s /some/location/docker-simplesamlphp/examples/systemd/some-memcachedb01.service /usr/lib/systemd/system/
ln -s /some/location/docker-simplesamlphp/examples/systemd/some-memcachedb02.service /usr/lib/systemd/system/
ln -s /some/location/docker-simplesamlphp/examples/systemd/some-simplesamlphp.service /usr/lib/systemd/system/
```

or

> Method 3 (Use the unit files directly)
>
```console
systemctl start /some/location/docker-simplesamlphp/examples/systemd/some-letsencrypt.service
```

Regardless of the method used above, start the letsencrypt container to obtain a certificate. The example provided uses http validation. Port 80 will need to be open to your server for DNS validation. Be sure to modify the unit file to your parameters (esp EMAIL and URL) and `systemctl daemon-reload`. The image used in this example is from [linuxserver/letsencrypt](https://hub.docker.com/r/linuxserver/letsencrypt/)

~~~
systemctl start some-letsencrypt
~~~

After it has completed key generation and obtained a certificate, stop the container

~~~
systemctl status some-letsencrypt

~~~

~~~
systemctl stop some-letsencrypt
~~~

Create persistant directory `ssl` for `some-haproxy`

~~~
mkdir -p /srv/docker/volumes/some-haproxy/haproxy/ssl
~~~

Copy the `haproxy.cfg` to `/srv/docker/volumes/some-haproxy/haproxy`

~~~
cp -v /some/location/docker-simplesamlphp/examples/haproxy/haproxy.cfg /srv/docker/volumes/some-haproxy/haproxy/
~~~

Enable and start `some-haproxy`, this will bring up the rest of the containers

~~~
systemctl enable --now some-haproxy
~~~

Verify:

~~~
systemctl status some-haproxy

● some-haproxy.service - SimpleSAMLphp HAProxy Container (some-haproxy)
   Loaded: loaded (/etc/systemd/system/some-haproxy.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2019-07-10 15:50:25 CDT; 21s ago
  Process: 17047 ExecStartPre=/usr/bin/docker pull million12/haproxy:latest (code=exited, status=0/SUCCESS)
  Process: 17043 ExecStartPre=/bin/bash -c /bin/cat /srv/docker/volumes/some-letsencrypt/config/keys/letsencrypt/priv-fullchain-bundle.pem > /srv/docker/volumes/%N/haproxy/ssl/priv-fullchain-bundle.pem (code=exited, status=0/SUCCESS)
  Process: 17035 ExecStartPre=/usr/bin/docker rm %N (code=exited, status=1/FAILURE)
  Process: 17023 ExecStartPre=/usr/bin/docker stop %N (code=exited, status=1/FAILURE)
 Main PID: 17429 (docker-current)
    Tasks: 7
   Memory: 5.1M
   CGroup: /system.slice/some-haproxy.service
           └─17429 /usr/bin/docker-current run --rm --name some-haproxy --network simplesamlphp-network --cap-add NET_ADMIN --publish 80:80 --publish 443:443 --volume /srv/docker/volumes/some-haproxy/haproxy/:/etc/haproxy/:Z million12/haproxy:latest

Jul 10 15:50:26 e10-devidp docker[17429]: frontend https-in
Jul 10 15:50:26 e10-devidp docker[17429]: bind *:443 ssl crt /etc/haproxy/ssl/priv-fullchain-bundle.pem
Jul 10 15:50:26 e10-devidp docker[17429]: reqadd X-Forwarded-Proto:\ https
Jul 10 15:50:26 e10-devidp docker[17429]: default_backend nodes-http
Jul 10 15:50:26 e10-devidp docker[17429]: backend nodes-http
Jul 10 15:50:26 e10-devidp docker[17429]: redirect scheme https if !{ ssl_fc }
Jul 10 15:50:26 e10-devidp docker[17429]: server node1 some-simplesamlphp:80 check
Jul 10 15:50:26 e10-devidp docker[17429]: ====================================================================================================
Jul 10 15:50:26 e10-devidp docker[17429]: Configuration file is valid
Jul 10 15:50:26 e10-devidp docker[17429]: [2019-07-10 20:50:26] HAProxy started with /etc/haproxy/haproxy.cfg config, pid 13.
~~~

~~~
docker ps -a

7a1e3550d2ad        million12/haproxy:latest               "/bootstrap.sh"          About a minute ago   Up About a minute   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp   some-haproxy
94054daae650        memcached:latest                       "docker-entrypoint..."   About a minute ago   Up About a minute   11211/tcp                                  some-memcacheda01
1bc3a7c8fba6        memcached:latest                       "docker-entrypoint..."   About a minute ago   Up About a minute   11211/tcp                                  some-memcachedb02
f1a5ad49bfd4        memcached:latest                       "docker-entrypoint..."   About a minute ago   Up About a minute   11211/tcp                                  some-memcacheda02
5ef6b9c104f2        memcached:latest                       "docker-entrypoint..."   About a minute ago   Up About a minute   11211/tcp                                  some-memcachedb01
bf58f84a21e6        venatorfox/simplesamlphp:development   "/init"                  About a minute ago   Up About a minute                                              some-simplesamlphp
~~~

##### Other Notes

When translating docker run into systemd unit files, be sure to use `systemd-escape` when needed. (ie spaces or special characters):

~~~
systemd-escape "CONFIG_MEMCACHESTORESERVERS=    'memcache_store.servers' => [\n        [\n             ['hostname' => 'some-memcacheda01'],\n             ['hostname' => 'some-memcacheda02'],\n        ],\n        [\n             ['hostname' => 'some-memcachedb01'],\n             ['hostname' => 'some-memcachedb02'],\n        ],"

CONFIG_MEMCACHESTORESERVERS\x3d\x20\x20\x20\x20\x27memcache_store.servers\x27\x20\x3d\x3e\x20\x5b\x5cn\x20\x20\x20\x20\x20\x20\x20\x20\x5b\x5cn\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x5b\x27hostname\x27\x20\x3d\x3e\x20\x27some\x2dmemcacheda01\x27\x5d\x2c\x5cn\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x5b\x27hostname\x27\x20\x3d\x3e\x20\x27some\x2dmemcacheda02\x27\x5d\x2c\x5cn\x20\x20\x20\x20\x20\x20\x20\x20\x5d\x2c\x5cn\x20\x20\x20\x20\x20\x20\x20\x20\x5b\x5cn\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x5b\x27hostname\x27\x20\x3d\x3e\x20\x27some\x2dmemcachedb01\x27\x5d\x2c\x5cn\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x5b\x27hostname\x27\x20\x3d\x3e\x20\x27some\x2dmemcachedb02\x27\x5d\x2c\x5cn\x20\x20\x20\x20\x20\x20\x20\x20\x5d\x2c
~~~

For Example:

~~~
docker run -t --name some-simplesamlphp --network simplesamlphp-network \
-e CONFIG_BASEURLPATH=https://auth.example.com/simplesaml/ \
-e CONFIG_AUTHADMINPASSWORD={SSHA256}MjJSiMlkQLa+fqI+CmQ1x1oUJ7OGucYpznKxBBHpgfC+Oh+7B9vgGw== \
-e CONFIG_SECRETSALT=exampleabcdefghijklmnopqrstuvwxy \
-e CONFIG_TECHNICALCONTACT_NAME="Adam W Zheng" \
-e CONFIG_TECHNICALCONTACT_EMAIL=adam.w.zheng@icloud.com \
-e CONFIG_SHOWERRORS=true \
-e CONFIG_ERRORREPORTING=true \
-e CONFIG_ADMINPROTECTINDEXPAGE=true \
-e CONFIG_LOGGINGLEVEL=INFO \
-e CONFIG_ENABLESAML20IDP=true \
-e CONFIG_STORETYPE=memcache \
-e CONFIG_MEMCACHESTOREPREFIX=simplesamlphp \
-e CONFIG_MEMCACHESTORESERVERS="    'memcache_store.servers' => [\n        [\n             ['hostname' => 'some-memcacheda01'],\n             ['hostname' => 'some-memcacheda02'],\n        ],\n        [\n             ['hostname' => 'some-memcachedb01'],\n             ['hostname' => 'some-memcachedb02'],\n        ]," \
-e OPENLDAP_TLS_REQCERT=allow \
-e MTA_NULLCLIENT=true \
-e POSTFIX_MYHOSTNAME=auth.example.com \
-e POSTFIX_MYORIGIN=$mydomain \
-e POSTFIX_INETINTERFACES=loopback-only \
-e DOCKER_REDIRECTLOGS=true \
-v /srv/docker/volumes/some-simplesamlphp/cache/:/var/simplesamlphp/cache/:Z \
-v /srv/docker/volumes/some-simplesamlphp/config/:/var/simplesamlphp/config/:Z \
-v /srv/docker/volumes/some-simplesamlphp/cert/:/var/simplesamlphp/cert/:Z \
-v /srv/docker/volumes/some-simplesamlphp/locales/:/var/simplesamlphp/locales/:Z \
-v /srv/docker/volumes/some-simplesamlphp/log/:/var/simplesamlphp/log/:Z \
-v /srv/docker/volumes/some-simplesamlphp/metadata/:/var/simplesamlphp/metadata/:Z \
-v /srv/docker/volumes/some-simplesamlphp/modules/:/var/simplesamlphp/modules/:Z \
-v /srv/docker/volumes/some-simplesamlphp/templates/:/var/simplesamlphp/templates/:Z \
-v /srv/docker/volumes/some-simplesamlphp/www/:/var/simplesamlphp/www/:Z \
venatorfox/simplesamlphp:development
~~~

Would look like this in a unit file

~~~
ExecStart=/usr/bin/docker run -t --name some-simplesamlphp \
                                 --network simplesamlphp-network \
                                 -e CONFIG_BASEURLPATH=https://auth.example.com/simplesaml/ \
                                 -e CONFIG_AUTHADMINPASSWORD={SSHA256}MjJSiMlkQLa+fqI+CmQ1x1oUJ7OGucYpznKxBBHpgfC+Oh+7B9vgGw== \
                                 -e CONFIG_SECRETSALT=exampleabcdefghijklmnopqrstuvwxy \
                                 -e CONFIG_TECHNICALCONTACT_NAME=Adam\x20W\x20Zheng \
                                 -e CONFIG_TECHNICALCONTACT_EMAIL=adam.w.zheng@icloud.com \
                                 -e CONFIG_SHOWERRORS=true \
                                 -e CONFIG_ERRORREPORTING=true \
                                 -e CONFIG_ADMINPROTECTINDEXPAGE=true \
                                 -e CONFIG_LOGGINGLEVEL=INFO \
                                 -e CONFIG_ENABLESAML20IDP=true \
                                 -e CONFIG_STORETYPE=memcache \
                                 -e CONFIG_MEMCACHESTOREPREFIX=simplesamlphp \
                                 -e CONFIG_MEMCACHESTORESERVERS=\x20\x20\x20\x20\x27memcache_store.servers\x27\x20\x3d\x3e\x20\x5b\x5cn\x20\x20\x20\x20\x20\x20\x20\x20\x5b\x5cn\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x5b\x27hostname\x27\x20\x3d\x3e\x20\x27some\x2dmemcacheda01\x27\x5d\x2c\x5cn\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x5b\x27hostname\x27\x20\x3d\x3e\x20\x27some\x2dmemcacheda02\x27\x5d\x2c\x5cn\x20\x20\x20\x20\x20\x20\x20\x20\x5d\x2c\x5cn\x20\x20\x20\x20\x20\x20\x20\x20\x5b\x5cn\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x5b\x27hostname\x27\x20\x3d\x3e\x20\x27some\x2dmemcachedb01\x27\x5d\x2c\x5cn\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x5b\x27hostname\x27\x20\x3d\x3e\x20\x27some\x2dmemcachedb02\x27\x5d\x2c\x5cn\x20\x20\x20\x20\x20\x20\x20\x20\x5d\x2c
                                 -e OPENLDAP_TLS_REQCERT=allow \
                                 -e MTA_NULLCLIENT=true \
                                 -e POSTFIX_MYHOSTNAME=auth.example.com \
                                 -e POSTFIX_MYORIGIN=$mydomain \
                                 -e POSTFIX_INETINTERFACES=loopback-only \
                                 -e DOCKER_REDIRECTLOGS=true \
                                 -v /srv/docker/volumes/some-simplesamlphp/cache/:/var/simplesamlphp/cache/:Z \
                                 -v /srv/docker/volumes/some-simplesamlphp/config/:/var/simplesamlphp/config/:Z \
                                 -v /srv/docker/volumes/some-simplesamlphp/cert/:/var/simplesamlphp/cert/:Z \
                                 -v /srv/docker/volumes/some-simplesamlphp/locales/:/var/simplesamlphp/locales/:Z \
                                 -v /srv/docker/volumes/some-simplesamlphp/log/:/var/simplesamlphp/log/:Z \
                                 -v /srv/docker/volumes/some-simplesamlphp/metadata/:/var/simplesamlphp/metadata/:Z \
                                 -v /srv/docker/volumes/some-simplesamlphp/modules/:/var/simplesamlphp/modules/:Z \
                                 -v /srv/docker/volumes/some-simplesamlphp/templates/:/var/simplesamlphp/templates/:Z \
                                 -v /srv/docker/volumes/some-simplesamlphp/www/:/var/simplesamlphp/www/:Z \
                                 venatorfox/simplesamlphp:development
~~~
