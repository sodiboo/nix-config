{
  shared.modules = [
    {
      networking.networkmanager.enable = true;
      users.users.sodiboo.extraGroups = ["networkmanager"];

      hardware.bluetooth.enable = true;
    }
  ];
}