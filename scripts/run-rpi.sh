#!/bin/bash
# Copyright (c) Mainflux
# SPDX-License-Identifier: Apache-2.0

###
# Runs all Mainflux microservices (must be previously built and installed).
#
# Expects that PostgreSQL and needed messaging DB are alredy running.
# Additionally, MQTT microservice demands that Redis is up and running.
#
###

BUILD_DIR=../build

# Kill all mainflux-* stuff
function cleanup {
    pkill mainflux
    pkill nats
}

###
# NATS
###
nats-server &
counter=1
until fuser 4222/tcp 1>/dev/null 2>&1;
do
    sleep 0.5
    ((counter++))
    if [ ${counter} -gt 10 ]
    then
        echo "NATS failed to start in 5 sec, exiting"
        exit 1
    fi
    echo "Waiting for NATS server"
done


###
# Things
###
MF_THINGS_LOG_LEVEL=info MF_THINGS_SINGLE_USER_EMAIL=edge@email.com MF_THINGS_SINGLE_USER_TOKEN=12345678   MF_THINGS_HTTP_PORT=8182 MF_THINGS_AUTH_GRPC_PORT=8183 MF_THINGS_AUTH_HTTP_PORT=8989 $BUILD_DIR/mainflux-things &

###
# MQTT
###
MF_MQTT_ADAPTER_LOG_LEVEL=info MF_THINGS_AUTH_GRPC_URL=localhost:8183 MF_MQTT_ADAPTER_MQTT_PORT=1884 MF_MQTT_BROKER_PORT=1883 $BUILD_DIR/mainflux-mqtt &

###
# Influxdb writer
###
MF_INFLUX_WRITER_LOG_LEVEL=debug MF_INFLUX_WRITER_CONFIG_PATH=../config/config.toml MF_INFLUX_WRITER_PORT=8900 MF_INFLUX_WRITER_DB_PORT=8086 MF_INFLUX_WRITER_DB_USER=mainflux MF_INFLUX_WRITER_DB_PASS=mainflux MF_INFLUX_WRITER_CONTENT_TYPE=application/senml+json $BUILD_DIR/mainflux-influxdb-writer &


trap cleanup EXIT

while : ; do sleep 1 ; done
