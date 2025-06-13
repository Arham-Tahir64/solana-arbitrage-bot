# Use Ubuntu 24.04 (Noble Numbat) as the base
FROM ubuntu:24.04

# Set environment variables to prevent interactive prompts during apt-get install
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install necessary tools and dependencies
# Added `ca-certificates`, `wget`, and `bzip2` for direct Solana CLI download
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    libudev-dev \
    libclang-dev \
    cmake \
    nodejs \
    npm \
    yarn \
    python3 \
    python3-pip \
    ca-certificates \
    wget \
    bzip2 \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install Rust and Cargo using rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"

# --- START OF REVISED SOLANA CLI INSTALLATION ---
# <<-- IMPORTANT: Use the latest stable version
ENV SOLANA_VERSION="1.18.17"
ENV SOLANA_INSTALL_DIR="/root/.local/share/solana"

RUN set -x && \
    mkdir -p ${SOLANA_INSTALL_DIR} && \
    wget -qO- https://github.com/solana-labs/solana/releases/download/v${SOLANA_VERSION}/solana-release-x86_64-unknown-linux-gnu.tar.bz2 | tar jxf - -C ${SOLANA_INSTALL_DIR} && \
    # Move all contents from solana-release to the parent directory
    cp -r ${SOLANA_INSTALL_DIR}/solana-release/. ${SOLANA_INSTALL_DIR}/ && \
    # Remove the solana-release directory and its contents
    rm -rf ${SOLANA_INSTALL_DIR}/solana-release && \
    # Create the 'active_release/bin' symlink for consistency
    ln -sfn ${SOLANA_INSTALL_DIR}/bin ${SOLANA_INSTALL_DIR}/active_release && \
    # Verify the solana binary exists after extraction
    ls -l ${SOLANA_INSTALL_DIR}/bin/solana || \
    (echo "ERROR: Solana binary not found after direct download!" && exit 1)

# Set the PATH for all subsequent layers and when the container is run.
# Now points directly to the 'bin' directory within the new installation structure.
ENV PATH="${SOLANA_INSTALL_DIR}/bin:$PATH"
# --- END OF REVISED SOLANA CLI INSTALLATION ---


# Install Anchor CLI using AVM (Anchor Version Manager)
RUN cargo install --git https://github.com/coral-xyz/anchor avm --force
# Keep this ENV PATH for avm to be found
ENV PATH="/root/.cargo/bin:$PATH"
RUN avm install latest
RUN avm use latest

# Set the working directory for your project inside the container
WORKDIR /project

# Optional: Expose any ports your application might use
# EXPOSE 3000

# CMD ["bash"]