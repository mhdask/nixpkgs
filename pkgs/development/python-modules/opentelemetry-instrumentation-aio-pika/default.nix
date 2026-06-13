{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  hatchling,
  opentelemetry-api,
  opentelemetry-instrumentation,
  opentelemetry-semantic-conventions,
}:
buildPythonPackage (finalAttrs: {
  pname = "opentelemetry-instrumentation-aio-pika";
  version = "0.55b0";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "open-telemetry";
    repo = "opentelemetry-python-contrib";
    tag = "v${finalAttrs.version}";
    hash = "sha256-UM9ezCh3TVwyj257O0rvTCIgfrddobWcVIgJmBUj/Vo=";

  };
  sourceRoot = "${finalAttrs.src.name}/instrumentation/opentelemetry-instrumentation-aio-pika";
  dependencies = [
    opentelemetry-api
    opentelemetry-instrumentation
    opentelemetry-semantic-conventions
  ];
  build-system = [ hatchling ];
})
