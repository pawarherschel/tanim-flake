{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # typix = {
    #   url = "github:loqusion/typix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs =
    {
      self,
      flake-utils,
      naersk,
      nixpkgs,
      fenix,
    # typix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
        };

        toolchain = fenix.packages.${system}.fromToolchainName {
          name = "1.90.0";
          sha256 = "sha256-SJwZ8g0zF2WrKDVmHrVG3pD2RGoQeo24MEXnNx5FyuI=";
        };

        naersk' = pkgs.callPackage naersk {
          cargo = toolchain.cargo;
          rustc = toolchain.rustc;
        };

        # typixLib = typix.lib.${system};
        # src = typixLib.cleanTypstSource ./.;
        # commonArgs = {
        #   typstSource = "example.typ";

        #   input = ["t=120"];

        #   fontPaths = [
        #     # Add paths to fonts here
        #     # "${pkgs.roboto}/share/fonts/truetype"
        #   ];

        #   virtualPaths = [
        #     # Add paths that must be locally accessible to typst here
        #     # {
        #     #   dest = "icons";
        #     #   src = "${inputs.font-awesome}/svgs/regular";
        #     # }
        #   ];
        # };

        # unstable_typstPackages = [ ];
        # # Compile a Typst project, *without* copying the result
        # # to the current directory

        # build-drv = typixLib.buildTypstProject (
        #   commonArgs
        #   // {
        #     inherit src unstable_typstPackages;
        #   }
        # );

        # # Compile a Typst project, and then copy the result
        # # to the current directory
        # build-script = typixLib.buildTypstProjectLocal (
        #   commonArgs
        #   // {
        #     inherit src unstable_typstPackages;
        #   }
        # );

        tanimSrc = pkgs.fetchFromGitHub {
          owner = "liquidhelium";
          repo = "tanim";
          rev = "06decc2170de01e54511b86a3d657acb0ba9a06e";
          hash = "sha256-EJoNVbp6k1o0KUlIRhr3bdrtDAETwSOqu516EYBA6RA=";
        };

        tanim = naersk'.buildPackage {
          src = tanimSrc;

          propagatedBuildInputs = [
            pkgs.ffmpeg
          ];

          propagatedNativeBuildInputs = [
            pkgs.pkg-config
            pkgs.rustPlatform.bindgenHook
            pkgs.llvmPackages_latest.llvm
          ];

          RUSTFLAGS = nixpkgs.lib.concatStringsSep " " ([
            # Increase codegen units to introduce parallelism within the compiler.
            "-Ccodegen-units=10"
            # Upstream defaults to lld on x86_64-unknown-linux-gnu, we want to use our linker
            "-Clinker-features=-lld"
            "-Clink-self-contained=-linker"
          ]);
        };
      in
      rec {
        packages.default = tanim;

        apps.default = flake-utils.lib.mkApp {
          drv = tanim;
          exePath = "/bin/tanim-cli";
        };

        # apps = {
        #   build = flake-utils.lib.mkApp {
        #     drv = build-script;
        #   };
        # };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ tanim ];
        };
      }
    );
}
