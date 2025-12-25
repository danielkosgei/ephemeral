{
  description = "Multi-Language Development Workspace";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Import modules using local paths
        common = import (./. + "/nix/common.nix") { inherit pkgs; };
        goModule = import (./. + "/nix/languages/go.nix") { inherit pkgs; };
        nodeModule = import (./. + "/nix/languages/node.nix") { inherit pkgs; };
        pythonModule = import (./. + "/nix/languages/python.nix") { inherit pkgs; };
        rustModule = import (./. + "/nix/languages/rust.nix") { inherit pkgs; };
        denoModule = import (./. + "/nix/languages/deno.nix") { inherit pkgs; };
        
        # Compose packages from all modules
        allPackages = common.packages ++ goModule.packages ++ nodeModule.packages 
                   ++ pythonModule.packages ++ rustModule.packages ++ denoModule.packages;
        
        # Main shell hook composing all parts
        composedShellHook = ''
          ${common.shellHook}
          
          # ====================================================================================
          # Project Selection Menu
          # ====================================================================================
          
          # Check if we're already in a project directory
          PROJECT_LANG=""
          IS_EXISTING_PROJECT=false
          
          if [ -f "go.mod" ]; then
            # Already in a Go project, skip menu
            IS_EXISTING_PROJECT=true
            PROJECT_LANG="go"
            PROJECT_NAME=$(go list -m 2>/dev/null | awk -F'/' '{print $NF}')
            gum style --foreground "#b4f8c8" "✓ Detected existing Go project: $PROJECT_NAME"
            echo ""
            
            # Load workspace config if available
            if [ -f ".workspace-config" ]; then
              source .workspace-config
            else
              USE_DATABASE="PostgreSQL"
              USE_REDIS=false
              MODULE_PATH=$(go list -m 2>/dev/null || echo "unknown")
            fi
            
          elif [ -f "package.json" ]; then
            # Already in a Node.js project, skip menu
            IS_EXISTING_PROJECT=true
            PROJECT_LANG="node"
            PROJECT_NAME=$(jq -r '.name // "unknown"' package.json 2>/dev/null || basename "$PWD")
            gum style --foreground "#b4f8c8" "✓ Detected existing Node.js project: $PROJECT_NAME"
            echo ""
            
            # Load workspace config if available
            if [ -f ".workspace-config" ]; then
              source .workspace-config
            else
              USE_DATABASE="PostgreSQL"
              USE_REDIS=false
            fi
            
          elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
            # Already in a Python project, skip menu
            IS_EXISTING_PROJECT=true
            PROJECT_LANG="python"
            if [ -f "pyproject.toml" ]; then
              PROJECT_NAME=$(grep -E '^name = ' pyproject.toml | head -n1 | sed 's/name = "\(.*\)"/\1/' || basename "$PWD")
            else
              PROJECT_NAME=$(basename "$PWD")
            fi
            gum style --foreground "#b4f8c8" "✓ Detected existing Python project: $PROJECT_NAME"
            echo ""
            
            # Load workspace config if available
            if [ -f ".workspace-config" ]; then
              source .workspace-config
            else
              USE_DATABASE="PostgreSQL"
              USE_REDIS=false
            fi
            
          elif [ -f "Cargo.toml" ]; then
            # Already in a Rust project, skip menu
            IS_EXISTING_PROJECT=true
            PROJECT_LANG="rust"
            PROJECT_NAME=$(grep -E '^name = ' Cargo.toml | head -n1 | sed 's/name = "\(.*\)"/\1/' || basename "$PWD")
            gum style --foreground "#b4f8c8" "✓ Detected existing Rust project: $PROJECT_NAME"
            echo ""
            
            # Load workspace config if available
            if [ -f ".workspace-config" ]; then
              source .workspace-config
            else
              USE_DATABASE="PostgreSQL"
              USE_REDIS=false
            fi
            
          elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
            # Already in a Deno project, skip menu
            IS_EXISTING_PROJECT=true
            PROJECT_LANG="deno"
            PROJECT_NAME=$(basename "$PWD")
            gum style --foreground "#b4f8c8" "✓ Detected existing Deno project: $PROJECT_NAME"
            echo ""
            
            # Load workspace config if available
            if [ -f ".workspace-config" ]; then
              source .workspace-config
            else
              USE_DATABASE="PostgreSQL"
              USE_REDIS=false
            fi
            
          else
            # Show menu to create new or open existing
            gum style --margin "0 4" --foreground "$LAVENDER" "What would you like to do?"
            echo ""
            
            ACTION=$(gum choose "Create new project" "Open existing project")
            echo ""
            
            if [ "$ACTION" = "Open existing project" ]; then
              # Scan for projects (Go, Node.js, Python, Rust, Deno) in current directory
              PROJECTS=()
              for dir in */; do
                if [ -f "$dir.workspace-config" ] || [ -f "$dir/go.mod" ] || [ -f "$dir/package.json" ] || [ -f "$dir/pyproject.toml" ] || [ -f "$dir/Cargo.toml" ] || [ -f "$dir/deno.json" ]; then
                  PROJECTS+=("$dir")
                fi
              done
              
              if [ ''${#PROJECTS[@]} -eq 0 ]; then
                gum style --foreground "$WARN" "⚠️  No projects found in current directory"
                gum style --margin "0 4" --faint "Tip: Projects need a .workspace-config, go.mod, package.json, pyproject.toml, Cargo.toml, or deno.json file"
                exit 1
              fi
              
              # Let user select a project
              gum style --margin "0 4" "Select a project to open:"
              SELECTED_PROJECT=$(printf '%s\n' "''${PROJECTS[@]}" | gum choose)
              
              if [ -z "$SELECTED_PROJECT" ]; then
                gum style --foreground "$WARN" "⚠️  No project selected"
                exit 1
              fi
              
              # Remove trailing slash
              SELECTED_PROJECT=''${SELECTED_PROJECT%/}
              
              # Navigate into the selected project
              cd "$SELECTED_PROJECT"
              IS_EXISTING_PROJECT=true
              
              # Detect project language and name
              if [ -f "go.mod" ]; then
                PROJECT_LANG="go"
                PROJECT_NAME=$(go list -m 2>/dev/null | awk -F'/' '{print $NF}')
              elif [ -f "package.json" ]; then
                PROJECT_LANG="node"
                PROJECT_NAME=$(jq -r '.name // "unknown"' package.json 2>/dev/null || basename "$PWD")
              elif [ -f "pyproject.toml" ]; then
                PROJECT_LANG="python"
                PROJECT_NAME=$(grep -E '^name = ' pyproject.toml | head -n1 | sed 's/name = "\(.*\)"/\1/' || basename "$PWD")
              elif [ -f "Cargo.toml" ]; then
                PROJECT_LANG="rust"
                PROJECT_NAME=$(grep -E '^name = ' Cargo.toml | head -n1 | sed 's/name = "\(.*\)"/\1/' || basename "$PWD")
              elif [ -f "deno.json" ]; then
                PROJECT_LANG="deno"
                PROJECT_NAME=$(basename "$PWD")
              else
                PROJECT_NAME="$SELECTED_PROJECT"
                PROJECT_LANG="unknown"
              fi
              
              gum style --foreground "#b4f8c8" "✓ Opened project: $PROJECT_NAME ($PROJECT_LANG)"
              echo ""
              
              # Load workspace config
              if [ -f ".workspace-config" ]; then
                source .workspace-config
              else
                USE_DATABASE="PostgreSQL"
                USE_REDIS=false
                if [ "$PROJECT_LANG" = "go" ]; then
                  MODULE_PATH=$(go list -m 2>/dev/null || echo "unknown")
                fi
              fi
            else
              # Create new project flow
              IS_EXISTING_PROJECT=false
            fi
          fi
          
          # ====================================================================================
          # Interactive Setup (New Projects Only)
          # ====================================================================================
          
          if [ "$IS_EXISTING_PROJECT" = false ]; then
            gum style --margin "0 4" --foreground "$LAVENDER" "Let's set up your project!"
            echo ""

            # Ask for language choice
            gum style --margin "0 4" "Choose a language:"
            PROJECT_LANG=$(gum choose "Go" "Node.js" "Python" "Rust" "Deno (TypeScript)")
            echo ""
            
            # Normalize language name
            if [ "$PROJECT_LANG" = "Go" ]; then
              PROJECT_LANG="go"
            elif [ "$PROJECT_LANG" = "Node.js" ]; then
              PROJECT_LANG="node"
            elif [ "$PROJECT_LANG" = "Python" ]; then
              PROJECT_LANG="python"
            elif [ "$PROJECT_LANG" = "Rust" ]; then
              PROJECT_LANG="rust"
            elif [ "$PROJECT_LANG" = "Deno (TypeScript)" ]; then
              PROJECT_LANG="deno"
            fi

            # Ask for project name
            PROJECT_NAME=$(gum input --prompt "Project name: " --placeholder "my-awesome-project")
            if [ -z "$PROJECT_NAME" ]; then
              gum style --foreground "$WARN" "⚠️  Project name is required"
              exit 1
            fi

            # Create project directory and navigate into it
            if [ -d "$PROJECT_NAME" ]; then
              gum style --foreground "$WARN" "⚠️  Directory $PROJECT_NAME already exists"
              exit 1
            fi
            mkdir -p "$PROJECT_NAME"
            cd "$PROJECT_NAME"
            gum style --foreground "#b4f8c8" "✓ Created directory: $PROJECT_NAME"
            echo ""

            # Ask for database choice
            gum style --margin "0 4" "Choose a database:"
            USE_DATABASE=$(gum choose "PostgreSQL" "None")

            # Ask for Redis
            echo ""
            USE_REDIS=false
            if gum confirm "Would you like to use Redis?"; then
              USE_REDIS=true
            fi

            # Ask for Go module path (Go projects only)
            if [ "$PROJECT_LANG" = "go" ]; then
              echo ""
              DEFAULT_MODULE_PATH="github.com/$(whoami)/$PROJECT_NAME"
              MODULE_PATH=$(gum input --prompt "Go module path: " --placeholder "$DEFAULT_MODULE_PATH" --value "$DEFAULT_MODULE_PATH")
            fi
            
            echo ""
            gum spin --spinner dot --title "Setting up your workspace..." -- sleep 1
          fi
          
          # ====================================================================================
          # Database & Redis Setup
          # ====================================================================================
          
          ${common.databaseSetup}
          
          # ====================================================================================
          # Language-Specific Project Scaffolding
          # ====================================================================================
          
          ${goModule.scaffoldHook}
          ${nodeModule.scaffoldHook}
          ${pythonModule.scaffoldHook}
          ${rustModule.scaffoldHook}
          ${denoModule.scaffoldHook}
          
          # ====================================================================================
          # Environment Variables
          # ====================================================================================
          
          export GO_ENV=development
          export PROJECT_NAME
          export PROJECT_LANG
          
          # ====================================================================================
          # Version Display
          # ====================================================================================
          
          echo ""
          gum style --border rounded --padding "0 2" --border-foreground "$MINT" --bold -- \
            "Environment Ready" \
            "" \
            "$(echo -e "  $PEACH Language: $RESET $PROJECT_LANG")" \
            "$(echo -e "  $ROSE Project: $RESET $PROJECT_NAME")" \
            "" \
            "$(echo -e "  $LAVENDER Go: $RESET $(go version | awk '{print $3}')")" \
            "$(echo -e "  $LAVENDER Node.js: $RESET $(node --version)")" \
            "$(echo -e "  $LAVENDER Python: $RESET $(python --version | awk '{print $2}')")" \
            "$(echo -e "  $LAVENDER Rust: $RESET $(rustc --version | awk '{print $2}')")" \
            "$(echo -e "  $LAVENDER Deno: $RESET $(deno --version | head -n1 | awk '{print $2}')")" \
            "$(if [ "$USE_DATABASE" = "PostgreSQL" ]; then echo -e "  $MINT PostgreSQL: $RESET $(postgres --version | awk '{print $3}')"; fi)" \
            "$(if [ "$USE_REDIS" = "true" ]; then echo -e "  $MINT Redis: $RESET $(redis-server --version | awk '{print $3}')"; fi)"
          
          # Git branch if in a repo
          if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
            BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
            gum style --margin "0 4" --italic -- "$(echo -e "🌿 Branch: $BRANCH")"
          fi
          
          echo ""
          
          # ====================================================================================
          # Language-Specific Aliases
          # ====================================================================================
          
          ${goModule.aliasesHook}
          ${nodeModule.aliasesHook}
          ${pythonModule.aliasesHook}
          ${rustModule.aliasesHook}
          ${denoModule.aliasesHook}
          
          # Database aliases (if PostgreSQL enabled)
          if [ "$USE_DATABASE" = "PostgreSQL" ]; then
            alias db='pgcli -h 127.0.0.1 -p 5433 -U postgres -d $PGDATABASE'
            alias db-test='pgcli -h 127.0.0.1 -p 5433 -U postgres -d ''${PGDATABASE}_test'
            alias db-backup='pg_dump -h 127.0.0.1 -p 5433 -U postgres $PGDATABASE > backup.sql'
            alias db-restore='psql -h 127.0.0.1 -p 5433 -U postgres $PGDATABASE < backup.sql'
            alias db-reset='dropdb -h 127.0.0.1 -p 5433 $PGDATABASE && createdb -h 127.0.0.1 -p 5433 $PGDATABASE'
          fi
          
          # Redis aliases (if Redis enabled)
          if [ "$USE_REDIS" = "true" ]; then
            alias cache='redli -h 127.0.0.1 -p 6379'
          fi
          
          # Monitoring aliases
          alias services-status='echo "=== Services ===" && (pg_isready -h 127.0.0.1 -p 5433 && echo "PostgreSQL: ✓" || echo "PostgreSQL: ✗") && (redis-cli ping > /dev/null 2>&1 && echo "Redis: ✓" || echo "Redis: ✗")'
          
          # ====================================================================================
          # Quick Tips
          # ====================================================================================
          
          gum style --margin "1 4" --faint -- "$(echo -e "💡 Quick tips:")"
          gum style --margin "0 6" --faint -- "$(echo -e "• Type 'dev' to start development server")"
          gum style --margin "0 6" --faint -- "$(echo -e "• Type 'test' to run tests")"
          if [ "$USE_DATABASE" = "PostgreSQL" ]; then
            gum style --margin "0 6" --faint -- "$(echo -e "• Type 'db' to connect to database")"
          fi
          
          echo ""
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = allPackages;
          shellHook = composedShellHook;
        };
      }
    );
}