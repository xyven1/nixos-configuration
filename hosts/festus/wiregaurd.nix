{
  networking.firewall = {
    allowedUDPPorts = [51820]; # Clients and peers can use the same port, see listenport
  };
  networking.wireguard.interfaces = {
    wg0 = {
      ips = ["10.200.30.11/24"];
      listenPort = 51820;
      privateKeyFile = "/home/xyven/.wg/private";

      peers = [
        {
          publicKey = "PPdF83YQ7U9nWSOzHhzqDHVEiPaDdfkmT8qZOb7YR0o=";
          presharedKeyFile = "/home/xyven/.wg/psk";
          allowedIPs = ["10.200.0.0/16"];
          endpoint = "bruellcarlisle.dyndns.org:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
