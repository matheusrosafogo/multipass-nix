{
  description = "Multipass packaged for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));

      mkMultipass =
        pkgs:
        let
          scope-guard = pkgs.callPackage ./pkgs/scope-guard { };
          neargye-semver = pkgs.callPackage ./pkgs/neargye-semver { };
          out-ptr = pkgs.callPackage ./pkgs/out-ptr { };
          xz-embedded = pkgs.callPackage ./pkgs/xz-embedded { };
        in
        pkgs.callPackage ./pkgs/multipass/package.nix {
          inherit
            neargye-semver
            out-ptr
            scope-guard
            xz-embedded
            ;
        };
    in
    {
      packages = forAllSystems (
        pkgs:
        let
          multipass = mkMultipass pkgs;
        in
        {
          inherit multipass;
          multipassd = multipass.multipassd;
          default = multipass;
        }
      );

      checks = forAllSystems (
        pkgs:
        let
          multipass = mkMultipass pkgs;
        in
        {
          multipass = pkgs.callPackage ./nixos/tests/multipass.nix { inherit multipass; };
        }
      );

      nixosModules.multipass =
        { lib, pkgs, ... }:
        {
          imports = [ ./nixos/multipass.nix ];
          services.multipass.package =
            lib.mkDefault self.packages.${pkgs.stdenv.hostPlatform.system}.multipass;
        };

      nixosModules.default = self.nixosModules.multipass;
    };
}
