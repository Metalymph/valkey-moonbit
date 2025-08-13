
///|
test "test_valkeyclient_new" {
  let client = @valkey.make_client()
  inspect(client.host, content="localhost")
}