{
  callPackage,
  fetchFromGitHub,
  lib,
  stdenv,
  symlinkJoin,

  neargye-semver,
  out-ptr,
  scope-guard,
  xz-embedded,
}:

let
  name = "multipass";
  version = "1.17.0";

  multipass_src = fetchFromGitHub {
    owner = "canonical";
    repo = "multipass";
    rev = "refs/tags/v${version}";
    hash = "sha256-zh4/giZeT9j/xKQ4HSaY6vspxiJ8oHMKcI0qaTMi7ww=";
    fetchSubmodules = false;
  };

  commonMeta = {
    homepage = "https://multipass.run";
    license = lib.licenses.gpl3Plus;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
  };

  multipassd = callPackage ./multipassd.nix {
    inherit
      commonMeta
      multipass_src
      version
      neargye-semver
      out-ptr
      scope-guard
      xz-embedded
      ;
  };

  multipass-gui = callPackage ./gui.nix {
    inherit
      commonMeta
      multipass_src
      multipassd
      version
      ;
  };
in
symlinkJoin {
  inherit version;
  pname = name;

  paths = [
    multipassd
    multipass-gui
  ];

  passthru = {
    inherit multipassd;
    updateScript = ./update.sh;
  };

  meta = commonMeta // {
    description = "Ubuntu VMs on demand for any workstation";
  };
}
