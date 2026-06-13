{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  numpy,
  pandas,
  pyarrow,
  pytz,
  setuptools,
  rustPlatform,
  cargo,
  rustc,
  neo4j,
}:
buildPythonPackage (finalAttrs: {
  pname = "neo4j-rust-ext";
  version = "6.2.0.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "neo4j";
    repo = "neo4j-python-driver-rust-ext";
    tag = finalAttrs.version;
    fetchSubmodules = true;
    hash = "sha256-nP2JCQ53RO0LUbDsft8f8k/B1Cj61y2O/hxuzSU8D/Y=";
  };

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    cargo
    rustc
  ];

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
    outputHashes = {};
  };

  build-system = [rustPlatform.maturinBuildHook];

  dependencies = [neo4j];

  optional-dependencies = {
    numpy = [numpy];
    pandas = [
      numpy
      pandas
    ];
    pyarrow = [pyarrow];
  };

  # Missing dependencies
  doCheck = false;

  pythonImportsCheck = ["neo4j"];

  postPatch = ''
    cp ${./Cargo.lock} Cargo.lock
    substituteInPlace pyproject.toml \
      --replace-fail '"pyo3/extension-module", "pyo3/generate-import-lib"' '"pyo3/extension-module"'
  '';

  meta = {
    description = "Rust Extensions for a Faster Neo4j Bolt Driver for Python";
    homepage = "https://github.com/neo4j/neo4j-python-driver-rust-ext";
    changelog = "https://github.com/neo4j/neo4j-python-driver-rust-ext/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [mhdask];
  };
})
