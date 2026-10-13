{
  description = "Isolated Pi agent with RemCTL MCP";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = builtins.currentSystem or "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system}.default = pkgs.writeShellScriptBin "pi-reminders" ''
                export PI_CODING_AGENT_DIR="$HOME/.pi/reminders-agent"
                mkdir -p "$PI_CODING_AGENT_DIR"

                cat > "$PI_CODING_AGENT_DIR/mcp.json" <<'EOF'
        {
          "mcpServers": {
            "remctl": {
              "command": "remctl",
              "args": ["mcp"]
            }
          }
        }
        EOF

                exec ${pkgs.pi-coding-agent}/bin/pi "$@"
      '';
    };
}
