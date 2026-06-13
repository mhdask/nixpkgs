{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  setuptools,
  prometheus-client,
  starlette,
}:
buildPythonPackage (finalAttrs: {
  pname = "starlette-exporter";
  version = "0.23.0";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "stephenhillier";
    repo = "starlette_exporter";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OfuiOBpyLQoiwTx/pz3md8dmbqo9vohkcXvudcZrk2U=";
  };
  dependencies = [
    starlette
    prometheus-client
  ];
  build-system = [ setuptools ];
})
