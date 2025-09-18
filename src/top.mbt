///|
fn run_example() -> Unit {
  match (try? @valkey.make_client()) {
    Ok(client) => println("ℹ️ Client started 🐇: \{client.host}")
    Err(e) => println("‼️ Failed to create client \{e}")
  }
}

///|
fn main {
  run_example()
}
