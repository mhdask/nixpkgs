{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm_9,
  nodejs_24,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "infrahub-frontend";
  version = "1.1.10";

  src = fetchFromGitHub {
    owner = "opsmill";
    repo = "infrahub";
    rev = "8ca7ec3d04f3bfec034a267a34b50fa247c1747d";
    fetchSubmodules = true;
    hash = "sha256-rljkq9ixzLaq9WZ+ugSXUkRr0XWDY40cOow8f7ua5Hk=";
  };

  sourceRoot = "${finalAttrs.src.name}/frontend";

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    sourceRoot = "${finalAttrs.src.name}/frontend/app";
    pnpm = pnpm_9;
    fetcherVersion = 3;
    hash = "sha256-h9nyxLExVMAEcvZ2E5DMKv84+VcKZ1EXm5KZiyEY6Js=";
  };

  nativeBuildInputs = [
    nodejs_24
    pnpm_9
    pnpmConfigHook
  ];

  env.pnpmRoot = "app";

  buildPhase = ''
    runHook preBuild
    pushd app
    pnpm run build
    popd
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp -r app/dist $out
    runHook postInstall
  '';

  meta = {
    description = "Frontend for the Infrahub infrastructure management platform";
    homepage = "https://github.com/opsmill/infrahub";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ mhdask ];
    platforms = lib.platforms.all;
  };
})
