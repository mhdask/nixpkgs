{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  hatchling,
  click,
  graphql-core,
  toml,
  httpx,
  pydantic,
  ruff,
}:
buildPythonPackage (finalAttrs: {
  pname = "ariadne-codegen";
  version = "0.18.0";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "mirumee";
    repo = "ariadne-codegen";
    tag = "${finalAttrs.version}";
    hash = "sha256-Xo56rY9Vj2AIMC7o0+3eWQDiJhfVZ+LTr39lPUTW0yQ=";
  };
  dependencies = [
    click
    graphql-core
    toml
    httpx
    pydantic
    ruff
  ];
  build-system = [ hatchling ];
})
