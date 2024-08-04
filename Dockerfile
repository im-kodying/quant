FROM rust:latest

# Set the working directory inside the container
WORKDIR /quant

# Copy the Cargo.toml and Cargo.lock files to the container
COPY /quant /quant

# Build the dependencies to cache them
RUN cargo build --release

# Copy the source code to the container
COPY quant/ .

# Build the Rust project in release mode
RUN cargo build --release

# Ensure the built executable has execute permissions
RUN chmod +x /quant/target/release/quant

# Set the entry point to the built executable
CMD ["./target/release/quant"]