{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  setuptools,
  setuptools-scm,
  prefect,
  redis,
}:
buildPythonPackage (finalAttrs: {
  pname = "prefect-redis";
  version = "0.2.11";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "PrefectHQ";
    repo = "prefect";
    tag = "prefect-redis-${finalAttrs.version}";
    hash = "sha256-mYqQKebUDwTpELUmWDkEFSUmxwM69AOw7rJOxgUiYbM=";
  };
  sourceRoot = "${finalAttrs.src.name}/src/integrations/prefect-redis";
  dependencies = [
    prefect
    redis
  ];
  build-system = [
    setuptools
    setuptools-scm
  ];
})
