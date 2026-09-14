.PHONY: tools configs validate clean

tools:
	python3 scripts/check_tools.py

configs:
	python3 scripts/generate_sby.py

validate:
	python3 scripts/run_all.py

clean:
	rm -rf build/sby build/runs build/validation_summary.json
	mkdir -p build
