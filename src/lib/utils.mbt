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
///
/// Example:
///
/// ```moonbit
/// let valid_url = validateURL("http://192.168.1.1:6379")
/// // Returns "http://192.168.1.1:6379"
/// // Throws ValkeyError::InvalidHost
/// ```
///
fn validateURL(url : @string.View) -> @string.View raise ValkeyError {
  let sanitizedUrl = url.trim(" ")
  if !sanitizedUrl.has_prefix("http://") && !sanitizedUrl.has_prefix("https://") {
    raise ValkeyError::InvalidHost(sanitizedUrl)
  }
  let ip_and_port = sanitizedUrl.split(":")
  if ip_and_port.count() != 2 {
    raise ValkeyError::InvalidHost(sanitizedUrl)
  }
  let ip = ip_and_port.head().unwrap()
  let ip_parts = ip.split(".")
  if ip_parts.count() != 4 {
    raise ValkeyError::InvalidHost(sanitizedUrl)
  }
  for part in ip_parts {
    match (try? @strconv.parse_uint(part, base=10)) {
      Ok(parsed_int) =>
        if parsed_int > 255 {
          raise ValkeyError::InvalidHost(
            "IP part number in URL \{url} exceed the limit: \{parsed_int}",
          )
        }
      Err(e) => raise ValkeyError::InvalidHost(e.to_string())
    }
  }
  let port = ip_and_port.nth(2).unwrap()
  match (try? @strconv.parse_uint(port, base=10)) {
    Ok(parsed_port) =>
      if parsed_port > 65535 {
        raise ValkeyError::InvalidHost(
          "Port number in URL \{url} exceed the limit: \{parsed_port}",
        )
      }
    Err(e) =>
      raise ValkeyError::InvalidHost(
        "Unvalid port number in URL \{url}: \{e.to_string()}",
      )
  }
  return url
}

///|
async fn parse_commands(
  json : Json,
  logger : &Logger,
) -> Unit raise ValkeyError {
  // TODO: with_task_group
  match json {
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
      ) => download_command_json(filename, url=download_url, logger)
  }
}

///|
async fn download_command_json(
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
      raise ValkeyError::GitHubCmdListFetching(
        "Failed to fetch command file definition for \{json_filename}: \{e}",
      )
  }
}
