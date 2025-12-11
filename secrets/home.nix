{ lib, config, ... }:
{
  home.activation.sops-nix = lib.mkForce ''
    	export A=B ${
       builtins.concatStringsSep " " (
         lib.mapAttrsToList (name: value: "'${name}=${value}'") config.sops.environment
       )
     }
    	${builtins.elemAt config.systemd.user.services.sops-nix.Service.ExecStart 0} > /dev/null 2>&1 
  '';
}
