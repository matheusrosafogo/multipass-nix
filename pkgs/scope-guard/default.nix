{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "scope-guard";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "ricab";
    repo = "scope_guard";
    rev = "v1.1.0";
    hash = "sha256-7McJrwVcyMcotd0y2thgdQQthXNZhU26YRQvP5q/OLc=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 scope_guard.hpp $out/include/scope_guard.hpp
    runHook postInstall
  '';

  meta = {
    description = "C++11 scope guard that defends against implicitly ignored returns";
    homepage = "https://github.com/ricab/scope_guard";
    license = lib.licenses.unlicense;
    platforms = lib.platforms.all;
  };
}
