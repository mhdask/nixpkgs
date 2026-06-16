{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.infrahub;
  inherit (lib) types;
in
{
  options.services.infrahub = {
    enable = lib.mkEnableOption "Infrahub infrastructure management platform";

    package = lib.mkPackageOption pkgs "infrahub" { };

    frontend.package = lib.mkPackageOption pkgs "infrahub-frontend" { };

    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address the backend gunicorn process binds to.";
    };

    port = lib.mkOption {
      type = types.port;
      default = 8000;
      description = "Port the backend gunicorn process listens on.";
    };

    workers = lib.mkOption {
      type = types.ints.positive;
      default = 4;
      description = "Number of gunicorn worker processes.";
    };

    settings = lib.mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = lib.literalExpression ''
        {
          INFRAHUB_DB_ADDRESS = "db.example.com";
          INFRAHUB_CACHE_ADDRESS = "cache.example.com";
        }
      '';
      description = ''
        Environment variables passed to the backend service.
        All Infrahub settings can be configured this way using their
        {env}`INFRAHUB_*` names.
      '';
    };

    secretsFile = lib.mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to a file containing additional environment variables,
        including secrets like {env}`INFRAHUB_DB_PASSWORD`.
        The file should use the `key=value` format understood by
        systemd's `EnvironmentFile=`.
      '';
    };

    database = {
      createLocally = lib.mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to create and manage a local Neo4j instance.
          When enabled, {option}`services.neo4j` is configured automatically.
        '';
      };
    };

    cache = {
      createLocally = lib.mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to create and manage a local Redis instance.
          When enabled, {option}`services.redis` is configured automatically.
        '';
      };
    };

    broker = {
      createLocally = lib.mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to create and manage a local RabbitMQ instance.
          Infrahub requires a message broker at startup.
          When enabled, {option}`services.rabbitmq` is configured automatically.
        '';
      };
    };

    workflow = {
      createLocally = lib.mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to run a local Prefect server and worker for workflow execution.
          When enabled, a Prefect server is started on port 4200 and an Infrahub
          worker is started to process background tasks.
        '';
      };
    };

    nginx = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to configure nginx to serve the frontend and proxy
          API requests to the backend. Requires
          {option}`services.infrahub.nginx.domain` to be set.
        '';
      };

      domain = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "infrahub.example.com";
        description = "The domain name nginx should serve Infrahub under.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.nginx.enable -> cfg.nginx.domain != null;
        message = "services.infrahub.nginx.enable requires services.infrahub.nginx.domain to be set.";
      }
    ];

    services.neo4j = lib.mkIf cfg.database.createLocally {
      enable = true;
      https.enable = false;
      http.enable = true;
      extraServerConfig = ''
        dbms.security.auth_enabled=false
      '';
    };

    services.redis.servers.infrahub = lib.mkIf cfg.cache.createLocally {
      enable = true;
      bind = "127.0.0.1";
      port = 6379;
    };

    services.rabbitmq = lib.mkIf cfg.broker.createLocally {
      enable = true;
      configItems = {
        "default_user" = "infrahub";
        "default_pass" = "infrahub";
      };
    };

    systemd.services.infrahub-prefect-server = lib.mkIf cfg.workflow.createLocally {
      description = "Prefect server for Infrahub";
      wantedBy = [ "multi-user.target" ];
      after =
        [ "network-online.target" ]
        ++ lib.optional cfg.database.createLocally "neo4j.service"
        ++ lib.optional cfg.cache.createLocally "redis-infrahub.service";
      wants = [ "network-online.target" ];
      requires =
        lib.optional cfg.database.createLocally "neo4j.service"
        ++ lib.optional cfg.cache.createLocally "redis-infrahub.service";
      environment = {
        HOME = "/var/lib/infrahub";
        PREFECT_HOME = "/var/lib/infrahub/.prefect";
        INFRAHUB_DB_ADDRESS = lib.mkDefault "localhost";
        INFRAHUB_CACHE_ADDRESS = lib.mkDefault "localhost";
      };
      serviceConfig = {
        Type = "simple";
        User = "infrahub";
        Group = "infrahub";
        DynamicUser = true;
        StateDirectory = "infrahub";
        ExecStart = lib.escapeShellArgs [
          "${cfg.package}/bin/infrahub-prefect-server"
          "--host" "127.0.0.1"
          "--port" "4200"
        ];
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    systemd.services.infrahub-prefect-worker = lib.mkIf cfg.workflow.createLocally {
      description = "Prefect worker for Infrahub";
      wantedBy = [ "multi-user.target" ];
      after = [
        "infrahub-prefect-server.service"
        "infrahub.service"
      ];
      requires = [
        "infrahub-prefect-server.service"
        "infrahub.service"
      ];
      path = [ pkgs.git ];
      environment = {
        HOME = "/var/lib/infrahub";
        PREFECT_HOME = "/var/lib/infrahub/.prefect";
        PREFECT_API_URL = "http://127.0.0.1:4200/api";
        INFRAHUB_DB_ADDRESS = lib.mkDefault "localhost";
        INFRAHUB_CACHE_ADDRESS = lib.mkDefault "localhost";
        INFRAHUB_STORAGE_LOCAL_PATH = lib.mkDefault "/var/lib/infrahub/storage";
        INFRAHUB_GIT_GLOBAL_CONFIG_FILE = lib.mkDefault "/var/lib/infrahub/.gitconfig";
        INFRAHUB_GIT_REPOSITORIES_DIRECTORY = lib.mkDefault "/var/lib/infrahub/repositories";
        INFRAHUB_INTERNAL_ADDRESS = lib.mkDefault "http://${cfg.host}:${toString cfg.port}";
        INFRAHUB_METRICS_PORT = "8001";
      };
      serviceConfig = {
        Type = "simple";
        User = "infrahub";
        Group = "infrahub";
        DynamicUser = true;
        StateDirectory = "infrahub";
        ExecStart = "${cfg.package}/bin/prefect worker start --pool infrahub-worker --type infrahubasync";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    systemd.services.infrahub = {
      description = "Infrahub backend";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after =
        [ "network-online.target" ]
        ++ lib.optional cfg.database.createLocally "neo4j.service"
        ++ lib.optional cfg.cache.createLocally "redis-infrahub.service"
        ++ lib.optional cfg.broker.createLocally "rabbitmq.service"
        ++ lib.optional cfg.workflow.createLocally "infrahub-prefect-server.service";
      requires =
        lib.optional cfg.database.createLocally "neo4j.service"
        ++ lib.optional cfg.cache.createLocally "redis-infrahub.service"
        ++ lib.optional cfg.broker.createLocally "rabbitmq.service"
        ++ lib.optional cfg.workflow.createLocally "infrahub-prefect-server.service";

      environment =
        {
          INFRAHUB_DB_ADDRESS = lib.mkDefault "localhost";
          INFRAHUB_CACHE_ADDRESS = lib.mkDefault "localhost";
          INFRAHUB_STORAGE_LOCAL_PATH = lib.mkDefault "/var/lib/infrahub/storage";
          INFRAHUB_GIT_GLOBAL_CONFIG_FILE = lib.mkDefault "/var/lib/infrahub/.gitconfig";
          INFRAHUB_GIT_REPOSITORIES_DIRECTORY = lib.mkDefault "/var/lib/infrahub/repositories";
          INFRAHUB_INTERNAL_ADDRESS = lib.mkDefault "http://${cfg.host}:${toString cfg.port}";
          INFRAHUB_WORKFLOW_DRIVER = lib.mkDefault (if cfg.workflow.createLocally then "worker" else "local");
          INFRAHUB_WORKFLOW_PORT = lib.mkIf cfg.workflow.createLocally (lib.mkDefault "4200");
          INFRAHUB_FRONTEND_DIRECTORY = lib.mkDefault "${cfg.frontend.package}";
          HOME = "/var/lib/infrahub";
          PREFECT_HOME = "/var/lib/infrahub/.prefect";
          PREFECT_API_URL = lib.mkIf cfg.workflow.createLocally "http://127.0.0.1:4200/api";
        }
        // cfg.settings;

      serviceConfig = {
        Type = "simple";
        User = "infrahub";
        Group = "infrahub";
        DynamicUser = true;
        StateDirectory = "infrahub";
        RuntimeDirectory = "infrahub";
        EnvironmentFile = lib.mkIf (cfg.secretsFile != null) cfg.secretsFile;

        ExecStart = "${pkgs.writeShellScript "infrahub-start" ''
          key=/var/lib/infrahub/secret_key
          [ -f "$key" ] || ${pkgs.openssl}/bin/openssl rand -hex 32 > "$key"
          export INFRAHUB_SECURITY_SECRET_KEY=$(< "$key")
          exec ${lib.escapeShellArgs [
            "${cfg.package}/bin/gunicorn"
            "infrahub.server:app"
            "--workers"
            (toString cfg.workers)
            "--worker-class"
            "infrahub.serve.worker.InfrahubUvicorn"
            "--bind"
            "${cfg.host}:${toString cfg.port}"
          ]}
        ''}";

        Restart = "on-failure";
        RestartSec = "5s";

        CapabilityBoundingSet = "";
        PrivateDevices = true;
        ProtectHome = true;
        ProtectKernelLogs = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
      };
    };

    services.nginx = lib.mkIf cfg.nginx.enable {
      enable = true;
      virtualHosts.${cfg.nginx.domain} = {
        root = "${cfg.frontend.package}/dist";

        locations."/".tryFiles = "$uri $uri/ /index.html";

        locations."/api/".proxyPass = "http://${cfg.host}:${toString cfg.port}";
        locations."/graphql/".proxyPass = "http://${cfg.host}:${toString cfg.port}";
        locations."/docs/".proxyPass = "http://${cfg.host}:${toString cfg.port}";
      };
    };
  };
}
