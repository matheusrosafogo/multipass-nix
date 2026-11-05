{ lib, stdenv, fetchFromGitHub, cmake }:

stdenv.mkDerivation {
  pname = "xz-embedded";
  version = "2024-12-30";

  src = fetchFromGitHub {
    owner = "tukaani-project";
    repo = "xz-embedded";
    rev = "v2024-12-30";
    hash = "sha256-0UrEB893EzZrWH2oS5gCe6aIxvhfu7hdPoB5pIZ7Bys=";
  };

  nativeBuildInputs = [ cmake ];

  postPatch = ''
    cp ${./CMakeLists.txt} CMakeLists.txt
  '';

  meta = {
    description = "Small, limited implementation of the .xz file format";
    homepage = "https://github.com/tukaani-project/xz-embedded";
    license = lib.licenses.bsd0;
    platforms = lib.platforms.all;
  };
}
