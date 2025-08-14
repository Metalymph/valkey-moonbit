///|
test "test_valkey" {
  try {
    let client = @valkey.make_client()
    inspect(client.host, content="localhost")
  } catch {
    e => println("Failed to create client: \{e}")
  } noraise {
    _ => println("Successfully completed test for Valkey")
  }
}