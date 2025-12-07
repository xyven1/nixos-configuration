{
  config,
  lib,
  ...
}: let
  cfg = config.custom.nginx;
in {
  options.custom.nginx = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable custom nginx module.";
    };
    fqdn = lib.mkOption {
      type = lib.types.str;
      description = "The fully-qualified domain name for ACME certificates.";
    };
    localSubnet = lib.mkOption {
      type = lib.types.str;
      description = "The local subnet to allow internal access.";
    };
    cloudflareCert = lib.mkOption {
      type = lib.types.nullOr (lib.types.submodule {
        options = {
          email = lib.mkOption {
            type = lib.types.str;
            description = "Email to use for Let's Encrypt registration.";
          };
          environmentFile = lib.mkOption {
            type = lib.types.str;
            description = "Path to file containing Cloudflare API token.";
          };
          wildcard = lib.mkOption {
            type = lib.types.bool;
            description = "Whether to request wildcard certificates.";
          };
        };
      });
      description = "Cloudflare ACME DNS provider configuration.";
      default = null;
    };
    ignoreUnlistedHosts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to completely ignore requests to unlisted virtual hosts.";
    };
    virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          locations = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule {
              options = {
                host = lib.mkOption {
                  type = lib.types.str;
                  default = "127.0.0.1";
                  description = "Backend host to proxy to.";
                };
                port = lib.mkOption {
                  type = lib.types.int;
                  description = "Backend port to proxy to.";
                };
                proxyHttps = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Whether to use https to backend.";
                };
                overrides = lib.mkOption {
                  type = lib.types.attrs;
                  default = {};
                  description = "Override location configuration for this path.";
                };
              };
            });
            default = {};
            description = "Location definitions for this virtual host.";
          };
          public = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether this host is publicly accessible.";
          };
          overrides = lib.mkOption {
            type = lib.types.attrs;
            default = {};
            description = "Override virtual host configuration.";
          };
        };
        config = {};
      });
      description = "Virtual host definitions.";
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [80 443];
    security.acme = lib.mkIf (cfg.cloudflareCert != null) {
      acceptTerms = true;
      certs."${cfg.fqdn}" = {
        email = cfg.cloudflareCert.email;
        dnsResolver = "1.1.1.1:53";
        domain = cfg.fqdn;
        extraDomainNames = lib.mkIf cfg.cloudflareCert.wildcard ["*.${cfg.fqdn}"];
        dnsProvider = "cloudflare";
        environmentFile = cfg.cloudflareCert.environmentFile;
        group = "nginx";
      };
    };

    # Nginx service
    services.nginx = {
      enable = true;
      appendHttpConfig = ''
        proxy_headers_hash_bucket_size 128;
        geo $internal_traffic {
          default 0;
          ${cfg.localSubnet} 1;
        }
      '';

      virtualHosts =
        (lib.mapAttrs'
          (subdomain: vhost: {
            name =
              if subdomain == ""
              then cfg.fqdn
              else "${subdomain}.${cfg.fqdn}";
            value = lib.mkMerge [
              {
                forceSSL = true;
                useACMEHost = cfg.fqdn;
                extraConfig = lib.mkIf (!vhost.public) ''
                  if ($internal_traffic = 0) {
                    return 444;
                  }
                '';
                locations =
                  lib.mapAttrs
                  (_: loc:
                    lib.mkMerge [
                      {
                        proxyPass = "${
                          if loc.proxyHttps
                          then "https"
                          else "http"
                        }://${loc.host}:${toString loc.port}/";
                        proxyWebsockets = true;
                        recommendedProxySettings = true;
                        extraConfig = lib.mkIf loc.proxyHttps ''
                          proxy_ssl_verify off;
                          proxy_ssl_session_reuse on;
                        '';
                      }
                      loc.overrides
                    ])
                  vhost.locations;
              }
              vhost.overrides
            ];
          })
          cfg.virtualHosts)
        // {
          _ = lib.mkIf cfg.ignoreUnlistedHosts {
            default = true;
            addSSL = true;
            useACMEHost = cfg.fqdn;
            extraConfig = ''
              deny all;
            '';
          };
        };
    };
  };
}
