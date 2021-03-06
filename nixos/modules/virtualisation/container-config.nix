{ config, pkgs, lib, ... }:

with lib;

{

  config = mkIf config.boot.isContainer {

    # Disable some features that are not useful in a container.
    nix.optimise.automatic = mkDefault false; # the store is host managed
    services.udisks2.enable = mkDefault false;
    powerManagement.enable = mkDefault false;

    networking.useHostResolvConf = mkDefault (!config.services.resolved.enable);

    # Containers should be light-weight, so start sshd on demand.
    services.openssh.startWhenNeeded = mkDefault true;

    # Shut up warnings about not having a boot loader.
    system.build.installBootLoader = "${pkgs.coreutils}/bin/true";

    # Not supported in systemd-nspawn containers.
    security.audit.enable = false;

    # Use the host's nix-daemon.
    environment.variables.NIX_REMOTE = "daemon";

  };

}
