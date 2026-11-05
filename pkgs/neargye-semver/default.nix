{ lib, stdenv, fetchFromGitHub, cmake }:

stdenv.mkDerivation {
  pname = "neargye-semver";
  version = "1.0.0-rc";

  src = fetchFromGitHub {
    owner = "Neargye";
    repo = "semver";
    rev = "v1.0.0-rc";
    hash = "sha256-rM4+Zt/CDCUKOCEGcbwcXQee5mhfya1JwLyNzjMtYME=";
  };

  nativeBuildInputs = [ cmake ];

  cmakeFlags = [
    "-DSEMVER_OPT_INSTALL=ON"
    "-DSEMVER_OPT_BUILD_EXAMPLES=OFF"
    "-DSEMVER_OPT_BUILD_TESTS=OFF"
  ];

  meta = {
    description = "C++17 header-only semantic versioning library";
    homepage = "https://github.com/Neargye/semver";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
