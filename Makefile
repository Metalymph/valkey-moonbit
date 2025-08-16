.PHONY: help run test_all test

help:
	@echo "Valkey client utility manager" 
	@echo "Usage:"
	@echo "  make t=? run         - Run the Valkey client"
	@echo "  make t=? test_all    - Run all tests"
	@echo "  make i=? t=? test    - Run tests for a specific index and target"
	@echo ""
	@echo "  Test index (i): 0, 1, .."
	@echo "  Targets (t): js,native,wasm-gc"

run:
	moon run --target $(t) src 

test_all:
	moon test -p metalymph/valkey-moonbit/valkey -f client_test.mbt --target $(t)

test:
	moon test -p metalymph/valkey-moonbit/valkey -f client_test.mbt -i $(i) --target $(t)