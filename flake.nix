{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    backend = {
      url = "github:FlakM/backend/01d5c427b046d807f23381832b60cac9717542a0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@attrs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      formatter.${system} = pkgs.nixpkgs-fmt;
      nixosConfigurations.blog = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = attrs;
        modules = [ ./configuration.nix ];
      };


      devShell.x86_64-linux = pkgs.mkShell {
        buildInputs = with pkgs; [
          terraform
          awscli2
        ];
      };
    };


}
