{
  lib,
  fetchFromGitHub,
  makeWrapper,
  python3,
}:
let
  python = python3.override {
    packageOverrides = final: prev: {
      dulwich = prev.dulwich.overridePythonAttrs (_: {
        doCheck = false;
      });
      infrahub-sdk = prev.infrahub-sdk.overridePythonAttrs (old: {
        src = fetchFromGitHub {
          owner = "mhdask";
          repo = "infrahub-sdk-python";
          rev = "whenever-bump";
          hash = "sha256-cDuWWVZYTWentIwWHpFwQHZLB7Fm3qFcc3/ciYCUj3A=";
        };
        dependencies = map (dep: if dep.pname or "" == "whenever" then final.whenever else dep) (
          old.dependencies or [ ]
        );
      });
    };
  };

  py = python.pkgs;

  dependencies = with py; [
    neo4j
    neo4j-rust-ext
    pydantic
    pydantic-settings
    pytest
    aio-pika
    structlog
    boto3
    email-validator
    redis
    hiredis
    typer
    click
    prefect
    prefect-redis
    ujson
    jinja2
    gitpython
    pyyaml
    tomli
    deepdiff
    # Dependencies specific to the API Server
    fastapi
    fastapi-storages
    graphene
    gunicorn
    lunr
    starlette-exporter
    python-multipart
    asgi-correlation-id
    bcrypt
    pyjwt
    uvicorn
    opentelemetry-instrumentation-aio-pika
    opentelemetry-instrumentation-fastapi
    grpcio
    opentelemetry-exporter-otlp-proto-grpc
    opentelemetry-exporter-otlp-proto-http
    nats-py
    netaddr
    authlib
    aiodataloader
    fast-depends
    cachetools-async
    puremagic
    # Dependencies specific to the SDK
    rich
    pyarrow
    numpy
    dulwich
    whenever
    netutils
    ariadne-codegen
    infrahub-sdk
  ];
in
py.buildPythonPackage {
  pname = "infrahub-backend";
  version = "1.1.10";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "opsmill";
    repo = "infrahub";
    rev = "release-1.10";
    hash = "sha256-rXaBwZHaPnGb+0Evr8M6t9jxAr9CgOd3xhpKj3D2Asw=";
  };
  build-system = [ py.hatchling ];
  inherit dependencies;
  nativeBuildInputs = [
    makeWrapper
    py.pythonRelaxDepsHook
  ];
  pythonRelaxDeps = true;
  doCheck = false;

  postInstall = ''
    pythonPath="${py.makePythonPath dependencies}:$out/${py.python.sitePackages}"
    makeWrapper ${lib.getExe py.gunicorn} $out/bin/gunicorn \
      --prefix PYTHONPATH : "$pythonPath"
    makeWrapper ${lib.getExe py.prefect} $out/bin/prefect \
      --prefix PYTHONPATH : "$pythonPath"
    makeWrapper ${lib.getExe py.uvicorn} $out/bin/infrahub-prefect-server \
      --prefix PYTHONPATH : "$pythonPath" \
      --add-flags "infrahub.prefect_server.app:create_infrahub_prefect --factory"
  '';
}
