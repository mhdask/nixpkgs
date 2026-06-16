{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  hatchling,
  pydantic,
  pydantic-settings,
  graphql-core,
  httpx,
  ujson,
  dulwich,
  whenever,
  netutils,
  tomli,
  rustPlatform,
}:
let
  dulwich-patched = dulwich.overridePythonAttrs (_: {
    doCheck = false;
  });
  whenever-patched = whenever.overridePythonAttrs (old: rec {
    version = "0.9.5";
    src = fetchFromGitHub {
      owner = "ariebovenberg";
      repo = "whenever";
      tag = version;
      hash = "sha256-HGASKQHQWXPzMcTHylRG94ZdL2gwLyHyfoTywllMTdA=";
    };
    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-i5hbXk+CFrsnIhT3DjnWbP2GaIqJxll8fbxCFz/21M8=";
    };
  });
in
buildPythonPackage (finalAttrs: {
  pname = "infrahub-sdk";
  version = "1.21.1";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "opsmill";
    repo = "infrahub-sdk-python";
    tag = "v${finalAttrs.version}";
    hash = "sha256-QYgvcJS0EChr6mZFJMLHfptFaPJmCsufZYXNZurnC0c=";
  };
  dependencies = [
    pydantic
    pydantic-settings
    graphql-core
    httpx
    ujson
    dulwich-patched
    whenever-patched
    netutils
    tomli
  ];
  build-system = [ hatchling ];
  pythonRelaxDeps = true;
  dontCheckRuntimeDeps = true;
})
