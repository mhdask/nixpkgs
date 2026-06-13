{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  uv-build,
}:
buildPythonPackage (finalAttrs: {
  pname = "fastapi-storages";
  version = "0.5.0";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "smithyhq";
    repo = "fastapi-storages";
    tag = "${finalAttrs.version}";
    hash = "sha256-HOirLcBnhB3Q1Fry2erjSxJ4uNlvxyZkB8tiEN4ZnlY=";
  };
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'uv_build>=0.9.17,<0.10.0' 'uv_build'
  '';
  build-system = [ uv-build ];
})
