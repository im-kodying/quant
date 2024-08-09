# Build stage
FROM --platform=linux/amd64 rust:latest AS builder

# Set the working directory inside the container
WORKDIR /quant

# Copy the Cargo.toml and Cargo.lock files to the container
COPY ./quant/Cargo.toml ./quant/Cargo.lock ./

# Copy the source code to the container
COPY ./quant/src ./src

# Build the dependencies to cache them
RUN cargo build --release

# Build the Rust project in release mode
RUN cargo build --release

# Runtime stage
FROM --platform=linux/amd64 ghcr.io/extrange/ibkr:latest

# Set the working directory inside the container
WORKDIR /quant

# Copy the built executable from the build stage
COPY --from=builder /quant/target/release/quant /quant

# Ensure the built executable has execute permissions
RUN chmod +x /quant/quant

# Set the entry point to the built executable
CMD ["./quant"]