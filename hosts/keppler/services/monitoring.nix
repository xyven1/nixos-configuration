{config, ...}: {
  services.prometheus = {
    enable = true;
    port = 9001;
    exporters = {
      ping = {
        enable = true;
        port = 9002;
        settings = {
          targets = [
            "1.1.1.1"
            "google.com"
          ];
          dns = {
            refresh = "1m";
            nameserver = "10.1.0.1";
          };
          ping = {
            interval = "1s";
            timeout = "1.5s";
            history-size = 60;
            fw-mark = 222;
          };
          options = {
            disableIPv6 = true;
          };
        };
        extraFlags = [
          "--metrics.rttunit=ms"
        ];
      };
    };
    scrapeConfigs = [
      {
        job_name = "ping";
        scrape_interval = "60s";
        static_configs = [
          {
            targets = ["localhost:${toString config.services.prometheus.exporters.ping.port}"];
          }
        ];
      }
    ];
  };
  custom.nginx.virtualHosts.monitor.locations."/".port = 2342;
  sops.secrets."grafana/secret_key" = {
    owner = "grafana";
    group = "grafana";
  };
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 2342;
        domain = "monitor.${config.networking.hostName}.${config.networking.domain}";
      };
      security = {
        secret_key = "$__file{${config.sops.secrets."grafana/secret_key".path}}";
      };
    };
  };
}
