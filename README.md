# KastleX - Kafka REST Proxy in Elixir
Kastle is a REST interface to Kafka cluster, powered by [Brod](https://github.com/klarna/brod) and [Phoenix framework](http://www.phoenixframework.org/).

See also [Kastle](https://github.com/klarna/kastle).

So far one can only query topics metadata.

# Get started

    mix deps.get
    mix phoenix.server

By default KastleX will try to connect to kafka at localhost:9092.

Default port is 4000.

# API

    GET  /api/v1/topics
    GET  /api/v1/topics/:topic
