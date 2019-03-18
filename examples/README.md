[![](https://images.microbadger.com/badges/version/venatorfox/simplesamlphp:1.17.1.svg)](https://github.com/Venator-Fox/docker-simplesamlphp/network "View Network") [![](https://images.microbadger.com/badges/image/venatorfox/simplesamlphp:1.17.1.svg)](https://microbadger.com/images/venatorfox/simplesamlphp:1.17.1 "View layer metadata on MicroBadger") [![Pulls on Docker Hub](https://img.shields.io/docker/pulls/venatorfox/simplesamlphp.svg)](https://hub.docker.com/r/venatorfox/simplesamlphp)  [![Stars on Docker Hub](https://img.shields.io/docker/stars/venatorfox/simplesamlphp.svg)](https://hub.docker.com/r/venatorfox/simplesamlphp) [![GitHub Open Issues](https://img.shields.io/github/issues/Venator-Fox/docker-simplesamlphp.svg)](https://github.com/Venator-Fox/docker-simplesamlphp/issues) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

### Examples

This directory contains some example files in order to run the [venatorfox/simplesamlphp](https://hub.docker.com/r/venatorfox/simplesamlphp/) in a more complex manner. (ie. with SSL termination, HAProxy, etc...) These examples assume this is installed in a non-orchestrated manner on a host.

The following examples are provided here:  
- Super basic with all the default options  
- HAProxy SSL Termination, Let's Encrypt CA, and common configurations via docker-compose  
- HAProxy SSL Termination, Let's Encrypt CA, and common configurations via systemd

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

Run the following two commands to generate a self-signed SSL certificate:
```console
mkdir -p /srv/docker/volumes/some-haproxy/ssl
docker run --rm -v /srv/docker/volumes/some-haproxy/ssl:/ssl -e HOST=localhost -e TYPE=pem project42/selfsignedcert
```

Save the `haproxy.cfg` to `/srv/docker/volumes/some-haproxy/haproxy.cfg`

Compose version in this example is v3.5  
Run `docker-compose -f docker-compose.yml up` to bring the stack up with your variables.
After install, visit https://localhost.  
Use `docker-compose -f docker-compose.yml down` to destroy all containers.

#### HAProxy SSL Termination, Let's Encrypt CA, and common configurations via systemd  
> This is recommended for production for non-orchestrated installs. These unit files will start containers utilizing, memcached, haproxy, and simplesaml

//TODO

