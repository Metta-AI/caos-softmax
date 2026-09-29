{
  # The worker image for `tools/gota`, and the tool itself: /worker is ./worker,
  # so this directory IS the tool. Editing the script rebuilds the image (a small
  # layer over cached nixpkgs paths); the alternative, a generic interpreter
  # image with the script curried on, saves that rebuild at the cost of a second
  # file. This tool is edited rarely enough that one file wins.
  #
  # python312, not `python3`: coworld requires >=3.11,<3.13, and `python3` in
  # nixos-unstable moves past that. uv is told never to download an interpreter
  # (UV_PYTHON_DOWNLOADS) so a mismatch fails loudly instead of fetching one.
  description = "caos tool: drive Softmax's coworld/softmax CLIs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forSystem =
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          workerRoot = pkgs.runCommand "gota-worker-root" { } ''
            mkdir -p $out
            install -m 755 ${./worker} $out/worker
          '';
        in
        pkgs.dockerTools.buildLayeredImage {
          name = "gota";
          tag = "latest";
          contents = [
            workerRoot
            pkgs.bash
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.jq
            pkgs.cacert
            pkgs.python312
            pkgs.uv
          ];
          config = {
            Env = [
              "PATH=/bin"
              "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
              "UV_PYTHON=python3.12"
              "UV_PYTHON_DOWNLOADS=never"
            ];
          };
        };
    in
    {
      packages = builtins.listToAttrs (
        map
          (system: {
            name = system;
            value = {
              caosImage = forSystem system;
            };
          })
          [
            "x86_64-linux"
            "aarch64-linux"
          ]
      );
    };
}
