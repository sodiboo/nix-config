let
  icons = {
    calendar = "󰃭 ";
    clock = " ";
    battery.charging = "󱐋";
    battery.levels = [" " " " " " " " " "];
    network.disconnected = "󰤮 ";
    network.ethernet = "󰈀 ";
    network.strength = ["󰤟 " "󰤢 " "󰤥 " "󰤨 "];
    bluetooth.on = "󰂯";
    bluetooth.off = "󰂲";
    volume.source = "󱄠";
    volume.muted = "󰝟";
    volume.levels = ["󰕿" "󰖀" "󰕾"];
    idle.on = "󰈈 ";
    idle.off = "󰈉 ";
  };
in {
  shared.home_modules = [
    ({
      config,
      lib,
      ...
    }: {
      # lol this breaks boot sequence
      # home.activation.restart-waybar = lib.hm.dag.entryAfter ["writeBoundary"] ''
      #   run ${config.systemd.user.systemctlPath} --user restart waybar.service
      # '';

      # systemd.user.services.waybar.Service.ExecStart = lib.mkForce (builtins.concatStringsSep " " [
      #   "${config.programs.waybar.package}/bin/waybar"
      #   "-c ${config.xdg.configFile."waybar/config".source}"
      #   "-s ${config.xdg.configFile."waybar/style.css".source}"
      # ]);

      programs.waybar = {
        enable = true;
        systemd.enable = true;
      };
      programs.waybar.settings.mainBar = {
        layer = "top";
        modules-left = ["wireplumber#source" "wireplumber" "idle_inhibitor"];
        modules-center = ["clock#date" "clock"];
        modules-right = ["network" "bluetooth" "battery"];

        battery = {
          interval = 5;
          format = "{icon}  {capacity}%";
          format-charging = "{icon}  {capacity}% ${icons.battery.charging}";
          format-icons = icons.battery.levels;
          states.warning = 30;
          states.critical = 15;
        };

        clock = {
          interval = 1;
          format = "${icons.clock} {:%H:%M:%S}";
        };

        "clock#date" = {
          format = "${icons.calendar} {:%Y-%m-%d}";
        };

        network = {
          tooltip-format = "{ifname}";
          format-disconnected = icons.network.disconnected;
          format-ethernet = icons.network.ethernet;
          format-wifi = "{icon} {essid}";
          format-icons = icons.network.strength;
        };

        bluetooth = {
          format = "{icon}";
          format-disabled = "";
          format-icons = {
            inherit (icons.bluetooth) on off;
            connected = icons.bluetooth.on;
          };
          format-connected = "{icon} {device_alias}";
          format-connected-battery = "{icon} {device_alias} {device_battery_percentage}%";
        };

        wireplumber = {
          format = "{icon} {volume}%";
          format-muted = "${icons.volume.muted} {volume}%";
          format-icons = icons.volume.levels;
          reverse-scrolling = 1;
          tooltip = false;
        };

        "wireplumber#source" = {
          format = "${icons.volume.source} {node_name}";
          tooltip = false;
        };

        # "group/volume" = {
        #   orientation = "horizontal";
        #   modules = [
        #     "wireplumber"
        #     "wireplumber#source"
        #   ];
        #   drawer = {
        #     transition-left-to-right = true;
        #   };
        # };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = icons.idle.on;
            deactivated = icons.idle.off;
          };
        };
      };
      stylix.targets.waybar.enable = false;
      programs.waybar.style = let
        colors = config.lib.stylix.colors;
        modules = s: "${s ".modules-left"}, ${s ".modules-center"}, ${s ".modules-right"}";
        module = s: modules (m: "${m} > ${s} > *");
      in ''
        * {
            border: none;
            font-family: ${config.stylix.fonts.sansSerif.name};
            font-size: ${toString config.stylix.fonts.sizes.desktop}px;
            color: #${colors.base07};
        }

        window#waybar {
            background: transparent;
            font-size: 2em;
        }

        ${modules lib.id} {
            background: transparent;
            margin: 3px 10px;
        }

        ${module "*"} {
          margin: 3px 1px;
          padding: 5px 7px;
          background: #${colors.base00};
        }
        ${module ":first-child"} {
            padding-left: 10px;
            border-top-left-radius: 20px;
            border-bottom-left-radius: 20px;
        }

        ${module ":last-child"} {
            padding-right: 10px;
            border-top-right-radius: 20px;
            border-bottom-right-radius: 20px;
        }

        ${module ":not(:first-child)"} {
            border-top-left-radius: 3px;
            border-bottom-left-radius: 3px;
        }

        ${module ":not(last-child)"} {
            border-top-right-radius: 3px;
            border-bottom-right-radius: 3px;
        }

        #battery.charging {
            color: #${colors.green};
        }

        #battery.warning:not(.charging) {
            color: #${colors.base0A};
        }

        #battery.critical:not(.charging) {
            animation: critical-blink steps(8) 1s infinite alternate;
        }

        @keyframes critical-blink {
            to {
                color: #${colors.base09};
            }
        }
      '';
    })
  ];
}
