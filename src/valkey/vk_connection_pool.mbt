///|
/// A pool of Valkey server connections
///
struct VKConnectionPool {
  /// List of available connections
  connections : Array[VKConnection]
  /// The maximum number of connections in the pool
  pool_size : UInt16
  /// Logger instance for pool-specific logging
  logger : &Logger
}

///|
/// Creates a new connection pool with the specified number of connections
///
/// Parameters:
/// * `size` : Number of connections to create in the pool (default is 8)
/// * `url` : The URL for the Valkey server
/// * `tls` : Whether to use TLS/SSL for the connections
/// * `logger` : Logger instance for logging
///
/// Returns a new ConnectionPool with the specified number of connections
/// All connections are initially in a disconnected state
///
fn make_connection_pool(
  size~ : UInt16 = 8,
  url~ : String,
  tls~ : Bool,
  logger~ : &Logger,
) -> VKConnectionPool {
  let connections = Array::new()
  let mut i : UInt16 = 0
  while i < size {
    let conn = VKConnection::new(url~, tls~, logger~)
    connections.push(conn)
    i = i + 1
  }
  { connections, pool_size: size, logger }
}

///|
/// Asynchronously connects all connections in the pool
///
/// Returns the ConnectionPool with all connections in connected state
/// Raises ValkeyError if any connection fails
///
async fn VKConnectionPool::connect_pool(
  self : VKConnectionPool,
) -> Unit raise ValkeyError {
  let new_connections : Array[VKConnection] = Array::new()
  let mut i : UInt16 = 0
  while i < self.pool_size {
    match self.connections.get(i.to_int()) {
      Some(conn) => {
        conn.connect()
        new_connections.push(conn)
      }
      None => {
        self.logger.write_string("Failed to get connection at index \{i}")
        raise GitHubCmdAPI("Failed to get connection")
      }
    }
    i = i + 1
  }
}
