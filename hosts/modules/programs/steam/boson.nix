{
  pkgs,
  stdenv,
  fetchzip,
  nix-update-script,
  ...
}:
stdenv.mkDerivation rec {
  pname = "boson-bin";
  version = "0.3.0";

  src = fetchzip {
    url = "https://github.com/FyraLabs/boson/releases/download/v${version}/boson-${version}-x86_64-musl.tar.zst";
    hash = "sha256-1muEpuwVm0tRJirWTc2zIo2mE0lrhXUf74XLhUmkdnk=";
    nativeBuildInputs = [ pkgs.zstd ];
  };

  passthru.updateScript = nix-update-script { };

  outputs = [
    "out"
    "steamcompattool"
  ];

  dontBuild = true;

  installPhase = ''
    mkdir $steamcompattool
    ln -s $src/* $steamcompattool
    rm $steamcompattool/compatibilitytool.vdf
    cp $src/compatibilitytool.vdf $steamcompattool
  '';
}
