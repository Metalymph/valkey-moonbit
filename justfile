i := "0"
t := "js"

help:
	@echo "Valkey client for Moonbit" 
	@echo "Usage:"
	@echo "  make t=? run         - Run the Valkey client"
	@echo "  make t=? test_all    - Run all tests"
	@echo "  make i=? t=? test    - Run tests for a specific index and target"
	@echo ""
	@echo "  Test index (i): 0 (default), 1, .."
	@echo "  Targets (t): js (default), native, wasm-gc"

dev:
	watchexec -r -e mbt,mod.json,pkg.json moon run --target {{t}} src 

run:
	moon run --target {{t}} src 

test_all:
	moon test -p metalymph/valkey-moonbit/valkey -f client_test.mbt --target {{t}}

test:
	moon test -p metalymph/valkey-moonbit/valkey -f client_test.mbt -i {{i}} --target {{t}}