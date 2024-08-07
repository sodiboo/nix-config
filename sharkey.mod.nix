{
  oxygen.modules = [
    ({
      pkgs,
      config,
      ...
    }: {
      services.sharkey.enable = true;
      services.sharkey.domain = "gaysex.cloud";
      services.sharkey.database.passwordFile = config.sops.secrets.sharkey-db-password.path;
      services.sharkey.redis.passwordFile = config.sops.secrets.sharkey-redis-password.path;
      services.sharkey.settings = {
        id = "aidx";

        port = 3001;

        maxNoteLength = 8192;
        maxFileSize = 1024 * 1024 * 1024;
        proxyRemoteFiles = true;

        signToActivityPubGet = true;
        CheckActivityPubGetSigned = false;
      };

      services.meilisearch.masterKeyEnvironmentFile = config.sops.secrets.meili-master-key-env.path;
    })
  ];
}
