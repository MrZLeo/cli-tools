{
  description = "Isolated Pi agent with RemCTL MCP";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = builtins.currentSystem or "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };

      mcpConfig = pkgs.writeText "pi-reminders-mcp.json" (
        builtins.toJSON {
          mcpServers.remctl = {
            command = "remctl";
            args = [ "mcp" ];
          };
        }
      );

      piReminders = pkgs.writeShellScriptBin "pi-reminders" ''
        export PI_CODING_AGENT_DIR="$HOME/.pi/reminders-agent"
        exec ${pkgs.pi-coding-agent}/bin/pi "$@"
      '';

      piRemindersSetup = pkgs.writeShellApplication {
        name = "pi-reminders-setup";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          export PI_CODING_AGENT_DIR="$HOME/.pi/reminders-agent"
          umask 077

          auth_file="$HOME/.pi/agent/auth.json"
          if [[ ! -f "$auth_file" || ! -O "$auth_file" || "$(stat -c %a -- "$auth_file")" != 600 ]]; then
            echo "Main Pi auth.json must exist, belong to you, and have mode 600." >&2
            exit 1
          fi
          mkdir -p "$PI_CODING_AGENT_DIR"
          chmod 700 "$PI_CODING_AGENT_DIR"
          [[ "$PI_CODING_AGENT_DIR/auth.json" -ef "$auth_file" ]] ||
            ln -sfnT -- "$auth_file" "$PI_CODING_AGENT_DIR/auth.json"

          # Seed once: repeated setup must preserve user configuration.
          if [[ ! -e "$PI_CODING_AGENT_DIR/mcp.json" && ! -L "$PI_CODING_AGENT_DIR/mcp.json" ]]; then
            install -m 600 ${mcpConfig} "$PI_CODING_AGENT_DIR/mcp.json"
          fi
        '';
      };
    in
    {
      packages.${system}.default = pkgs.symlinkJoin {
        name = "pi-reminders";
        paths = [
          piReminders
          piRemindersSetup
        ];
      };
    };
}
