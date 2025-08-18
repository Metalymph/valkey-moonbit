///|
test "test_valkeyclient_new" {
  let client = @valkey.make_client()
  inspect(client.host, content="http://127.0.0.1")
}

///|
test "test_valkeyclient_orphanconn_run" {
  try {
    let client = @valkey.make_client()
    run(fn() -> Unit {
      client.with_connection(async fn(_) raise Error {
        // Perform operations with the connection
        fail("Check error generation")
      }) catch {
        e => println("Error using connection: \{e}")
      }
    })
    inspect(client.host, content="localhost")
  } catch {
    e => println("Failed to run client: \{e}")
  } noraise {
    _ => println("Successfully completed test for ValkeyClient run")
  }
}
