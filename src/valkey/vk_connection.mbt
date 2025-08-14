///|
/// Represents a single connection to a Valkey server
/// Holds connection state and provides methods for communication
///
pub struct VKConnection {
  /// The full URL including protocol, host and port
  url : String
  /// Whether the connection uses TLS/SSL
  tls : Bool
  /// The connection status
  mut is_connected : Bool
  /// Logger instance for connection-specific logging
  logger : &Logger
}

///|
/// Creates a new Connection instance with the specified configuration
///
/// Parameters:
/// * `url` : The full URL including protocol, host and port
/// * `tls` : Whether to use TLS/SSL for the connection
/// * `logger` : Logger instance for connection-specific logging
///
/// Returns a new Connection instance in a disconnected state
///
pub fn VKConnection::new(
  url~ : String,
  tls~ : Bool,
  logger~ : &Logger,
) -> VKConnection {
  { url, tls, is_connected: false, logger }
}

///|
/// Establishes a connection to the Valkey server
///
/// Returns Unit on success, raises ValkeyError on failure
///
async fn VKConnection::connect(self : VKConnection) -> Unit raise ValkeyError {
  self.logger.write_string("Connecting to \{self.url}...")
  match (try? @mio.get(self.url)) {
    Ok(response) =>
      if response.statusCode == 200 {
        let new_conn = self
        new_conn.is_connected = true
        new_conn.logger.write_string("Connected successfully")
      } else {
        self.logger.write_string(
          "Connection failed with status code \{response.statusCode}",
        )
        raise GitHubCmdAPI("Connection failed")
      }
    Err(e) => {
      self.logger.write_string("Connection failed: \{e}")
      raise GitHubCmdAPI(e.to_string())
    }
  }
}

///|
/// Closes the connection to the Valkey server
///
fn VKConnection::close(self : VKConnection) -> Unit {
  if !self.is_connected {
    return
  }
  let new_conn = self
  new_conn.is_connected = false
  new_conn.logger.write_string("Connection closed")
}
