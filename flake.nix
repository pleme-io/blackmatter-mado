{
  description = "Blackmatter Mado - GPU-rendered terminal emulator styling";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, devenv }:
    let
      lib = nixpkgs.lib;
      allSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: lib.genAttrs allSystems (system: f system);

      # Shared HM module stubs for check evaluation
      mkHmStubs = pkgs: { lib, ... }: {
        config._module.args = { inherit pkgs; };
        options.home.packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [];
        };
        options.home.homeDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/home/test";
        };
        options.xdg.configFile = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options.text = lib.mkOption { type = lib.types.str; default = ""; };
            options.source = lib.mkOption { type = lib.types.path; default = ./.; };
          });
          default = {};
        };
      };
    in {
      # ── Home-manager module ──────────────────────────────────────
      homeManagerModules.default = import ./module;

      # ── Dev shells ───────────────────────────────────────────────
      devShells = forAllSystems (system: let
        pkgs = import nixpkgs { inherit system; };
      in {
        default = devenv.lib.mkShell {
          inputs = { inherit nixpkgs devenv; };
          inherit pkgs;
          modules = [{
            languages.nix.enable = true;
            packages = with pkgs; [ nixpkgs-fmt nil ];
            git-hooks.hooks.nixpkgs-fmt.enable = true;
          }];
        };
      });

      # ── Checks ───────────────────────────────────────────────────
      checks = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };

          moduleEval = lib.evalModules {
            modules = [
              ./module
              (mkHmStubs pkgs)
            ];
          };

          colors = import ./module/themes/nord/colors.nix;
        in {
          # Verify module options exist and are well-formed
          module-eval = pkgs.runCommand "mado-module-eval" {} ''
            echo "Option exists: ${builtins.toJSON (builtins.hasAttr "mado" moduleEval.config.blackmatter.components)}"
            echo "Default font: ${moduleEval.config.blackmatter.components.mado.font.family}"
            echo "Default cursor: ${moduleEval.config.blackmatter.components.mado.cursor.style}"
            echo "Enable default: ${builtins.toJSON moduleEval.config.blackmatter.components.mado.enable}"
            touch $out
          '';

          # Verify Nord palette structure is complete
          theme-colors = pkgs.runCommand "mado-theme-colors" {} ''
            echo "polar.night0 = ${colors.polar.night0}"
            echo "snow.storm0 = ${colors.snow.storm0}"
            echo "frost.frost0 = ${colors.frost.frost0}"
            echo "aurora.red = ${colors.aurora.red}"
            touch $out
          '';

          # Verify module enables correctly (with enable = true)
          module-enable = let
            enabledEval = lib.evalModules {
              modules = [
                ./module
                (mkHmStubs pkgs)
                ({ ... }: {
                  config.blackmatter.components.mado.enable = true;
                })
              ];
            };
          in pkgs.runCommand "mado-module-enable" {} ''
            echo "Module enabled successfully"
            echo "Enable = ${builtins.toJSON enabledEval.config.blackmatter.components.mado.enable}"
            echo "Config text length: ${builtins.toJSON (builtins.stringLength (enabledEval.config.xdg.configFile."mado/mado.yaml".text))}"
            touch $out
          '';

          # Verify shader-enabled module evaluates correctly
          module-shaders = let
            shaderEval = lib.evalModules {
              modules = [
                ./module
                (mkHmStubs pkgs)
                ({ ... }: {
                  config.blackmatter.components.mado = {
                    enable = true;
                    shaders.enable = true;
                  };
                })
              ];
            };
          in pkgs.runCommand "mado-module-shaders" {} ''
            echo "Shaders enabled: ${builtins.toJSON shaderEval.config.blackmatter.components.mado.shaders.enable}"
            echo "Bloom: ${builtins.toJSON shaderEval.config.blackmatter.components.mado.shaders.bloom}"
            touch $out
          '';
        }
      );
    };
}
