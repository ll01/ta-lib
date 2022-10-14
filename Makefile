.PHONY: build

.PHONY: manylinux-wheel $(build-targets)

build:
	python3 setup.py build_ext --inplace

install:
	python3 setup.py install

talib/_func.pxi: tools/generate_func.py
	python3 tools/generate_func.py > talib/_func.pxi

talib/_stream.pxi: tools/generate_stream.py
	python3 tools/generate_stream.py > talib/_stream.pxi

generate: talib/_func.pxi talib/_stream.pxi

cython:
	cython --directive emit_code_comments=False talib/_ta_lib.pyx

clean:
	rm -rf build talib/_ta_lib.so talib/*.pyc

perf:
	python3 tools/perf_talib.py

download:
	curl -L -O http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz

run-docker:
	docker run -it -v $(pwd):/io quay.io/pypa/manylinux2014_x86_64

install-ta-lib:
	tar -xzf ta-lib-0.4.0-src.tar.gz
	cd ta-lib/ ; \
	chmod +x ./configure; \
	./configure --prefix=/usr --build="$(shell uname -m)-unknown-linux-gnu"; \
	make; \
	make install;

pythons := $(wildcard /opt/python/*/bin)

build-targets := $(addprefix build-,$(pythons))

.PHONY: manylinux-wheel $(build-targets)

manylinux-wheel: $(build-targets)

$(build-targets): build-%:
	"$*"/pip install -r requirements.txt;	\
	"$*"/pip --no-cache-dir wheel ./ -w wheelhouse/;	\
	rm -rf build;

repair-manylinux-wheel:
	for whl in $(wildcard wheelhouse/TA_Lib_Precompiled*.whl);	\
	do	\
		auditwheel repair $$whl -w wheelhouse || true;	\
	done

install-test:
	rm -rf ta-lib
	for PYBIN in $(wildcard /opt/python/*/bin);	\
	do	\
		$$PYBIN/pip install ta-lib-bin --no-index -f wheelhouse;	\
	done
