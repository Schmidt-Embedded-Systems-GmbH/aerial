aerial: src/util.ML src/cell.ML src/mtl.ML src/monitor.ML src/aerial.ML src/ROOT.ML
	polyc src/ROOT.ML -o aerial

.PHONY: clean
clean:
	rm -f aerial
