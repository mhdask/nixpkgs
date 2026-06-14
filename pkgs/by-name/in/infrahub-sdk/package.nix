{
  lib,
  fetchFromGitHub,
  python3Packages,
}:
python3Packages.buildPythonPackage (finalAttrs: {
  pname = "infrahub-sdk";
  version = "1.9.8";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "opsmill";
    repo = "infrahub";
    tag = "infrahub-v${finalAttrs.version}";
    hash = "sha256-2kwDpbjIP7Y9EbJgRemxeLRXTzrOpdflO+UjbCV53l0=";
    fetchSubmodules = true;
  };
  sourceRoot = "source/python_sdk";
  build-system = [python3Packages.hatchling];
  pythonRelaxDeps = true;
  dontCheckRuntimeDeps = true;
})
