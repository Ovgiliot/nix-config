{ pkgs, inputs, ... }:

{
  imports = [ inputs.doom-emacs.hmModule ];

  programs.doom-emacs = {
    enable = true;
    doomPrivateDir = ./doom.d;
    # emacsPackage = pkgs.emacs29; # Uncomment to override Emacs version
  };
}
