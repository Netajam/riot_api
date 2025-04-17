ARG ELIXIR_VERSION=1.18.3
ARG OTP_VERSION=27
ARG DEBIAN_VERSION=bookworm # Define Debian version globally or before runtime stage
FROM elixir:${ELIXIR_VERSION}-otp-${OTP_VERSION} AS builder

# Set environment variables for the build stage
ENV MIX_ENV=prod \
    LANG=C.UTF-8

WORKDIR /app

# Install build tools
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy dependency definition files
COPY mix.exs mix.lock ./

# Fetch and compile dependencies (only production dependencies)
RUN mix deps.get --only prod && \
    mix deps.compile

# --- Asset Setup (Standalone) ---
COPY priv ./priv
COPY assets ./assets
COPY config ./config
COPY lib ./lib
COPY assets/tailwind.config.js ./assets/

RUN mix assets.deploy
# Build the Release
RUN mix release
FROM debian:${DEBIAN_VERSION}-slim

# Set environment variables for runtime
ENV LANG=C.UTF-8 \
    SHELL=/bin/bash \
    MIX_ENV=prod \
    PHX_SERVER=true
WORKDIR /app
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        libssl3 \
        locales \
        openssl \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create a non-root user for security
RUN groupadd --system appgroup && \
    adduser --system --ingroup appgroup --shell /bin/false --disabled-password appuser
COPY --from=builder --chown=appuser:appgroup /app/_build/prod/rel/riot_api ./
USER appuser
EXPOSE 4000
CMD ["./bin/riot_api", "start"]