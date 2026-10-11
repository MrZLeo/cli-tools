{
  description = "Personal command-line tools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};

      cliTools = pkgs.buildEnv {
        name = "cli-tools";

        paths = with pkgs; [
          dust
          gh
          hyperfine
          jq
          lazygit
          nodejs
          tmux
          tokei
          zoxide
          axel
          btop
          fastfetch
          git-lfs
          glow
          tlrc
          unzip
          wget
          cmake
          cppcheck
          ninja
          uv
          ffmpeg
          hugo
          neomutt
          pandoc
          poppler-utils
          _7zz
          vhs
          yazi
          zig
          zls
        ];

        # buildEnv also respects each package's meta.outputsToInstall,
        # preserving separate manual outputs such as jq.man and tmux.man.
        pathsToLink = [
          "/bin"
          "/share"
        ];
      };
    in
    {
      packages.${system}.default = cliTools;
      checks.${system}.default = cliTools;
      formatter.${system} = pkgs.nixfmt;
    };
}
