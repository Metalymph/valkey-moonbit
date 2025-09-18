///|
pub enum VLLevel {
  // Debug
  Info
  // Warning
  // Error
} derive(Show)

///|
/// A logger implementation for Valkey that adheres to the Logger interface.
/// TODO: Expand logging capabilities (e.g., log to file, different levels)
/// and possibly integrate with existing logging frameworks.
///
pub struct ValkeyLogger {
  mut level : VLLevel
} derive(Show)

///|
pub fn ValkeyLogger::new(level~ : VLLevel = VLLevel::Info) -> ValkeyLogger {
  { level, }
}

///|
impl Logger for ValkeyLogger with write_string(self, msg : String) -> Unit {
  ///|
  println("Valkey (\{self.level}): \{msg}")
}

///|
impl Logger for ValkeyLogger with write_substring(
  self,
  msg : String,
  init : Int,
  end : Int,
) -> Unit {
  ///|
  println(
    "Valkey (\{self.level}): \{msg.view(start_offset=init, end_offset=end)}",
  )
}

///|
impl Logger for ValkeyLogger with write_char(self, c : Char) -> Unit {
  ///|
  println("Valkey (\{self.level}): \{c}")
}

///|
/// Sets the logging level for the ValkeyLogger instance.
///
/// Parameters:
///
/// * `self` : The ValkeyLogger instance to modify.
/// * `level` : The new logging level to set.
///
/// Returns the modified ValkeyLogger instance with the updated logging level.
///
pub fn ValkeyLogger::set_level(self : ValkeyLogger, level : VLLevel) -> Self {
  self.level = level
  self
}
