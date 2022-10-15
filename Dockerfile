# Dockerfile for TA-Lib. To build:
#
#    docker build --rm -t talib .
#
# To run:
#
#    docker run --rm -it talib bash
#
ARG ARCHITECTURE=x86_64
FROM quay.io/pypa/manylinux_2_28_${ARCHITECTURE} as builder

ARG ARCHITECTURE
ENV PATH="/opt/_internal/cpython-3.10.8/bin:$PATH"

WORKDIR /src/ta-lib-core
RUN dnf upgrade --refresh -y \
    && dnf update -y \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz \
    | tar xvz --strip-components 1 \
    && ./configure --prefix=/usr \
    && make \
    && make install

WORKDIR /src/ta-lib-python
COPY . .
RUN make manylinux-wheel -j 4
RUN make repair-manylinux-wheel


FROM builder as test
RUN python3.10 -m pip install -e . \
    && python3.10 -c 'import numpy, talib; close = numpy.random.random(100); output = talib.SMA(close); print(output)' 

RUN python3.10 -m pip install -r requirements_test.txt \
        && pytest . ;

# Build final image.
FROM python:3.10-slim
COPY --from=builder /src/ta-lib-python/wheelhouse/TA_Lib_Precompiled*manylinux* /opt/ta-lib-python/wheels/
COPY --from=builder /opt/ta-lib-core /opt/ta-lib-core
RUN pip install numpy
RUN python -m pip install TA-Lib-Precompiled --no-index -f /opt/ta-lib-python/wheels \
    && python -c 'import numpy, talib; close = numpy.random.random(100); output = talib.SMA(close); print(output)'
