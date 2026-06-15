# Stage 1: Extract the tronbyt-server binary from the official image
ARG BUILD_FROM=ghcr.io/tronbyt/server:2.3.2
FROM $BUILD_FROM AS tronbyt

# Stage 2: Build the actual app using Alpine (has shell, apk, etc.)
FROM alpine:3.21

# Install runtime dependencies
#   `jq` used for parsing Home Assistant options.json
RUN apk add --no-cache jq ca-certificates tzdata dos2unix

# Copy everything from /app in the tronbyt image (binary + static assets)
COPY --from=tronbyt /app/ /app/

# Ensure the binary is executable
RUN chmod +x /app/tronbyt-server

# Copy our startup script and ensure LF line endings
COPY run.sh /
RUN dos2unix /run.sh && chmod a+x /run.sh

WORKDIR /app

# Tronbyt stores its data in /app/data
# HA apps get persistent storage at /data
# Therefore, symlink /app/data -> /data/tronbyt so it persists across restarts
CMD [ "/run.sh" ]
