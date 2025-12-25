{ pkgs }:
rec {
  # Color palette for TUI
  colors = {
    peach = ''\033[38;2;255;196;164m'';
    rose = ''\033[38;2;255;182;193m'';
    cream = ''\033[38;2;255;241;220m'';
    coral = ''\033[38;2;255;160;122m'';
    lavender = ''\033[38;2;230;190;255m'';
    mint = ''\033[38;2;189;224;254m'';
    warn = ''\033[38;2;255;107;107m'';
    reset = ''\033[0m'';
    bold = ''\033[1m'';
    dim = ''\033[2m'';
  };
  
  # Helper to create heredoc without complex escaping
  mkHeredoc = delimiter: content: ''
    cat > \$TARGET_FILE << '${delimiter}'
    ${content}
    ${delimiter}
  '';
  
  # Export color variables for use in shell
  exportColors = ''
    export PEACH="${colors.peach}"
    export ROSE="${colors.rose}"
    export CREAM="${colors.cream}"
    export CORAL="${colors.coral}"
    export LAVENDER="${colors.lavender}"
    export MINT="${colors.mint}"
    export WARN="${colors.warn}"
    export RESET="${colors.reset}"
  '';
}
