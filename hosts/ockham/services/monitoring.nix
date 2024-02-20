{config, ...}: {
  services.prometheus = {
    enable = true;
    port = 9001;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = ["systemd" "processes"];
        port = 9002;
      };
    };
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = ["localhost:${toString config.services.prometheus.exporters.node.port}"];
          }
        ];
        scrape_interval = "15s";
      }
    ];
  };
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 2342;
        domain = "monitor.${config.networking.hostName}.${config.networking.domain}";
      };
    };
  };
}
