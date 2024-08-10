# Build stage
FROM --platform=linux/amd64 rust:latest AS builder

# Set the working directory inside the container
WORKDIR /quant

# Copy the Cargo.toml and Cargo.lock files to the container
COPY quant/Cargo.toml quant/Cargo.lock ./

# Copy the source code to the container
COPY quant/src ./src

# Build the dependencies to cache them
RUN cargo build --release

# Build the Rust project in release mode
RUN cargo build --release

# Runtime stage for ib-gateway
FROM --platform=linux/amd64 ghcr.io/gnzsnz/ib-gateway:latest AS ib-gateway

# Runtime stage for quant
FROM --platform=linux/amd64 ghcr.io/extrange/ibkr:latest

# Set the working directory inside the container
WORKDIR /quant

# Copy the built executable from the build stage
COPY --from=builder /quant/target/release/quant /quant

# Copy the ib-gateway executable from the ib-gateway stage
COPY --from=ib-gateway /usr/local/bin/ib-gateway /usr/local/bin/ib-gateway

# Ensure the built executables have execute permissions
RUN chmod +x /quant/quant /usr/local/bin/ib-gateway

# Set the entry point to run ib-gateway first, then quant
CMD ["sh", "-c", "/usr/local/bin/ib-gateway && ./quant"]