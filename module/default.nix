# module/default.nix
# Mado (窓) — GPU-rendered terminal emulator configuration
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.mado;

  # Import shared Nord palette
  colors = import ./themes/nord/colors.nix;

  # Map to numbered Nord names
  nord = {
    nord0 = colors.polar.night0;
    nord1 = colors.polar.night1;
    nord2 = colors.polar.night2;
    nord3 = colors.polar.night3;
    nord4 = colors.snow.storm0;
    nord5 = colors.snow.storm1;
    nord6 = colors.snow.storm2;
    nord7 = colors.frost.frost0;
    nord8 = colors.frost.frost1;
    nord9 = colors.frost.frost2;
    nord10 = colors.frost.frost3;
    nord11 = colors.aurora.red;
    nord12 = colors.aurora.orange;
    nord13 = colors.aurora.yellow;
    nord14 = colors.aurora.green;
    nord15 = colors.aurora.purple;
  };

  # ── Derived shader values ────────────────────────────────────────
  builtinShaders =
    (lib.optional cfg.shaders.bloom ./shaders/bloom.wgsl)
    ++ (lib.optional cfg.shaders.cursorGlow ./shaders/cursor-glow.wgsl)
    ++ (lib.optional cfg.shaders.scanlines ./shaders/scanlines.wgsl)
    ++ (lib.optional cfg.shaders.filmGrain ./shaders/film-grain.wgsl);

  allShaderPaths = builtinShaders ++ cfg.shaders.custom;

  # ── Build the complete YAML config ──────────────────────────────
  madoSettings = {
    font_family = cfg.font.family;
    font_size = cfg.font.size;

    window = {
      width = cfg.window.width;
      height = cfg.window.height;
      padding = cfg.window.padding;
    };

    appearance = {
      background = cfg.appearance.background;
      foreground = cfg.appearance.foreground;
      opacity = cfg.appearance.opacity;
      bold_is_bright = cfg.appearance.boldIsBright;
    };

    shell = lib.optionalAttrs (cfg.shell.command != null) {
      command = cfg.shell.command;
    } // lib.optionalAttrs (cfg.shell.args != []) {
      args = cfg.shell.args;
    };

    cursor = {
      style = cfg.cursor.style;
      blink = cfg.cursor.blink;
      color = cfg.cursor.color;
    };

    behavior = {
      scrollback_lines = cfg.behavior.scrollbackLines;
      copy_on_select = cfg.behavior.copyOnSelect;
      confirm_close = cfg.behavior.confirmClose;
      mouse_hide_while_typing = cfg.behavior.mouseHideWhileTyping;
      mouse_scroll_multiplier = cfg.behavior.mouseScrollMultiplier;
    };

    performance = {
      vsync = cfg.performance.vsync;
      target_fps = cfg.performance.targetFps;
    };

    shell_integration = {
      enabled = cfg.shellIntegration.enabled;
      features = cfg.shellIntegration.features;
    };

    shaders = {
      enabled = cfg.shaders.enable;
      files = map (path:
        "${config.home.homeDirectory}/.config/mado/shaders/${builtins.baseNameOf (toString path)}"
      ) allShaderPaths;
    };

    theme = if cfg.theme.nordTheme then "nord" else cfg.theme.name;
  } // lib.optionalAttrs (cfg.activeProfile != null) {
    active_profile = cfg.activeProfile;
  } // cfg.extraSettings;

  # Generate YAML using Nix's built-in generator
  yamlContent = let
    # Simple recursive YAML generator
    toYAML = indent: attrs:
      concatStringsSep "\n" (mapAttrsToList (k: v:
        let prefix = concatStrings (genList (_: "  ") indent);
        in
          if builtins.isAttrs v then
            "${prefix}${k}:\n${toYAML (indent + 1) v}"
          else if builtins.isList v then
            "${prefix}${k}:\n${concatMapStringsSep "\n" (item:
              "${prefix}  - ${builtins.toJSON item}"
            ) v}"
          else if builtins.isBool v then
            "${prefix}${k}: ${if v then "true" else "false"}"
          else if builtins.isFloat v then
            "${prefix}${k}: ${builtins.toJSON v}"
          else if builtins.isInt v then
            "${prefix}${k}: ${toString v}"
          else
            "${prefix}${k}: ${builtins.toJSON v}"
      ) attrs);
  in ''
    # Mado (窓) Configuration
    # Managed by Nix (blackmatter.components.mado)
    # Do not edit — changes will be overwritten on rebuild.

    ${toYAML 0 madoSettings}
  '';

