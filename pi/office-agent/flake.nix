{
  description = "Isolated Pi office agent with Excel MCP";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          mcpConfig = pkgs.writeText "pi-office-mcp.json" (
            builtins.toJSON {
              mcpServers.excel = {
                command = "uvx";
                args = [
                  "--no-managed-python"
                  "--no-python-downloads"
                  "--python"
                  "python3"
                  "--from"
                  "excel-mcp-server==2.0.0"
                  "excel-mcp-server"
                  "stdio"
                  "--allow-dir"
                  "."
                ];
                env = {
                  EXCEL_FILES_PATH = "";
                  EXCEL_MCP_ALLOW_VBA_WRITE = "0";
                };
                exposure = "codemode";
                description = "Create, read and edit Excel workbooks inside the directory where pi-office was started.";
              };
            }
          );

          settingsConfig = pkgs.writeText "pi-office-settings.json" (
            builtins.toJSON {
              defaultProvider = "openai";
              defaultModel = "gpt-6-astra";
              defaultThinkingLevel = "medium";
              # Keep project MCP servers and extensions out unless explicitly approved.
              defaultProjectTrust = "never";
            }
          );

          piOffice = pkgs.writeShellApplication {
            name = "pi-office";
            runtimeInputs = [
              pkgs.pi-coding-agent
              pkgs.python3
              pkgs.uv
            ];
            text = ''
              export PI_CODING_AGENT_DIR="$HOME/.pi/office-agent"
              exec pi "$@"
            '';
          };

          piOfficeSetup = pkgs.writeShellApplication {
            name = "pi-office-setup";
            runtimeInputs = [ pkgs.coreutils ];
            text = ''
              export PI_CODING_AGENT_DIR="$HOME/.pi/office-agent"
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
              if [[ ! -e "$PI_CODING_AGENT_DIR/settings.json" && ! -L "$PI_CODING_AGENT_DIR/settings.json" ]]; then
                install -m 600 ${settingsConfig} "$PI_CODING_AGENT_DIR/settings.json"
              fi
            '';
          };
        in
        {
          default = pkgs.symlinkJoin {
            name = "pi-office";
            paths = [
              piOffice
              piOfficeSetup
            ];
          };
        }
      );
      checks = forAllSystems (system: {
        default = self.packages.${system}.default;
      });
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
