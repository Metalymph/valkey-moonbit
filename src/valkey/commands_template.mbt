pub struct CmdResponse {
  // Define the structure of the command response
  id: UInt64
  status: UInt16
} derive(Show)

pub fn CmdResponse::new() -> CmdResponse {
  // Initialize a new command response
  { id: 0, status: 200 }
}

pub enum Command {
  // Define your commands here
  // Example: Ping, Set, Get, etc.
} derive(Show)