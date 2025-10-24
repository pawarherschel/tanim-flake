{
  description = "A Typst project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    typix = {
      url = "github:loqusion/typix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    # Example of downloading icons from a non-flake source
    # font-awesome = {
    #   url = "github:FortAwesome/Font-Awesome";
    #   flake = false;
    # };
  };

  outputs =
    inputs@{
      nixpkgs,
      typix,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        framesStart = 0;
        framesEnd = 100;

        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib;

        typixLib = typix.lib.${system};

        src = typixLib.cleanTypstSource ./.;
        commonArgs = t: {
          typstSource = "main.typ";

          typstOpts = {
            format = "png";
            input = [
              (lib.strings.concatStrings [
                "t="
                (builtins.toString t)
              ])
            ];
          };

          fontPaths = [
            # Add paths to fonts here
            # "${pkgs.roboto}/share/fonts/truetype"
          ];

          virtualPaths = [
            # Add paths that must be locally accessible to typst here
            # {
            #   dest = "icons";
            #   src = "${inputs.font-awesome}/svgs/regular";
            # }
          ];
        };

        # Compile a Typst project, *without* copying the result
        # to the current directory
        build-frame =
          t:
          typixLib.buildTypstProject (
            commonArgs t
            // {
              inherit src;
            }
          );

        built-frames = builtins.genList (
          x:
          let
            t = framesStart + x;
          in
          (build-frame t).out
        ) (framesEnd - framesStart);

        ffmpeg = pkgs.ffmpeg-headless;

        save-frame-paths =
          let
            txt = lib.strings.concatStringsSep "\n" (
              builtins.map (
                x:
                lib.strings.concatStrings [
                  "file '"
                  x
                  "'\nduration 0.03333"
                ]
              ) built-frames
            );
          in
          pkgs.writeText "meow.txt" txt;

        stitch-frames = pkgs.writeShellApplication {
          name = "stitch-frames";
          text =
            let
              frames = "-f concat -safe 0 -i ${save-frame-paths}";
              videoFilter = "-vf scale='trunc(iw/2)*2:trunc(ih/2)*2',fps=30";
            in
            "${ffmpeg}/bin/ffmpeg ${frames} ${videoFilter} -c:v libx264 -pix_fmt yuv420p ./output.mp4";
        };

        build-video = pkgs.stdenvNoCC.mkDerivation {
          pname = "tanim-as-nix-flake";
          version = "0.1";
          frames = built-frames;
          buildInputs = [
            ffmpeg
          ];
          frameList = save-frame-paths;
          script = stitch-frames;

          dontUnpack = true;

          installPhase = ''
            mkdir -p $out

            ${stitch-frames}/bin/stitch-frames

            cp output.mp4 $out/output.mp4
          '';
        };

        video-path = builtins.path { path = build-video; };

        copy-video = pkgs.writeShellApplication {
          name = "copy-output-to-cwd";
          runtimeInputs = [ pkgs.coreutils ];
          text = ''
            cp -LT --no-preserve=mode ${video-path}/output.mp4 output.mp4
          '';
        };
      in
      {
        packages.default = copy-video;
      }
    );
}
