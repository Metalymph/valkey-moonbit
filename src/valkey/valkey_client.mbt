///|
/// Error type for Valkey client operations.
///
/// Constructors:
///
/// * `CommandParse(@string.View)` : Error parsing a Valkey command with the
///   problematic command string.
/// * `GitHubCmdListFetching(@string.View)` : Error fetching command list from
///   GitHub repository with the error message.
/// * `InvalidHost(@string.View)` : Error for invalid host configuration with
///   the invalid host string.
/// * `IOError(@fs.IOError)` : File system I/O error wrapped from the underlying
///   file system operation.
///
/// Example:
///
/// ```moonbit
/// try {
///   let client = @valkey.make_client(
///     host="possibly-invalid-url"
///   )
/// } catch {
///   @valkey.ValkeyError::InvalidHost(host) => 
///     println("Invalid host: \{host}")
///   @valkey.ValkeyError::IOError(io_err) => 
///     println("IO error: \{io_err}")
///   @valkey.ValkeyError::CommandParse(cmd) => 
///     println("Command parse error: \{cmd}")
///   @valkey.ValkeyError::GitHubCmdListFetching(msg) => 
///     println("GitHub fetch error: \{msg}")
/// }  noraise {
///   client => println("Successfully created Valkey client: \{client}")
/// }
/// ```
///
suberror ValkeyError {
  GitHubCmdAPI(@string.View)
  InvalidHost(@string.View)
  InvalidPort(@string.View)
  IOError(String)
} derive(Show)

///|
/// Client for connecting to and interacting with Valkey servers.
///
/// Since this struct is not marked with any visibility modifier, it is abstract
/// and users can only pass its value around but cannot directly construct or
/// destruct it.
///
/// Example:
///
/// ```moonbit
/// let _ = make_client()
/// ```
///
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
/// let _ = make_client(
///   host="https://my-valkey-server-host", 
///   tls=true
/// )
/// ```
///
pub fn make_client(
  host~ : @string.View = "localhost",
  port~ : UInt16 = 6379,
  logger~ : &Logger = ValkeyLogger::new(),
  tls~ : Bool = false,
  github_cmds_repo~ : String = "https://api.github.com/repos/valkey-io/valkey/contents/src/commands?ref=unstable",
) -> ValkeyClient raise ValkeyError {
  let protocol : String = if tls { "https" } else { "http" }
  let host_port = validatePort(port~)
  let host_url : String = match host {
    "localhost" | "127.0.0.1" => "\{protocol}://127.0.0.1"
    _ => validateHost(host~).to_string()
  }
  {
    host: host_url,
    port: host_port,
    logger,
    tls,
    github_cmds_repo,
    connections_pool: make_connection_pool(url=host_url, tls~, logger~),
    orphan_conn: None,
  }
}

///|
pub fn ValkeyClient::full_url(self : ValkeyClient) -> String {
  if self.tls {
    return "https://\{self.host}:\{self.port}"
  }
  return "http://\{self.host}:\{self.port}"
}

///|
pub async fn ValkeyClient::run(
  self : ValkeyClient,
  force_cmd_reload~ : Bool = false,
) -> Unit raise ValkeyError {
  if force_cmd_reload || !@fs.path_exists("valkey_commands.mbt") {
    self.load_commands()
  }
  self.connections_pool.connect_pool()
}

///|
pub async fn ValkeyClient::with_connection(
  self : ValkeyClient,
  executor : async (VKConnection) -> Unit raise ValkeyError,
) -> Self raise ValkeyError {
  self.orphan_conn = Some(
    VKConnection::new(url=self.full_url(), tls=self.tls, logger=self.logger),
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
/// * The temporary directory "json_commands" creation fails (wraps `IOError`)
/// * The HTTP request to fetch commands from GitHub fails
/// * Command parsing or generation encounters an error
///
fn ValkeyClient::load_commands(self : ValkeyClient) -> Unit raise ValkeyError {
  if !@fs.path_exists("json_commands") {
    self.logger.write_string("Creating tmp directory 'json_commands'...")
    @fs.create_dir("json_commands") catch {
      @fs.IOError(e) => {
        self.logger.write_string("Failed to create directory 'tmp': \{e}")
        raise IOError(e)
      }
    }
  }
  @mio.run(fn() {
    self.logger.write_string(
      "Fetching commands from GitHub Valkey official repository...",
    )

    // Fetching GitHub Repo Commands from APIs
    match (try? @mio.get(self.github_cmds_repo)) {
      Ok(response) => {
        if response.statusCode != 200 {
          self.logger.write_string(
            "Failed to fetch commands: status code \{response.statusCode}",
          )
        }

        // Fetches commands from GitHub and parses them (with internal download)
        try
          parse_commands_from_github(response.unwrap_json(), self.logger)
        catch {
          e => {
            self.logger.write_string(
              "Failed parsing commands from GitHub: \{e}",
            )
            return
          }
        } noraise {
          _ => self.logger.write_string("Successfully fetched commands")
        }

        // Delete previous commands soruce file"
        self.logger.write_string("Building commands...")
        if !@fs.path_exists("valkey_commands.mbt") {
          self.logger.write_string(
            "Cleaning previous \"valkey_commands.mbt\" source file...",
          )
        }

        // TODO: build commands

        // Writes all the commands into the source file
        @fs.write_string_to_file("valkey_commands.mbt", "") catch {
          @fs.IOError(e) => {
            self.logger.write_string("Failed to create directory 'tmp': \{e}")
            return
          }
        }
      }
      // response.unwrap_json()
      Err(e) =>
        self.logger.write_string(
          "Error fetching commands from GitHub Valkey official repository (): \{e}",
        )
    }
  })

  // Clean up the temporary directory
  @fs.remove_dir("json_commands") catch {
    @fs.IOError(e) => {
      self.logger.write_string(
        "Failed to remove 'json_commands' directory: \{e}",
      )
      raise IOError(e)
    }
  }
}
