///|
fn run_example() -> Unit {
  match (try? @valkey.make_client()) {
    Ok(client) => println("Client run! \{client.host}")
    Err(e) => println("Failed to create client \{e}")
  }
}

///|
fn main {
  run_example()
}
