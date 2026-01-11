# Test to demonstrate validation error messages
# This file documents the expected error messages when required fields are missing

# Example 1: Missing domain field
# Expected error message when running with:
# qgroget.serviceModules.myService = {
#   enable = true;
#   dataDir = "/var/lib/myservice";
#   # Missing: domain = ...
# };
#
# Error output:
#   Service 'myService' is enabled but missing required field(s): domain
#
#   Configuration Error:
#   When qgroget.serviceModules.myService.enable = true, you must provide:
#     - domain (string): Domain name for the service (e.g., "myService.example.com")
#
#   Example fix:
#   qgroget.serviceModules.myService = {
#     enable = true;
#     domain = "myService.example.com";
#   };

# Example 2: Missing dataDir field
# Expected error message when running with:
# qgroget.serviceModules.myService = {
#   enable = true;
#   domain = "myservice.example.com";
#   # Missing: dataDir = ...
# };
#
# Error output:
#   Service 'myService' is enabled but missing required field(s): dataDir
#
#   Configuration Error:
#   When qgroget.serviceModules.myService.enable = true, you must provide:
#     - dataDir (string): Data directory path for persistent data (e.g., "/var/lib/myService")
#
#   Example fix:
#   qgroget.serviceModules.myService = {
#     enable = true;
#     dataDir = "/var/lib/myService";
#   };

# Example 3: Missing both domain and dataDir fields
# Expected error message when running with:
# qgroget.serviceModules.myService = {
#   enable = true;
#   # Missing: domain = ...
#   # Missing: dataDir = ...
# };
#
# Error output:
#   Service 'myService' is enabled but missing required field(s): domain, dataDir
#
#   Configuration Error:
#   When qgroget.serviceModules.myService.enable = true, you must provide:
#     - domain (string): Domain name for the service (e.g., "myService.example.com")
#     - dataDir (string): Data directory path for persistent data (e.g., "/var/lib/myService")
#
#   Example fix:
#   qgroget.serviceModules.myService = {
#     enable = true;
#     domain = "myService.example.com";
#     dataDir = "/var/lib/myService";
#   };

# To test validation errors manually:
# 1. Edit modules/server/default.nix or a host configuration
# 2. Enable a service without required fields
# 3. Run: sudo nixos-rebuild switch --flake .#YourHost
#    or: nix flake check
# 4. The evaluation should fail immediately with the clear error message above
