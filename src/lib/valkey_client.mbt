///|
suberror ValkeyError {
  CommandParse(@string.View)
  GitHubCmdListFetching(@string.View)
  InvalidHost(@string.View)
  IOError(@fs.IOError)
}

///|
pub struct ValkeyClient {
  host : String
  port : UInt16
  logger : &Logger
  tls : Bool
  github_cmds_repo : String
  connections_pool : VKConnectionPool
  mut orphan_conn : VKConnection?
}

///|
/// Creates a new ValkeyClient instance with the specified configuration
/// parameters.
///
/// Parameters:
///
/// * `host` : The hostname or URL for the Valkey server. Defaults to
///   "localhost". If set to "localhost", it will be converted to the
///   appropriate protocol URL (http://127.0.0.1 or https://127.0.0.1). For
///   other values, must be a valid URL starting with "http://" or "https://".
/// * `port` : The port number for the Valkey server connection. Defaults to
///   6379.
/// * `logger` : A logger instance for recording client operations and debugging
///   information.
/// * `tls` : Whether to use TLS/SSL for secure connections. Defaults to false.
///   When true, uses "https" protocol; when false, uses "http" protocol.
/// * `github_cmds_repo` : The GitHub API URL for fetching Valkey command
///   definitions. Defaults to the official Valkey repository's commands
///   directory on the unstable branch.
///
/// Returns a new `ValkeyClient` instance configured with the provided
/// parameters.
///
/// Throws an error of type `ValkeyError::InvalidHost` if the provided host is
/// not "localhost" and is not a valid URL starting with "http://" or
/// "https://".
///
/// Example:
///
/// ```moonbit
/// let logger = Logger::new()
/// let client = ValkeyClient::new(logger~)
/// let secure_client = ValkeyClient::new(
///   host="https://my-valkey-server.com", 
///   port=6380, 
///   logger~, 
///   tls=true
/// )
/// ```
///
pub fn ValkeyClient::new(
  host~ : @string.View = "localhost",
  port~ : UInt16 = 6379,
  logger~ : &Logger,
  tls~ : Bool = false,
  github_cmds_repo~ : String = "https://api.github.com/repos/valkey-io/valkey/contents/src/commands?ref=unstable",
) -> ValkeyClient raise ValkeyError {
  let protocol : String = if tls { "https" } else { "http" }
  let host_url : String = match host {
    "localhost" | "127.0.0.1" => "\{protocol}://127.0.0.1"
    url_string => validateURL(url_string).to_string()
  }
  {
    host: host_url,
    port,
    logger,
    tls,
    github_cmds_repo,
    connections_pool: make_connection_pool(url=host_url, tls~, logger~),
    orphan_conn: None,
  }
}

///|
pub async fn ValkeyClient::run(
  self : ValkeyClient,
  force_cmd_fetching~ : Bool = false,
) -> Unit raise ValkeyError {
  if force_cmd_fetching || !@fs.path_exists("valkey_commands.mbt") {
    self.build_commands()
  }
  self.connections_pool.connect_pool()
}

///|
pub async fn ValkeyClient::with_connection(
  self : ValkeyClient,
  executor : async (VKConnection) -> Unit raise ValkeyError,
) -> Self raise ValkeyError {
  self.orphan_conn = Some(
    VKConnection::new(url=self.host, tls=self.tls, logger=self.logger),
  )
  self.orphan_conn.unwrap().connect()
  defer self.orphan_conn.unwrap().close()
  executor(self.orphan_conn.unwrap())
  self
}

///|
/// Builds and generates Valkey commands by fetching command definitions from
/// the GitHub repository and creating local command files.
///
/// Parameters:
///
/// * `self` : The ValkeyClient instance containing configuration for the GitHub
///   repository URL and logger.
///
/// Throws an error of type `ValkeyError` if:
///
/// * The temporary directory creation fails (wraps `IOError`)
/// * The HTTP request to fetch commands from GitHub fails
/// * Command parsing or generation encounters an error
///
/// Example:
///
/// ```moonbit
/// let logger = Logger::new()
/// let client = ValkeyClient::new(logger~)
/// client.build_commands()
/// ```
///
fn ValkeyClient::build_commands(self : ValkeyClient) -> Unit raise ValkeyError {
  if !@fs.path_exists("json_commands") {
    self.logger.write_string("Creating directory 'tmp'...")
    match (try? @fs.create_dir("json_commands")) {
      Ok(_) => self.logger.write_string("Creating directory 'tmp'...")
      Err(e) => {
        self.logger.write_string("Failed to create directory 'tmp': \{e}")
        raise IOError(e)
      }
    }
  }
  @mio.run(fn() {
    self.logger.write_string(
      "Fetching commands from GitHub Valkey official repository...",
    )
    match (try? @mio.get(self.github_cmds_repo)) {
      Ok(response) => {
        if response.statusCode != 200 {
          self.logger.write_string(
            "Failed to fetch commands: status code \{response.statusCode}",
          )
        }
        parse_commands(response.unwrap_json())
        self.logger.write_string("Building commands...")
        generate_commands()
      }
      // response.unwrap_json()
      Err(e) =>
        self.logger.write_string(
          "Error fetching commands from GitHub Valkey official repository (): \{e}",
        )
    }
  })
}

fn ValkeyClient::parse_commands(github_payload: Json) -> Iter[Command] raise ValkeyError {
  let commands = Array[Command]::new()

  commands
}

fn Iter::generate_commands(self: Iter[Command]) -> Unit raise ValkeyError {
  // This function should generate commands based on the fetched data
  // For now, it is a placeholder
  println("Generating commands...")
  // Implement command generation logic here
}
