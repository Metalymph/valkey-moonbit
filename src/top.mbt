///|
fn run() -> Unit {
  let client = try? @lib.ValkeyClient::new()
  match client {
    Ok(client) => println("Client run! \{client.host}")
    Err(_) => println("Failed to create client")
  }
}
