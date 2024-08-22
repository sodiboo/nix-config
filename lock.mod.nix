let
  scripts = {
    pkgs,
    config,
    ...
  }: let
    # wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
    # wl-paste = "${pkgs.wl-clipboard}/bin/wl-paste";
    convert = "${pkgs.imagemagick}/bin/convert";
    grim = "${pkgs.grim}/bin/grim";
    jq = "${pkgs.jq}/bin/jq";
    swaylock = "${config.programs.swaylock.package}/bin/swaylock";
    niri = "${config.programs.niri.package}/bin/niri";
    # for quick iteration
    magick_args = builtins.concatStringsSep " " [
      "-scale 2%"
      "-blur 0x.5"
      "-resize 5000%"
    ];
  in {
    lock = pkgs.writeScriptBin "blurred-locker" ''
      dir=/tmp/blurred-locker

      mkdir -p $dir

      for output in $(${niri} msg --json outputs | ${jq} -r "keys.[]"); do
        image="$dir/$output.png"

        ${grim} -o "$output" "$image"

        ${convert} "$image" ${magick_args} "$image"

        args+=" -i $output:$image"
      done

      ${niri} msg action do-screen-transition
      ${swaylock} $args

      rm -r $dir
    '';

    blur = image:
      pkgs.runCommand "blurred.png" {} ''
        ${convert} "${image}" ${magick_args} "$out"
      '';
  };
in {
  personal.modules = [
    ({
      lib,
      pkgs,
      config,
      ...
    }: let
      scripts' = scripts {
        inherit pkgs;
        config = config.home-manager.users.sodiboo;
      };
    in {
      options.stylix.blurred-image = with lib;
        mkOption {
          type = types.coercedTo types.package toString types.path;
          default = scripts'.blur config.stylix.image;
          readOnly = true;
        };

      config = {
      };
    })
  ];

  personal.home_modules = [
    ({
      lib,
      pkgs,
      config,
      ...
    }: let
      scripts' = scripts {
        inherit pkgs config;
      };
      niri = lib.getExe config.programs.niri.package;
    in {
      home.packages = [
        scripts'.lock
      ];
      programs.swaylock.enable = true;

      services.swayidle.enable = true;
      services.swayidle.timeouts = [
        {
          timeout = 300;
          command = "${niri} msg action spawn -- ${lib.getExe scripts'.lock}";
        }
        {
          timeout = 360;
          command = "${niri} msg action power-off-monitors";
        }
      ];
      systemd.user.services.swayidle.Unit = {
        Wants = ["niri.service"];
        After = "niri.service";
      };
    })
  ];
}
