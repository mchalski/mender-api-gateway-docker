#!/bin/sh

CERT_PATH=/var/www/mendersoftware/cert/cert.crt
KEY_PATH=/var/www/mendersoftware/cert/private.key

waserr=0
for f in $CERT_PATH $KEY_PATH; do
    if ! test -e $f; then
        echo "required file $f not found in container"
        waserr=1
    fi
done

if [ "$waserr" = "1" ]; then
   echo "certificate or key not found, exiting"
   exit 1
fi

if [ -n "$ALLOWED_HOSTS" ]; then
    sed -i -e "s/[@]ALLOWED_HOSTS[@]/$ALLOWED_HOSTS/" /usr/local/openresty/nginx/conf/nginx.conf
else
   echo "ALLOWED_HOSTS undefined, exiting"
   exit 1
fi

if [ -n "$HAVE_MULTITENANT" ]; then
    ln -s /usr/local/openresty/nginx/conf/tenantadm.nginx.conf /usr/local/openresty/nginx/conf/optional/endpoints/tenantadm.nginx.conf
fi

DNS_NAMES=${DNS_NAMES:-mender-useradm mender-inventory mender-deployments mender-device-auth mender-device-adm}

echo "setting up automatic reload on host IP address changes for DNS names: $DNS_NAMES"

./reload-when-hosts-changed $DNS_NAMES &

exec /usr/local/openresty/bin/openresty -g "daemon off;" $*
