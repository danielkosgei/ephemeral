{ pkgs }:
{
  # Rust-specific packages
  packages = with pkgs; [
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
  ];
  
  # Rust project scaffolding
  scaffoldHook = ''
    if [ "$IS_EXISTING_PROJECT" = false ] && [ "$PROJECT_LANG" = "rust" ]; then
      gum style --foreground "$LAVENDER" "📦 Creating Rust project structure..."
      
      # Initialize cargo project
      cargo init --name "$PROJECT_NAME" .
      
      # Create .gitignore
      if [ ! -f ".gitignore" ]; then
        cat > .gitignore << 'GITIGNORE_EOF'
# Rust
/target
**/*.rs.bk
*.pdb
Cargo.lock

# Data directories
.data/

# Environment files
.env
.env.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store
GITIGNORE_EOF
      fi
      
      # Update Cargo.toml with common dependencies
      cat > Cargo.toml << CARGO_EOF
[package]
name = "$PROJECT_NAME"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { version = "1.42", features = ["full"] }
axum = "0.8"
tower = "0.5"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
dotenv = "0.15"

[dev-dependencies]
CARGO_EOF
      
      # Create project structure
      mkdir -p src/handlers
      mkdir -p src/models
      mkdir -p tests
      
      # Create src/main.rs with Axum server
      cat > src/main.rs << 'MAIN_EOF'
use axum::{
    routing::get,
    Json, Router,
};
use serde::Serialize;
use std::net::SocketAddr;

#[derive(Serialize)]
struct Message {
    message: String,
}

#[derive(Serialize)]
struct Health {
    status: String,
}

#[tokio::main]
async fn main() {
    dotenv::dotenv().ok();

    let app = Router::new()
        .route("/", get(root))
        .route("/health", get(health));

    let port = std::env::var("PORT")
        .unwrap_or_else(|_| "3000".to_string())
        .parse::<u16>()
        .expect("PORT must be a valid number");

    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    println!("Server listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .expect("Failed to bind");

    axum::serve(listener, app)
        .await
        .expect("Server error");
}

async fn root() -> Json<Message> {
    Json(Message {
        message: "Hello from Rust!".to_string(),
    })
}

async fn health() -> Json<Health> {
    Json(Health {
        status: "ok".to_string(),
    })
}
MAIN_EOF
      
      # Create README.md
      cat > README.md << README_EOF
# $PROJECT_NAME

A Rust application built with Nix development environment.

## Getting Started

### Prerequisites

- Nix with flakes enabled

### Development

Enter the development environment:

\\\`\\\`\\\`bash
nix develop
\\\`\\\`\\\`

Run the development server:

\\\`\\\`\\\`bash
cargo run
\\\`\\\`\\\`

Or using the alias:

\\\`\\\`\\\`bash
dev
\\\`\\\`\\\`

### Building

\\\`\\\`\\\`bash
cargo build --release
\\\`\\\`\\\`

### Testing

\\\`\\\`\\\`bash
cargo test
\\\`\\\`\\\`

## Available Commands

- \\\`dev\\\` - Run with hot reload (cargo watch)
- \\\`build\\\` - Build release binary
- \\\`test\\\` - Run tests
- \\\`lint\\\` - Run clippy
- \\\`format\\\` - Format code with rustfmt
README_EOF
      
      # Save workspace configuration
      cat > .workspace-config << CONFIG_EOF
USE_DATABASE="$USE_DATABASE"
USE_REDIS=$USE_REDIS
PROJECT_NAME="$PROJECT_NAME"
PROJECT_LANG="$PROJECT_LANG"
CONFIG_EOF
      
      # Create .env file
      cat > .env << ENV_EOF
# Database Configuration
DATABASE_URL=$DATABASE_URL
PGHOST=$PGHOST
PGPORT=$PGPORT
PGDATABASE=$PGDATABASE
PGUSER=$PGUSER
PGPASSWORD=$PGPASSWORD

# Redis Configuration
REDIS_HOST=$REDIS_HOST
REDIS_PORT=$REDIS_PORT

# Application
RUST_ENV=development
PORT=3000

# Timezone
TZ=UTC
ENV_EOF
      
      gum style --foreground "#b4f8c8" "✓ Rust project structure created!"
      gum style --foreground "#ffb6b9" --margin "0 2" "📝 Created .env file with database credentials"
    fi
  '';
  
  # Rust-specific aliases
  aliasesHook = ''
    if [ "$PROJECT_LANG" = "rust" ]; then
      # Development
      alias dev='cargo run'
      alias build='cargo build --release'
      alias test='cargo test'
      alias lint='cargo clippy'
      alias format='cargo fmt'
      
      # Cargo shortcuts
      alias ca='cargo add'
      alias cr='cargo remove'
      alias cu='cargo update'
      alias cc='cargo clean'
    fi
  '';
}
