{picocss, ...}: {
  oxygen.modules = [
    ({
      lib,
      pkgs,
      config,
      ...
    }: let
      pico-just-the-css = pkgs.runCommand "pico-just-the-css" {} ''
        mkdir $out && cp -r ${picocss}/css $out
      '';

      # These should match `vps.sodi.boo` DNS records.
      # All other domains are (flattened) CNAMEs to `vps.sodi.boo`.

      oxygen-ipv4 = "85.190.241.69"; # IPv4 is unused here,
      oxygen-ipv6 = "2a02:c202:2189:7245::1"; # But DHCP doesn't give me IPv6.

      rapid-testing = false;
      generated-site = pkgs.callPackage ./nginx/gen.nix {};
      static-root =
        if rapid-testing
        then "/etc/nixos/nginx/result"
        else "${generated-site}";
    in {
      networking = {
        firewall.enable = true;
        firewall.allowedTCPPorts = [80 443];

        enableIPv6 = true;
        defaultGateway6.address = "fe80::1";
        defaultGateway6.interface = "ens18";
        interfaces.ens18.ipv6.addresses = [
          {
            address = oxygen-ipv6;
            prefixLength = 64;
          }
        ];
      };
      services.nginx = {
        enable = true;

        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

        appendHttpConfig = ''
          map $time_iso8601 $month {
            default "unreachable";
            "~^(?<y>\d{4})-(?<m>\d{2})-(?<d>\d{2})T" $m;
          }

          map $month $is_gay {
            default 0;
            "06" 1;
          }

          map $month $isnt_gay {
            default 1;
            "06" 0;
          }

          map $request_uri $is_domain_specific_well_known {
            default "0";
            "~^/.well-known/(discord|acme-challenge)" "1";
          }

          map "$is_gay$is_domain_specific_well_known" $is_gay_redirectable {
            default 0;
            "10" 1;
          }

          map "$isnt_gay$is_domain_specific_well_known" $isnt_gay_redirectable {
            default 0;
            "10" 1;
          }
        '';

        virtualHosts = let
          static = builtins.mapAttrs (path: conf:
            conf
            // {
              extraConfig =
                ''
                  rewrite ^${lib.escapeRegex (lib.removeSuffix "/" path)}(.+)$ $1 break;
                ''
                + conf.extraConfig or "";
            });
          base-http = locations: {
            extraConfig =
              ''
                error_page 502 /.nginx/502.html;
              ''
              + locations.extraConfig or "";
            locations =
              (builtins.removeAttrs locations ["extraConfig"])
              // static {
                "/.nginx/" = {
                  root = static-root;
                  extraConfig = ''
                    try_files /$server_name$uri $uri @picocss;
                  '';
                };
                "@picocss" = {
                  root = "${pico-just-the-css}";
                };
              };
          };
          base = locations:
            base-http locations
            // {
              forceSSL = true;
              enableACME = true;
            };
          proxy = port:
            base {
              "/".proxyPass = "http://127.0.0.1:${toString port}/";
              "/".proxyWebsockets = true;
            };
          personal-website = inactive: status: redirect: ''
            location = /blog {
              return 301 /blog/;
            }

            location / {
              root ${./sodi.boo/public};
              try_files $uri/index.html $uri.html $uri @picocss;
            }

            if (${inactive}) {
              return ${toString status} https://${redirect}$request_uri;
            }
          '';
        in {
          "0-sort-first" =
            base-http {
              "= /".extraConfig = ''
                rewrite . /.nginx/raw-ip.html last;
              '';
            }
            // {rejectSSL = true;};
          "sodi.boo" = base {
            "= /.well-known/discord".alias = ./sodi.boo/discord-domain-verification;
            extraConfig = personal-website "$is_gay_redirectable" 307 "sodi.gay";
          };
          "sodi.gay" = base {
            extraConfig = personal-website "$isnt_gay_redirectable" 307 "sodi.boo";
          };
          "gaysex.cloud" = proxy config.services.sharkey.settings.port;
          "infodumping.place" = proxy config.services.writefreely.settings.server.port;
          "search.gaysex.cloud" = proxy config.services.searx.settings.server.port;
        };
      };
      security.acme = {
        acceptTerms = true;
        defaults.email = "acme@sodi.boo";
      };
    })
  ];
}
