#!/bin/bash -e

ADMIN_USER=${ADMIN_USER:-"admin"}
GF_SECURITY_ADMIN_PASSWORD=${GF_SECURITY_ADMIN_PASSWORD:-"admin"}
GRAFANA_PORT=${GRAFANA_PORT:-3000}

change_port(){
    sed -i 's/--HTTP_PORT--/'$GRAFANA_PORT'/g' /grafana.ini
    sed -i 's/--ADMIN_USER--/'$ADMIN_USER'/g' /grafana.ini
    sed -i 's/--GF_SECURITY_ADMIN_PASSWORD--/'$GF_SECURITY_ADMIN_PASSWORD'/g' /grafana.ini
}

check_env_variable() {
    if [[ $PROMETHEUS_HOST ]];
    then echo "PROMETHEUS_HOST is $PROMETHEUS_HOST"; 
    else echo "Need set the Environment Variable \"PROMETHEUS_HOST\"" ; exit 1
    fi
    if [[ $PROMETHEUS_PORT ]];
    then echo "PROMETHEUS_PORT is $PROMETHEUS_PORT"; 
    else echo "Need set the Environment Variable \"PROMETHEUS_PORT\"" ; exit 1
    fi
    if [[ $GF_SECURITY_ADMIN_PASSWORD ]];
    then echo "The password of grafana user was passed!"; 
         echo "ADMIN_PASS=$GF_SECURITY_ADMIN_PASSWORD"
    fi
}

create_grafana_datasource() {
   
    ret="[]"
    for i in {30..0}; do
    	ret=`curl -sX GET  "http://$ADMIN_USER:$GF_SECURITY_ADMIN_PASSWORD@localhost:$GRAFANA_PORT/api/datasources"` || echo '' 
	if [ -n "$ret" ];then
    		echo $ret | grep "\"name\".*prometheus" && echo "prometheus already exists"
		
		break
	else
		echo "grafana init process in progress..."
	fi
	sleep 1
    done

    if [[ "$ret" != "[]" ]];then
	return 0
    fi

    url="http://$PROMETHEUS_HOST:$PROMETHEUS_PORT"
    curl -sX POST -i "http://$ADMIN_USER:$GF_SECURITY_ADMIN_PASSWORD@localhost:$GRAFANA_PORT/api/datasources" \
       -H "Content-Type: application/json" \
       -H "Accept: application/json" \
       -d '{"name": "prometheus",
	    "type": "prometheus",
	    "typeLogoUrl": "public/app/plugins/datasource/prometheus/img/prometheus_logo.svg",
	    "access": "direct",
	    "url": "'"$url"'",
	    "password": "",
	    "user": "",
	    "database": "",
	    "basicAuth": false,
	    "basicAuthUser": "",
	    "basicAuthPassword": "",
	    "withCredentials": false,
	    "isDefault": false}'
}

start_grafana(){
    chown -R grafana:grafana /var/lib/grafana /var/log/grafana

    cmd="exec gosu grafana /usr/sbin/grafana-server \
	--homepath=/usr/share/grafana \
	--config=/grafana.ini \
      	cfg:default.paths.data=/var/lib/grafana   \
      	cfg:default.paths.logs=/var/log/grafana"

    $cmd &
    pid="$!"
    create_grafana_datasource	
    if ! kill -s TERM "$pid" || ! wait "$pid"; then
        echo >&2 'grafana init process failed.'
       	exit 1
    fi
    $cmd
}
 
check_env_variable
change_port
start_grafana
