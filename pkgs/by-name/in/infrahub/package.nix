{
  fetchFromGitHub,
  python3Packages,
}:
python3Packages.buildPythonPackage (finalAttrs: {
  pname = "infrahub-backend";
  version = "1.9.8";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "opsmill";
    repo = "infrahub";
    tag = "infrahub-v${finalAttrs.version}";
    hash = "sha256-1RFghluZsxPQXHSxYdzuwGaJMyu7T9tPY34dt97ze9Q=";
  };

  build-system = [ python3Packages.hatchling ];
  dependencies = with python3Packages; [
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
  ];
  nativeBuildInputs = [ python3Packages.pythonRelaxDepsHook ];
  pythonRelaxDeps = true;
  # dontCheckRuntimeDeps = true;
  # dontCheck = true;
})
