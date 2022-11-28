# Use nix develop to start a development environment under NixOS
{
  description = "OTPlibrary";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      # Use the same nixpkgs
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, gitignore }:
    # flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ haskellOverlay ];
        };
        ghcVersion = "ghc924";
        hsPkgs = pkgs.haskell.packages.${ghcVersion};

        pkgName = "otp";

        haskellOverlay = final: prev: {
          haskell = prev.haskell // {
            packages = prev.haskell.packages // {
              ${ghcVersion} = prev.haskell.packages.${ghcVersion}.override {
                overrides = hfinal: hprev: {
                  # doctest =
                  #   hfinal.callPackage ./nix/haskell-packages/doctest-0.20.0.nix { };
                  ${pkgName} = hfinal.callCabal2nix pkgName
                    (gitignore.lib.gitignoreSource ./.) { };
                };
              };
            };
          };
        };
      in {
        packages.default = hsPkgs.${pkgName};
        devShells.default = hsPkgs.shellFor {
          name = pkgName;
          packages = pkgs: [ pkgs.${pkgName} ];
          buildInputs = [
            pkgs.cabal-install
            pkgs.cabal2nix
            hsPkgs.ormolu
            hsPkgs.ghc
            pkgs.hlint
            # hsPkgs.hoogle
            # pkgs.stylish-haskell
            #pkgs.haskell-language-server
          ];
          src = null;
          
          # Define environment variables.
          # VAR1 = "var-1-value";
        };
      });
}
