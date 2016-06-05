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
  * at: point of interest, latest, earliest, or a number, default latest
  * max_offsets: how many offsets to return, integer, default 1

## Fetch messages

    GET   /api/v1/messages/:topic/:partition/:offset

Optional parameters:
  * max_wait_time: maximum time in ms to wait for the response, default 1000
  * min_bytes: minimum bytes to accumulate in the response, default 1
  * max_bytes: maximum bytes to fetch, default 100 kB

## Produce messages

    POST  /api/v1/messages/:topic/:partition

Use "Content-type: application/binary".  
Key is supplied as query parameter "key".  
Value is request body.  

Example with cURL:

    curl -X POST localhost:4000/api/v1/messages/kastlex/0 -H "Content-type: application/binary" -d 1
