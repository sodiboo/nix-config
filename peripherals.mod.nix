{nari, ...}: {
  personal.modules = [
    {
      programs.adb.enable = true;
      users.users.sodiboo.extraGroups = ["adbusers"];

      services.udisks2.enable = true;
      services.gvfs.enable = true;
      services.devmon.enable = true;
    }
  ];
  sodium.modules = [
    nari.nixosModules.default
    ({pkgs, ...}: {
      hardware.wooting.enable = true;
      users.users.sodiboo.extraGroups = ["input"];

      environment.systemPackages = with pkgs; [
        openrgb-with-all-plugins
        openrazer-daemon
        polychromatic
      ];

      programs.droidcam.enable = true;
    })
  ];
  lithium.modules = [
    {
      # I have a fingerprint reader. I want to use it for sudo, polkit and the likes.
      services.fprintd.enable = true;

      # I'd like greetd to unlock my keyring, which fprint can't do.
      security.pam.services.greetd.fprintAuth = false;

      # And swaylock doesn't work well with fprint.
      security.pam.services.swaylock.fprintAuth = false;

      services.upower.enable = true;
    }
    {
      services.udev.extraRules = ''
        ACTION=="add|change", KERNEL=="event[0-9]*", ENV{ID_INPUT_TOUCHPAD}=="1", ENV{LIBINPUT_IGNORE_DEVICE}="1"
      '';
    }
  ];

  nitrogen.modules = [
    {
      services.upower.enable = true;
    }
  ];
}
