{ config, lib, pkgs, ... }:

with lib;

let cfg = config.system.autoUpgrade; in

{

  options = {

    system.autoUpgrade = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to periodically upgrade NixOS to the latest
          version. If enabled, a systemd timer will run
          <literal>nixos-rebuild switch --upgrade</literal> once a
          day.
        '';
      };

      channel = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = https://nixos.org/channels/nixos-14.12-small;
        description = ''
          The URI of the NixOS channel to use for automatic
          upgrades. By default, this is the channel set using
          <command>nix-channel</command> (run <literal>nix-channel
          --list</literal> to see the current value).
        '';
      };

      flags = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [ "-I" "stuff=/home/alice/nixos-stuff" "--option" "extra-binary-caches" "http://my-cache.example.org/" ];
        description = ''
          Any additional flags passed to <command>nixos-rebuild</command>.
        '';
      };

      dates = mkOption {
        default = "04:40";
        type = types.str;
        description = ''
          Specification (in the format described by
          <citerefentry><refentrytitle>systemd.time</refentrytitle>
          <manvolnum>7</manvolnum></citerefentry>) of the time at
          which the update will occur.
        '';
      };

      allowReboot = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Shall the system be rebooted if the new configuration
          uses a different kernel, kernel modules or initrd
          than the booted system?
        '';
      };

    };

  };

  config = lib.mkIf cfg.enable {

    system.autoUpgrade.flags =
      [ "--no-build-output" ]
      ++ (if cfg.channel == null
          then [ "--upgrade" ]
          else [ "-I" "nixpkgs=${cfg.channel}/nixexprs.tar.xz" ]);

    systemd.services.nixos-upgrade = {
      description = "NixOS Upgrade";

      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;

      serviceConfig.Type = "oneshot";

      environment = config.nix.envVars //
        { inherit (config.environment.sessionVariables) NIX_PATH;
          HOME = "/root";
        } // config.networking.proxy.envVars;

      path = [ pkgs.coreutils pkgs.gnutar pkgs.xz.bin pkgs.gitMinimal config.nix.package.out ];

      script = ''
        ${lib.optionalString cfg.allowReboot ''
          set -euo pipefail
          T=$(mktemp -d)
          cd "$T"
          ${config.system.build.nixos-rebuild}/bin/nixos-rebuild build ${toString cfg.flags}
          booted="$(readlink /run/booted-system/{initrd,kernel,kernel-modules})"
          built="$(readlink result/{initrd,kernel,kernel-modules})"
          cd /tmp
          rm -rf "$T"
          if [ "$booted" = "$built" ]; then
            ${config.system.build.nixos-rebuild}/bin/nixos-rebuild switch ${toString cfg.flags}
          else
            ${config.system.build.nixos-rebuild}/bin/nixos-rebuild boot ${toString cfg.flags}
            /run/current-system/sw/bin/shutdown -r +1
          fi
          ''}
          ${lib.optionalString (!cfg.allowReboot) "${config.system.build.nixos-rebuild}/bin/nixos-rebuild switch ${toString cfg.flags}"}
        '';

      startAt = cfg.dates;
    };

  };

}
