///|
fn validatePort(port~ : UInt16) -> UInt16 raise ValkeyError {
  if port > 65535 {
    raise ValkeyError::InvalidPort("Port number must be less or equal to 65535")
  }
  port
}

///|
/// Validates and sanitizes a URL string to ensure it contains a valid
/// HTTP/HTTPS endpoint with a proper IPv4 address and port number.
///
/// Parameters:
///
/// * `url` : The URL string to validate, expected to be in the format
///   "http://ip:port" or "https://ip:port".
///
/// Returns the original URL string if validation passes.
///
/// Throws an error of type `ValkeyError::InvalidHost` if:
///
/// * The URL doesn't start with "http://" or "https://"
/// * The URL format is invalid (missing or extra colons)
/// * The IP address doesn't consist of exactly 4 dot-separated parts
/// * Any IP address octet is not a valid number between 0-255
/// * The port number is not a valid integer or exceeds 65535
/// Throws an error of type `ValkeyError::InvalidPort` if the port number is unvalid
///
fn validateHost(host~ : @string.View) -> @string.View raise ValkeyError {
  let sanitizedHost = host.trim(" ")
  if !sanitizedHost.has_prefix("http://") &&
    !sanitizedHost.has_prefix("https://") {
    raise ValkeyError::InvalidHost(sanitizedHost)
  }
  let ip_parts = host.split(".")
  if ip_parts.count() != 4 {
    raise ValkeyError::InvalidHost(sanitizedHost)
  }
  for part in ip_parts {
    match (try? @strconv.parse_uint(part, base=10)) {
      Ok(parsed_int) =>
        if parsed_int > 255 {
          raise ValkeyError::InvalidHost(
            "IP part number in \{host} exceed the limit: \{parsed_int}",
          )
        }
      Err(e) => raise ValkeyError::InvalidHost(e.to_string())
    }
  }
  return host
}

///|
/// Parses a JSON object representing a GitHub repository file and downloads it
/// if it's a Valkey command definition file.
///
/// Parameters:
///
/// * `json` : A JSON object containing file metadata from GitHub's repository
///   API, expected to be an array of objects having fields like "name", "download\_url", and "type".
/// * `logger` : A logger instance used to record download progress and status
///   messages.
///
/// Throws an error of type `ValkeyError` if the download operation fails or if
/// there are issues processing the command file.
///
async fn parse_commands_from_github(
  json : Json,
  logger : &Logger,
) -> Unit raise ValkeyError {
  // TODO: with_task_group
  let json_array = match json {
    Json::Array(arr) => arr
    _ => {
      logger.write_string("Invalid JSON format for GitHub commands")
      raise ValkeyError::GitHubCmdAPI("Invalid JSON format for GitHub commands")
    }
  }

  // Iterates through each JSON object in the array to find the command files
  for json_obj in json_array {
    match json_obj {
      {
        "name": String(filename),
        "path": _,
        "sha": _,
        "size": _,
        "url": _,
        "html_url": _,
        "git_url": _,
        "download_url": String(download_url),
        "type": "file",
        ..
      } if download_url.has_prefix(
          "https://raw.githubusercontent.com/valkey-io/valkey/unstable/src/commands/",
        ) =>
        download_command_json_file_from_github(
          filename,
          url=download_url,
          logger,
        )
      _ =>
        // Skipping non-command json files
        return
    }
  }
}

///|
async fn download_command_json_file_from_github(
  json_filename : @string.View,
  url~ : String = "https://raw.githubusercontent.com/valkey-io/valkey/unstable/src/commands/\{json_filename}",
  logger : &Logger,
) -> Unit raise ValkeyError {
  logger.write_string("Downloading command json file from \{url}...")
  match (try? @mio.download(url, save_path="json_commands/\{json_filename}")) {
    Ok(_) =>
      logger.write_string(
        "Successfully downloaded command file: \{json_filename} into ",
      )
    Err(e) =>
      raise ValkeyError::GitHubCmdAPI(
        "Failed to fetch command file definition for \{json_filename}: \{e}",
      )
  }
}
