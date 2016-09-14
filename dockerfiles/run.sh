docker rm -f grafana
docker run -it \
   -e PROMETHEUS_HOST=10.3.10.33 \
   -e PROMETHEUS_PORT=9090 \
   --net=host \
   --entrypoint=bash \
   --name=grafana \
   centos7-grafana-3.1.1

  # -v /data/grafana:/data/grafana \