in {
  options.blackmatter.components.mado = {
    enable = mkEnableOption "Mado GPU-rendered terminal emulator";

    # ── Font ────────────────────────────────────────────────────────
    font = {
      family = mkOption {
        type = types.str;
        default = "JetBrains Mono";
        description = "Font family for terminal text";
        example = "FiraCode Nerd Font";
      };

      size = mkOption {
        type = types.float;
        default = 14.0;
        description = "Font size in points";
      };
    };

    # ── Window ──────────────────────────────────────────────────────
    window = {
      width = mkOption {
        type = types.int;
        default = 1200;
        description = "Initial window width in pixels";
      };

      height = mkOption {
        type = types.int;
        default = 800;
        description = "Initial window height in pixels";
      };

      padding = mkOption {
        type = types.int;
        default = 12;
        description = "Window padding in pixels";
      };
    };

    # ── Appearance ──────────────────────────────────────────────────
    appearance = {
      background = mkOption {
        type = types.str;
        default = nord.nord0;
        description = "Background color (hex)";
      };

      foreground = mkOption {
        type = types.str;
        default = nord.nord6;
        description = "Foreground color (hex)";
      };

      opacity = mkOption {
        type = types.float;
        default = 0.95;
        description = "Background opacity (0.0 - 1.0)";
      };

      boldIsBright = mkOption {
        type = types.bool;
        default = false;
        description = "Draw bold text in bright colors";
      };
    };

    # ── Shell ───────────────────────────────────────────────────────
    shell = {
      command = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Shell command to run (null = use SHELL env var)";
        example = "/bin/zsh";
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional arguments passed to shell";
      };
    };

    # ── Cursor ──────────────────────────────────────────────────────
    cursor = {
      style = mkOption {
        type = types.enum ["block" "bar" "underline"];
        default = "block";
        description = "Cursor style";
      };

      blink = mkOption {
        type = types.bool;
        default = true;
        description = "Enable cursor blinking";
      };

      color = mkOption {
        type = types.str;
        default = nord.nord8;
        description = "Cursor color (hex)";
      };
    };

    # ── Theme ───────────────────────────────────────────────────────
    theme = {
      nordTheme = mkOption {
        type = types.bool;
        default = true;
        description = "Use Nord color theme (theme = \"nord\")";
      };

      name = mkOption {
        type = types.str;
        default = "nord";
        description = "Theme name when nordTheme is false (e.g. dracula, solarized-light)";
      };

      customColors = mkOption {
        type = types.attrs;
        default = {};
        description = "Custom ANSI color overrides (e.g. { red = \"#ff0000\"; })";
        example = {
          background = "#1e1e1e";
          foreground = "#d4d4d4";
        };
      };
    };

    # ── Shell integration ───────────────────────────────────────────
    shellIntegration = {
      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "Enable shell integration features";
      };

      features = mkOption {
        type = types.listOf types.str;
        default = [ "cursor" "sudo" "title" ];
        description = "Shell integration features to enable";
      };
    };

    # ── Active profile ─────────────────────────────────────────────
    activeProfile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Name of the profile to activate (null = use default config)";
    };

    # ── Behavior ────────────────────────────────────────────────────
    behavior = {
      scrollbackLines = mkOption {
        type = types.int;
        default = 10000;
        description = "Number of lines in scrollback buffer";
      };

      copyOnSelect = mkOption {
        type = types.bool;
        default = false;
        description = "Automatically copy selected text to clipboard";
      };

      confirmClose = mkOption {
        type = types.bool;
        default = false;
        description = "Confirm before closing terminal window";
      };

      mouseHideWhileTyping = mkOption {
        type = types.bool;
        default = true;
        description = "Hide mouse cursor while typing";
      };

      mouseScrollMultiplier = mkOption {
        type = types.int;
        default = 2;
        description = "Mouse scroll wheel multiplier";
      };
    };

    # ── Performance ─────────────────────────────────────────────────
    performance = {
      vsync = mkOption {
        type = types.bool;
        default = true;
        description = "Enable vsync for smoother rendering";
      };

      targetFps = mkOption {
        type = types.int;
        default = 120;
        description = "Target frame rate for rendering";
      };
    };

    # ── Shaders ─────────────────────────────────────────────────────
    shaders = {
      enable = mkEnableOption "custom WGSL post-processing shaders";

      bloom = mkOption {
        type = types.bool;
        default = true;
        description = "Subtle bloom glow on bright text";
      };

      cursorGlow = mkOption {
        type = types.bool;
        default = false;
        description = "Soft glow around the cursor";
      };

      scanlines = mkOption {
        type = types.bool;
        default = false;
        description = "CRT-style scanline overlay";
      };

      filmGrain = mkOption {
        type = types.bool;
        default = false;
        description = "Subtle animated film grain texture";
      };

      custom = mkOption {
        type = types.listOf types.path;
        default = [];
        description = "Additional custom WGSL shader file paths";
      };
    };

    # ── Extra settings ──────────────────────────────────────────────
    extraSettings = mkOption {
      type = types.attrs;
      default = {};
      description = "Additional mado settings merged into the config";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Install mado package
    {
      home.packages = [ pkgs.mado ];
    }

    # Generate ~/.config/mado/mado.yaml
    {
      xdg.configFile."mado/mado.yaml".text = yamlContent;
    }

    # Deploy shader files to ~/.config/mado/shaders/
    (mkIf cfg.shaders.enable {
      xdg.configFile = lib.listToAttrs (map (path:
        lib.nameValuePair
          "mado/shaders/${builtins.baseNameOf (toString path)}"
          { source = path; }
      ) builtinShaders);
    })
  ]);
}
