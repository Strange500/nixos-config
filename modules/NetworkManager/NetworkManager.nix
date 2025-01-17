{ pkgs, inputs, ... }:

{
    networking.networkmanager = {
        enable = true;
    };
    
    networking.firewall.checkReversePath = false; 

}
