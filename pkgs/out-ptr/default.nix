{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "out-ptr";
  version = "2025-04-07";

  src = fetchFromGitHub {
    owner = "soasis";
    repo = "out_ptr";
    rev = "02a577edfcf25e2519e380a95c16743b7e5878a1";
    hash = "sha256-yoV2ja54cIJ2NZWRMqrldTkInG/yAeRG9sI8/ceHang=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/include $out/share/out_ptr
    cp -r include/ztd $out/include/
    cp ${./out_ptr-config.cmake} $out/share/out_ptr/out_ptr-config.cmake
    runHook postInstall
  '';

  meta = {
    description = "C++11 implementation of std::out_ptr";
    homepage = "https://github.com/soasis/out_ptr";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
  };
}
