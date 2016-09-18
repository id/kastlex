# KastleX - Kafka REST Proxy in Elixir
Kastle is a REST interface to Kafka cluster, powered by [Brod](https://github.com/klarna/brod) and [Phoenix framework](http://www.phoenixframework.org/).

See also [Kastle](https://github.com/klarna/kastle).

# Get started

    mix deps.get
    mix phoenix.server

To start with an interactive shell:

    iex --sname kastlex -S mix phoenix.server

By default KastleX will try to connect to kafka at localhost:9092 and to zookeeper on localhost:2181.

Default port is 8092.

# API

## Topics metadata

    GET   /api/v1/topics
    ["kastlex"]

    GET   /api/v1/topics/:topic
    {"topic":"kastlex","partitions":[{"replicas":[0],"partition":0,"leader":0,"isr":[0]}],"config":{}}

## Brokers metadata

    GET   /api/v1/brokers
    [{"port":9092,"id":0,"host":"localhost","endpoints":["PLAINTEXT://127.0.0.1:9092"]}]

    GET   /api/v1/brokers/:broker_id
    {"port":9092,"id":0,"host":"localhost","endpoints":["PLAINTEXT://127.0.0.1:9092"]}

## Consumer groups

    GET   /api/v1/consumers
    ["console-consumer-25992"]

    GET   /api/v1/consumers/:group_id
    {
        "protocol": "range",
        "partitions": [
            {
                "topic": "kastlex",
                "partition": 0,
                "offset": 20,
                "metadata": "",
                "high_wm_offset": 20,
                "expire_time": 1473714215481,
                "commit_time": 1473627815481
            }
        ],
        "members": [
            {
                "subscription": {
                    "version": 0,
                    "user_data": "",
                    "topics": [
                        "kastlex"
                    ]
                },
                "session_timeout": 30000,
                "member_id": "consumer-1-ea5aa1bc-6b14-488f-88f1-26edb2261786",
                "client_id": "consumer-1",
                "client_host": "/127.0.0.1",
                "assignment": {
                    "version": 0,
                    "user_data": "",
                    "topic_partitions": {
                        "kastlex": [
                            0
                        ]
                    }
                }
            }
        ],
        "leader": "consumer-1-ea5aa1bc-6b14-488f-88f1-26edb2261786",
        "group_id": "console-consumer-66960",
        "generation_id": 1
    }


## Query available offsets for partition.

    GET   /api/v1/offsets/:topic/:partition
    [20]

Optional parameters:
  * `at`: point of interest, `latest`, `earliest`, or a number, default `latest`
  * `max_offsets`: how many offsets to return, integer, default 1

## Fetch messages

    GET   /api/v1/messages/:topic/:partition/:offset
    {
      "size": 29,
      "messages": [
        {
          "value": "foo",
          "size": 17,
          "offset": 20,
          "key": null,
          "crc": -91546804
        }
      ],
      "highWmOffset": 21,
      "errorCode": "no_error"
    }

Optional parameters:
  * `max_wait_time`: maximum time in ms to wait for the response, default 1000
  * `min_bytes`: minimum bytes to accumulate in the response, default 1
  * `max_bytes`: maximum bytes to fetch, default 100 kB

## Produce messages

    POST  /api/v1/messages/:topic/:partition

Use `Content-type: application/binary`.  
Key is supplied as query parameter `key`.  
Value is request body.  
Successful response: HTTP Status 204 and empty body.  

## List under-replicated partitions

    GET   /api/v1/urp
    GET   /api/v1/urp/:topic

# Authentication
Authentication is a courtesy of [Guardian](https://github.com/ueberauth/guardian).

## Generating tokens
Access to topics in encoded in the "subject" field of JWT.

Admin access:

    subject = %{user: "admin"}
    perms = %{admin: Guardian.Permissions.max}
    {:ok, token, _} = Guardian.encode_and_sign(subject, :token, perms: perms)

Read only access to topics my-topic1 and my-topic2:

    subject = %{user: "user", topics: "my-topic1,my-topic2"]}
    perms = %{client: [:get_topic, :offsets, :fetch]}
    {:ok, token, _} = Guardian.encode_and_sign(subject, :token, perms: perms)

Read/Write access to all topics:

    subject = %{user: "user", topics: "*"}
    perms = %{client: [:get_topic, :offsets, :fetch, :produce]}
    {:ok, token, _} = Guardian.encode_and_sign(subject, :token, perms: perms)

## cURL examples
First generate an token with all permissions:

    subject = %{user: "admin", topics: "*"}
    perms = %{admin: Guardian.Permissions.max, client: Guardian.Permissions.max}
    {:ok, token, _} = Guardian.encode_and_sign(subject, :token, perms: perms)

Then try some stuff

    export JWT='token generated above'
    curl -H "Authorization: $JWT" localhost:4000/api/v1/brokers
    curl -H "Authorization: $JWT" localhost:4000/api/v1/topics
    curl -H "Authorization: $JWT" localhost:4000/api/v1/topics/my-topic
    curl -H "Authorization: $JWT" localhost:4000/api/v1/messages/my-topic/0 -H "Content-type: application/binary" -d 1
    curl -H "Authorization: $JWT" localhost:4000/api/v1/messages/my-topic/0?key=2 -H "Content-type: application/binary" -d 2
    curl -H "Authorization: $JWT" localhost:4000/api/v1/messages/my-topic/0/0

# Deployment to production

## Generate a JWK
In Kastlex shell

    jwk = JOSE.JWK.generate_key({:ec, :secp256r1})
    JOSE.JWK.to_file("secret.jwk", jwk)

## Generate a secret key base

    printf "%s" $(openssl rand -base64 64) > secret.key

## Set the following varibles for Kastlex environment

    KASTLEX_SECRET_KEY_FILE=/path/to/secret.key
    KASTLEX_JWK_FILE=/path/to/secret.jwk
    KASTLEX_KAFKA_CLUSTER=kafka-host1:9092,kafka-host2:9092
    KASTLEX_ZOOKEEPER_CLUSTER=zk-host1:2181,zk-host2:2181

## (Optional) Set custom HTTP port

    KASTLEX_HTTP_PORT=8092

## (Optional) Enable HTTPS
Variables are given with their default values except for KASTLEX_USE_HTTPS which is disabled by default.

So if you just set `KASTLEX_USE_HTTPS=true`, Kastlex will be accepting TLS connection on 8093 and use certificates in /etc/kastlex/ssl.

    KASTLEX_USE_HTTPS=true
    KASTLEX_HTTPS_PORT=8093
    KASTLEX_CERTFILE=/etc/kastlex/ssl/server.crt
    KASTLEX_KEYFILE=/etc/kastlex/ssl/server.key
    KASTLEX_CACERTFILE=/etc/kastlex/ssl/ca-cert.crt

## Building release for production

    MIX_ENV=prod mix compile
    MIX_ENV=prod mix release

## Running release

    rel/kastlex/bin/kastlex console
