{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  uv-build,
  anyio,
  typing-extensions,
}:
buildPythonPackage (finalAttrs: {
  pname = "fast-depends";
  version = "3.0.7";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "Lancetnik";
    repo = "FastDepends";
    tag = "${finalAttrs.version}";
    hash = "sha256-AjQS7aqz0/CojwHlyD6ZU575SdhxGcaA6unE62gzxnE=";
  };
  dependencies = [
    anyio
    typing-extensions
  ];
  build-system = [ uv-build ];
})
