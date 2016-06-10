# KastleX - Kafka REST Proxy in Elixir
Kastle is a REST interface to Kafka cluster, powered by [Brod](https://github.com/klarna/brod) and [Phoenix framework](http://www.phoenixframework.org/).

See also [Kastle](https://github.com/klarna/kastle).

# Get started

    mix deps.get
    mix phoenix.server

By default KastleX will try to connect to kafka at localhost:9092.

Default port is 4000.

# API

## Topics metadata

    GET   /api/v1/topics
    GET   /api/v1/topics/:topic

## Brokers metadata

    GET   /api/v1/brokers

## Query available offsets for partition.

    GET   /api/v1/offsets/:topic/:partition

Optional parameters:
  * `at`: point of interest, `latest`, `earliest`, or a number, default `latest`
  * `max_offsets`: how many offsets to return, integer, default 1

## Fetch messages

    GET   /api/v1/messages/:topic/:partition/:offset

Optional parameters:
  * `max_wait_time`: maximum time in ms to wait for the response, default 1000
  * `min_bytes`: minimum bytes to accumulate in the response, default 1
  * `max_bytes`: maximum bytes to fetch, default 100 kB

## Produce messages

    POST  /api/v1/messages/:topic/:partition

Use `Content-type: application/binary`.  
Key is supplied as query parameter `key`.  
Value is request body.  

## Authentication
Authentication is a courtesy of [Guardian](https://github.com/ueberauth/guardian).

### Generating tokens
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
First generate an admin token with all permissions:

    subject = %{user: "admin"}
    perms = %{admin: Guardian.Permissions.max}
    {:ok, token, _} = Guardian.encode_and_sign(subject, :token, perms: perms)

Then you can use it to issue other tokens since it includes :issue_token permission:

    export JWT_ADMIN='token generated above'
    JWT_CLIENT=$(curl -s -H "Authorization: $JWT_ADMIN" localhost:4000/api/v1/tokens -H "Content-type: application/binary" -d '{"user":"me","topics":"*","perms":{"client":["produce", "fetch", "offsets", "get_topic"]}}' | jq .token | tr -d \")
    curl -H "Authorization: $JWT_ADMIN" localhost:4000/api/v1/brokers
    curl -H "Authorization: $JWT_ADMIN" localhost:4000/api/v1/topics
    curl -H "Authorization: $JWT_CLIENT" localhost:4000/api/v1/topics/my-topic
    curl -H "Authorization: $JWT_CLIENT" localhost:4000/api/v1/messages/my-topic/0 -H "Content-type: application/binary" -d 1
    curl -H "Authorization: $JWT_CLIENT" localhost:4000/api/v1/messages/my-topic/0?key=2 -H "Content-type: application/binary" -d 2
    curl -H "Authorization: $JWT_CLIENT" localhost:4000/api/v1/messages/my-topic/0/0
