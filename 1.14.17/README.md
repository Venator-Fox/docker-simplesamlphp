[![](https://images.microbadger.com/badges/version/venatorfox/simplesamlphp:1.14.17.svg)](https://microbadger.com/images/venatorfox/simplesamlphp:1.14.17 "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/venatorfox/simplesamlphp:1.14.17.svg)](https://microbadger.com/images/venatorfox/simplesamlphp:1.14.17 "Get your own image badge on microbadger.com") [![Pulls on Docker Hub](https://img.shields.io/docker/pulls/venatorfox/simplesamlphp.svg)](https://hub.docker.com/r/venatorfox/simplesamlphp)  [![Stars on Docker Hub](https://img.shields.io/docker/stars/venatorfox/simplesamlphp.svg)](https://hub.docker.com/r/venatorfox/simplesamlphp) [![GitHub Open Issues](https://img.shields.io/github/issues/Venator-Fox/docker-simplesamlphp.svg)](https://github.com/Venator-Fox/docker-simplesamlphp/issues) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Supported tags and respective `Dockerfile` links

- [`1.14.16`, `latest` (*1.14.17/Dockerfile*)](https://github.com/Venator-Fox/docker-simplesamlphp/blob/master/1.14.17/Dockerfile)
- [`1.14.16` (*1.14.16/Dockerfile*)](https://github.com/Venator-Fox/docker-simplesamlphp/blob/master/1.14.16/Dockerfile)
- [`1.14.15` (*1.14.15/Dockerfile*)](https://github.com/Venator-Fox/docker-simplesamlphp/blob/master/1.14.15/Dockerfile)

### How to use this image

Start a `venatorfox/simplesamlphp` instance, expose port 80.

```console
$ docker run --name some-simplesamlphp -p80:80 venatorfox/simplesamlphp:latest
```
Visit the site at http://localhost, default unconfigured username is "admin" and password is "123". #superSecure 

See below for available runtime environment variables for a more specific configuration.

> The config.php will be created at run and baked into the SimpleSAMLphp Core Install.
> This will allow easy future upgrades, as you can simply destroy the container and bring it up with a new version.
> The docker environment variables configured at runtime will be applied to the default config, pulled from SimpleSAMLphp.

> The purpose of this image is to store as much ephemeral data inside the container as possible for easy upgrades.
> This is controlled by how you mount docker volumes. Examples are presented below.

### Supported Volume Mount Options for Pre-Seeding

The following directories will pre-seed if they are mounted.
If attempting to mount an subdirectory, it will not pre-seed and therefore must pre-exist.

If the directory is not mounted, it will use its ephemeral counterpart in the container which is ideal, explained below.
Note that once a directory is mounted, it will need to be upgraded manually for future SimpleSAMLphp releases if applicable.
If a mounted directory disappears from the host, it will pre-seed again with defaults from the SimpleSAMLphp install on restart.
If reverting to a default directory is desired, remove the host directory and adjust the docker run command to exclude the mount.

Some directories will probably never need manually updated as SimpleSAMLphp will not update them in new versions.
`/cert` and `/metadata` are examples of directories that should always be volume mounted, as it contains data that must persist, is very organization specific, and will probably never or rarely be changed by SimpleSAMLphp releases.

Something like `/bin` should never be volume mounted unless it's for development purposes, as it will likley be upgraded by SimpleSAMLphp in new versions.

Be sure to check new SimpleSAMLphp releases to see if manual upgrades need done to a directory that was mounted.
Check [SimpleSAMLphp docs](https://simplesamlphp.org/docs/stable/simplesamlphp-install) installation section 5 for specifics.

Individual files can also be mounted, but will not pre-seed content. It must pre-exist before starting the container.
Mounting the `authsources.php` file is a good example, as `/config` will probably not be mounted.
Another example, if using composer, the `composer.json` and `composer.lock` files will need mounted.

This will vary greatly depending on use. A compose file similar to a production instance as is at the end of this README.

| Directory | Opinion |
| ------ | ------ |
| /var/simplesamlphp/attributemap | -- |
| /var/simplesamlphp/bin | Probably should not be volume mounted. |
| /var/simplesamlphp/cert | Should always be volume mounted. |
| /var/simplesamlphp/config | Should probably not be volume mounted as its mostly configured by docker. |
| /var/simplesamlphp/config-templates | -- |
| /var/simplesamlphp/dictionaries | Can be mounted for customized user messages. |
| /var/simplesamlphp/docs | -- |
| /var/simplesamlphp/extra | -- |
| /var/simplesamlphp/lib | -- |
| /var/simplesamlphp/log | If using docker log redirection (not working yet), this cannot be volume mounted. If docker logs write to a file, this should be volume mounted so logs do not grow inside the container. |
| /var/simplesamlphp/metadata | Should always be volume mounted, very specific to organization. |
| /var/simplesamlphp/metadata-templates | -- |
| /var/simplesamlphp/modules | Can be volume mounted for easier module customization |
| /var/simplesamlphp/schemas | -- |
| /var/simplesamlphp/templates | -- |
| /var/simplesamlphp/tests | -- |
| /var/simplesamlphp/tools | -- |
| /var/simplesamlphp/vendor | -- |
| /var/simplesamlphp/www | Can be volume mounted for easier www customization |

### Runtime Environment Variables

The following variables can be overridden at run or in docker-compose. 
It is recommended to set them properly and not use default values. 
(Unless you want an authentication service with no SSL, with your admin password being 123 (Can you not, kthx)).

| Variable | Default Value | Description |
| ------ | ------ | ------ |
| CONFIG_BASEURLPATH | simplesaml/ | If using SSL behind a proxy enter the base URL here, otherwise IdP metadata will use http://. Format is [(https)://(hostname)[:port]]/[path/to/simplesaml/]. |
| DOCKER_REDIRECTLOGS | false | Redirect logs written to the log file by SimpleSAMLphp to `/proc/1/fd/1`. This does not work yet due to permissions issues. If someone knows how to resolve this please let me know or contribute a fix to the Git repository. Thanks! |
| CONFIG_AUTHADMINPASSWORD | SSHA256 hash of '123' | Plain text works as well. Use PWGen to generate a hash for this variable. Refer to [SimpleSAMLphp docs](https://simplesamlphp.org/docs/stable/simplesamlphp-install), installation guide section 7. |
| CONFIG_SECRETSALT | defaultsecretsalt | Refer to [SimpleSAMLphp docs](https://simplesamlphp.org/docs/stable/simplesamlphp-install), installation guide section 7 if help is needed for generating one. |
| CONFIG_TECHNICALCONTACT_NAME | Administrator | Name of the Admin of Rainy Clouds, 42nd of Their Name, Breaker of Sanity, and ~~Destroyer~~ Protector of the Federation |
| CONFIG_TECHNICALCONTACT_EMAIL | na@example.org | Address of hate mail and applicaton exception logs to send to. Mail support is not yet supported in this container, it is coming soon. Best to turn off mail error reporting option and direct users to the proper email until its implemented. |
| CONFIG_LANGUAGEDEFAULT | en | -- |
| CONFIG_TIMEZONE | America/Chicago | Visit the [php.net man pages](http://php.net/manual/en/timezones.america.php) for the options, the one linked is for 'Murica. |
| CONFIG_TEMPDIR | /tmp/simplesaml | -- |
| CONFIG_SHOWERRORS | true | Shows detailed errors to the user if one occurs. |
| CONFIG_ERRORREPORTING | true | Allow users to send reports from SimpleSAMLphp to the technicalcontact. Not yet working. |
| CONFIG_ADMINPROTECTINDEXPAGE | false | Require admin password to access frontpage_federation index |
| CONFIG_ADMINPROTECTMETADATA | false | Require admin password to access public IdP metadata |
| CONFIG_DEBUG | false | Enable debugging to logs, requires CONFIG_LOGGINGLEVEL be set to DEBUG |
| CONFIG_LOGGINGLEVEL | NOTICE | Options are ERR, WARNING, NOTICE, INFO, DEBUG |
| CONFIG_LOGGINGHANDLER | file | Default different from official default of syslog due to systemd not running in containers. |
| CONFIG_LOGFILE | simplesamlphp.log | -- |
| CONFIG_ENABLESAML20IDP | false | Enable SAML20 IdP |
| CONFIG_ENABLESHIB13IDP | false | Enable Shibboleth13 IdP |
| CONFIG_SESSIONDURATION | 8 * (60 * 60) | -- |
| CONFIG_SESSIONDATASTORETIMEOUT | (4 * 60 * 60) | -- |
| CONFIG_SESSIONSTATETIMEOUT | (60 * 60) | -- |
| CONFIG_SESSIONCOOKIELIFETIME | 0 | -- |
| CONFIG_SESSIONREMEMBERMEENABLE | false | -- |
| CONFIG_SESSIONREMEMBERMECHECKED | false | -- |
| CONFIG_SESSIONREMEMBERMELIFETIME | (14 * 86400) | -- |
| CONFIG_SESSIONCOOKIESECURE | false | -- |
| CONFIG_ENABLEHTTPPOST | false | -- |
| CONFIG_THEMEUSE | default | -- |
| CONFIG_STORETYPE | phpsession | If using `memcache` option, CONFIG_MEMCACHESTORESERVERS and CONFIG_MEMCACHESTOREPREFIX will need to be set. |
| CONFIG_MEMCACHESTORESERVERS | See Format Below* | Was unable to make this an easy variable, the format of the array is given below in a 2x2 example. Keep the format but replace the hostnames. |
| CONFIG_MEMCACHESTOREPREFIX | null | `simplesamlphp` can be used in most cases. |
| WWW_INDEX | core/frontpage_welcome.php | Page to direct to if a user accesses the IdP/SP directly. Can be set to an authentication test for example. |
| OPENLDAP_TLS_REQCERT | demand | As per ldap man pages, Options are `never` `allow` `try` `demand`. If using Active Directory or OpenLDAP with TLS, logins will be rejected if the directory certificate is self-signed with the default `demand` value. This can be set to `never` for testing purposes. Refer to ldap.conf man page section 5 for more details. |

Default CONFIG_MEMCACHESTORESERVERS format, 2 pair of 2 example. Use this template and replace the hostnames. Check compose file for usage example:
```console
    'memcache_store.servers' => array(\n        array(\n             array('hostname' => 'mc_a1'),\n             array('hostname' => 'mc_a2'),\n        ),\n        array(\n             array('hostname' => 'mc_b1'),\n             array('hostname' => 'mc_b2'),\n        ),
```

### Maintenance

This is being actively maintained and is running in production.
Please [create an issue](https://github.com/Venator-Fox/docker-simplesamlphp/issues) if needed or if additional variables/features are desired.

### Todos
 - Figure out logging to docker stdio
 - Add support for mail to be sent during exceptions
 - Add ability for stats to be sent to docker stdio or to mounted file

### More Complex/Practical Compose Example, IdP SSL Termination with HAProxy
This example will run HAProxy with snakeoil SSL termination for https://localhost.
It will also bring up 4 memcached containers, 2 pairs of 2, for phpsession.
This is useful for running a SimpleSAMLphp cluster via some orchestration service such as Rancher.

Since SimpleSAMLphp will not care about the webroot, an entry to the hosts file can be added to whatever for testing. 
Be sure to adjust the HOST environment variable below for whatever localhost self-signed certificate desired.
Of course in production use a real CA, like LetsEncrypt.

This will be more in line with what would be seen in a production environment. (minus the demo 123 password, salt, etc)
Note the choices of volume mounts of what to keep ephemeral, and what to keep persistant.
The more volumes, the more manual upgrades might be.
Check SimpleSAMLphp's upgrade notes to see if updates occured in a specified directory.

Note that running this compose file will create files in `/opt/docker/volumes/` on your host.
You can remove this after toying with the example.

Run the following two commands:
```console
mkdir -p /opt/docker/volumes/idp-haproxy/ssl
docker run --rm -v /opt/docker/volumes/idp-haproxy/ssl:/ssl -e HOST=localhost -e TYPE=pem project42/selfsignedcert
```

Save the `haproxy.cfg` to `/opt/docker/volumes/idp-haproxy/haproxy.cfg`

Finally, save the v2 compose file as `docker-compose.yml` somewhere.
Run `docker-compose -f docker-compose.yml up` to bring the stack up.
After install, visit https://localhost (or whatever URL you chose)
Use `docker-compose -f docker-compose.yml down` to destroy containers after playing.
