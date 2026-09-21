{
  description = "rubyshell development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        ruby = pkgs.ruby_3_3;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            ruby
            pkgs.bundler
            pkgs.libyaml
            pkgs.gnumake
            pkgs.gcc
          ];

          shellHook = ''
            export BUNDLE_PATH="$PWD/.bundle/vendor"
            export BUNDLE_BIN="$PWD/.bundle/bin"
            export GEM_HOME="$BUNDLE_PATH"
            export PATH="$BUNDLE_BIN:$PWD/bin:$PATH"
          '';
        };
      });
}
