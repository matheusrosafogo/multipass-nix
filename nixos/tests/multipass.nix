{
  pkgs,
  multipass,
}:

pkgs.testers.nixosTest {
  name = "multipass";

  nodes.machine =
    { lib, ... }:
    {
      imports = [ ../multipass.nix ];

      virtualisation = {
        cores = 1;
        memorySize = 1024;
        diskSize = 4096;
      };

      services.multipass = {
        enable = true;
        package = multipass;
      };
    };

  testScript = ''
    machine.wait_for_unit("sockets.target")
    machine.wait_for_unit("multipass.service")

    # The daemon creates its certificates during startup; wait for them before
    # using the client.
    machine.wait_for_file("/usr/local/etc/multipassd/multipass_root_cert.pem")
    machine.wait_until_succeeds("multipass list")
    machine.succeed("multipass version")
  '';
}
