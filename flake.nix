{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, flake-utils, naersk, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
        };

        naersk' = pkgs.callPackage naersk {};

        tanimSrc = pkgs.fetchFromGitHub {
            owner = "liquidhelium";
            repo = "tanim";
            rev = "d78c52dbc611ebb9c574e55dc6a4a6bef69e7a17";
            hash = "sha256-X4toMLTPNtaxQQBDGNvnTrmReMGzNbjuFXgG318Z53s=";
        };

        tanim = naersk'.buildPackage {
          src = tanimSrc;
          
          buildInputs = [
            pkgs.ffmpeg
          ];

          nativeBuildInputs = [
            pkgs.pkg-config
            pkgs.llvmPackages_latest.llvm
            pkgs.rustPlatform.bindgenHook
          ];
        };
      in rec {
        packages.default = tanim;

        apps.default = flake-utils.lib.mkApp {
          drv = tanim;
          exeName = "tanim-cli";
        };
        
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ tanim ];
        };
      }
    );
}
