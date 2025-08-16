# metalymph/valkey-moonbit

A Moonbit client library for Valkey.

#### ⚠️ this library is under very active development and is not ready to use. I hope it will be ready as soon as possible for a v0.1.

To add it to your Moonbit project call the following command in your terminal:
`moon add metalymph/valkey-moonbit`

Valkey commands are generated from the [official source on GitHub](https://github.com/valkey-io/valkey/tree/unstable/src/commands) and rebuilt at library first usage or if forced via `start` method.

To start using valkey-moonbit you need to create a client, and use it as command prompt dispatcher. 
Once a client is instantiated, it allocates a connection pool which serves as the main connections resource to concurrently call one or more commands.
In the following code we're instantiating a client and directly reserve a custom separate connection to execute random code within it's controlled state via closure function.
```moon
run(fn() -> Unit {
  make_client().with_connection(async fn(_) raise Error {
    // Perform operations with the connection
    fail("Check error generation")
  }) catch {
    e => println("Error using connection: \{e}")
  }
})
```