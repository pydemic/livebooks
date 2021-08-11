FROM rust AS xsv

RUN git clone https://github.com/BurntSushi/xsv.git && \
  cd xsv && \
  cargo build --release

FROM elixir:1.12.2

ENV PATH="/root/.mix/escripts:${PATH}" \
  LIVEBOOK_IP="0.0.0.0"

COPY --from=xsv /xsv/target/release/xsv /usr/local/bin/xsv

WORKDIR /data

RUN mix local.hex --force && \
  mix local.rebar --force

RUN mix escript.install --force github elixir-nx/livebook

CMD ["sleep", "infinity"]
