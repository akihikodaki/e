# SPDX-License-Identifier: Apache-2.0

BENCHMARKS := $(shell cat benchmarks)

.DELETE_ON_ERROR:
.PHONY: obj/bin/champsim stats

stats: $(BENCHMARKS:%=stats/%.json)

ChampSim/vcpkg/vcpkg: ChampSim/vcpkg/bootstrap-vcpkg.sh | obj/vcpkg/
	VCPKG_DOWNLOADS="$$PWD/obj/vcpkg" $<

ChampSim/vcpkg_installed: ChampSim/vcpkg/vcpkg
	export VCPKG_DOWNLOADS="$$PWD/obj/vcpkg" && cd ChampSim && vcpkg/vcpkg install

obj/.csconfig: ChampSim/champsim_config.json
	cd ChampSim && ./config.sh --prefix ../obj champsim_config.json

obj/bin/champsim: ChampSim/vcpkg_installed | obj/.csconfig
	$(MAKE) -CChampSim OBJ_ROOT=../obj/.csconfig ../$@

obj/sha256sum: benchmarks sha256sum $(BENCHMARKS:%=obj/traces/%.champsimtrace.xz)
	sha256sum -c $<
	touch $@

obj/traces/%: | obj/traces/
	cd obj/traces && curl -O https://dpc3.compas.cs.stonybrook.edu/champsim-traces/speccpu/$*

sha256sum: | $(BENCHMARKS:%=obj/traces/%.champsimtrace.xz)
	sha256sum -b $(BENCHMARKS:%=obj/traces/%.champsimtrace.xz) > $@

stats/%.json: | obj/bin/champsim obj/sha256sum obj/traces/%.champsimtrace.xz stats/
	obj/bin/champsim -w 50000000 -i 200000000 --json $@ obj/traces/$*.champsimtrace.xz > stats/$*.txt

%/:
	mkdir -p $*
