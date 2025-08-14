///|
/// Executes an asynchronous function in the runtime environment.
///
/// Parameters:
///
/// * `f` : An asynchronous function that performs operations without raising
///   exceptions.
///
/// Example:
///
/// ```moonbit
/// @valkey.run(async fn() -> Unit noraise {
///   println("Running your async calls!")
/// })
/// ```
///
pub fn run(f : async () -> Unit noraise) -> Unit = "%async.run"
