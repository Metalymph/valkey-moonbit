# metalymph/valkey-moonbit

A Moonbit client library for Valkey.

#### ⚠️ this library is under very active development and is not ready to use. I hope it will be ready as soon as possible for a v0.1.

To add it to your Moonbit project call the following command in your terminal:
`moon add metalymph/valkey-moonbit`

Valkey commands are generated from the [official source on GitHub](https://github.com/valkey-io/valkey/tree/unstable/src/commands) and built at library first usage or if forced via `force_cmd_reload` in `@valkey.make_client` call when instantiating a new client.

#### First steps

To start using valkey-moonbit you need to create a client, and use it as command prompt dispatcher. 
Once a client is instantiated, it allocates a connection pool which serves as the main connections resource to concurrently call one or more commands.
It's also possible to use a single connection to execute a single isolated command or even a `pipeline` (a chained command list which returns a stack of responses.)
In the following code we're instantiating a client and directly reserve a custom separate connection to execute random code within it's controlled state via closure function.
```moon
@valkey.run(fn() -> Unit {
  make_client().with_connection(async fn(_) raise Error {
    // Perform operations with the connection
    fail("Check error generation")
  }) catch {
    e => println("Error using connection: \{e}")
  } noraise {
    _ => println("Successfully executed with connection")
  }
})
```

`with_connection` is responsible to call the passed closure (which can internally execute random code too) and to allocate and cleanup the connection.
In the example above it's been specifically called `@valkey.run`: the reason is that being async context in Moonbit currently delegated to the developer, it would be possible, potentially, that each library implements a different wrapper, maybe not exactly what is needed for a specific use case.

#### Concurrent commands and pipelining

More commands can be called at once using chained *command methods* (`ValkeyClient::ping`, `ValkeyClient.set`, etc...) or a the `pipeline` method which executes all the given commands synchrounosly.

TODO