{ pkgs }:
let
  helpers = import ./lib/helpers.nix { inherit pkgs; };
in
{
  # Common packages used across all languages
  packages = with pkgs; [
    postgresql
    redis
    gum
    curl
    jq
    pgcli
    redli
    act
    git
  ];
  
  # Common shell hook - runs for all projects
  shellHook = ''
    # Prevent re-initialization
    if [ -n "$WORKSPACE_INITIALIZED" ]; then
      return
    fi
    export WORKSPACE_INITIALIZED=1

    # Save original directory to return to on exit
    export ORIGINAL_DIR="$PWD"

    # Export color palette
    ${helpers.exportColors}

    clear

    # Welcome Screen
    gum style --border rounded --margin "1 2" --padding "1 4" --border-foreground "#ffb6b9" --align center --width 60 -- \
      "$(echo -e "$BOLD$PEACH Multi-Language Dev Workspace$RESET")"
    gum style --margin "0 4" --align center -- \
      "$(echo -e "$ROSE Powered by Nix $RESET")"
    echo ""

    # Helper Functions
    check_port() {
      if command -v lsof > /dev/null 2>&1; then
        if lsof -Pi :$1 -sTCP:LISTEN -t > /dev/null 2>&1; then
          gum style --foreground "#ff6b6b" "⚠️  Port $1 is already in use"
          return 1
        fi
      fi
      return 0
    }

    # Cleanup on exit
    cleanup() {
      echo ""
      gum style --margin "1 2" --align center --faint -- "$(echo -e "🧹 Cleaning up services...")"

      # Stop services if running
      if [ "$USE_REDIS" = "true" ]; then
        if redis-cli ping > /dev/null 2>&1; then
          redis-cli shutdown > /dev/null 2>&1
        fi
      fi
      if [ "$USE_DATABASE" = "PostgreSQL" ]; then
        if pg_ctl status > /dev/null 2>&1; then
          pg_ctl stop > /dev/null 2>&1
        fi
      fi

      # Return to original directory
      if [ -n "$ORIGINAL_DIR" ] && [ "$PWD" != "$ORIGINAL_DIR" ]; then
        cd "$ORIGINAL_DIR"
        gum style --margin "0 2" --align center --faint -- "$(echo -e "📁 Returned to $ORIGINAL_DIR")"
      fi

      gum style --margin "0 2" --align center -- "$(echo -e "$CORAL ✨ Goodbye — workspace restored to calm. $RESET")"
    }
    trap cleanup EXIT INT TERM
  '';
  
  # Database setup function (returns shell code)
  databaseSetup = ''
    # Only create .data if we're in a project (PROJECT_NAME is set)
    if [ -n "$PROJECT_NAME" ]; then
      mkdir -p .data/postgres .data/redis
    fi

    # Database Setup
    if [ "$USE_DATABASE" = "PostgreSQL" ]; then
      export PGDATA="$PWD/.data/postgres"
      export PGHOST=127.0.0.1
      export PGPORT=5433
      export PGDATABASE="''${PROJECT_NAME}_dev"
      export PGUSER=postgres
      export PGPASSWORD=""
      export PSQL_PAGER='less -S'

      gum spin --spinner dot --title "Starting PostgreSQL..." -- sleep 1

      if check_port $PGPORT; then
        if [ ! -d "$PGDATA/base" ]; then
          initdb -U postgres --no-locale --encoding=UTF8 > /dev/null
          echo "unix_socket_directories = '$PGDATA'" >> $PGDATA/postgresql.conf
          echo "listen_addresses = '127.0.0.1'" >> $PGDATA/postgresql.conf
          echo "port = $PGPORT" >> $PGDATA/postgresql.conf
        fi

        if ! pg_ctl status > /dev/null 2>&1; then
          pg_ctl start -l $PGDATA/logfile -o "-k $PGDATA -h 127.0.0.1 -p $PGPORT" > /dev/null
          for i in {1..10}; do
            if pg_isready -h 127.0.0.1 -p $PGPORT > /dev/null 2>&1; then break; fi
            sleep 1
          done

          if ! psql -h 127.0.0.1 -p $PGPORT -lqt | cut -d \| -f 1 | grep -qw "$PGDATABASE"; then
            createdb -h 127.0.0.1 -p $PGPORT "$PGDATABASE"
          fi

          TEST_DB="''${PGDATABASE}_test"
          if ! psql -h 127.0.0.1 -p $PGPORT -lqt | cut -d \| -f 1 | grep -qw "$TEST_DB"; then
            createdb -h 127.0.0.1 -p $PGPORT "$TEST_DB"
          fi
        fi
      fi

      export DATABASE_URL="postgresql://postgres@127.0.0.1:$PGPORT/$PGDATABASE"
    fi

    # Redis Setup
    if [ "$USE_REDIS" = "true" ]; then
      export REDIS_HOST=127.0.0.1
      export REDIS_PORT=6379

      gum spin --spinner dot --title "Starting Redis..." -- sleep 1

      if check_port $REDIS_PORT; then
        if ! redis-cli ping > /dev/null 2>&1; then
          redis-server --daemonize yes \
            --dir $PWD/.data/redis \
            --dbfilename dump.rdb \
            --port $REDIS_PORT \
            --bind $REDIS_HOST \
            --logfile $PWD/.data/redis/redis.log
          sleep 1
        fi
      fi
    fi
  '';
}
