{
  commonMeta,
  multipass_src,
  version,

  boost,
  cargo,
  cmake,
  dnsmasq,
  fmt_11,
  git,
  grpc,
  iproute2,
  iptables,
  lib,
  libapparmor,
  libssh,
  neargye-semver,
  ninja,
  openssl,
  out-ptr,
  pkg-config,
  protobuf,
  qemu,
  qemu-utils,
  qt6,
  rustPlatform,
  rustc,
  scope-guard,
  stdenv,
  xterm,
  xz-embedded,
  yaml-cpp,
}:

let
  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
  };
in
stdenv.mkDerivation {
  pname = "multipassd";
  inherit version;
  src = multipass_src;

  patches = [
    # Do not bootstrap vcpkg (which downloads and builds all C++ deps).
    ./vcpkg_no_install.patch
    # Do not copy QEMU binaries/firmware from the vcpkg tree; use the ones
    # provided by nixpkgs instead.
    ./qemu_paths.patch
    # libssh 0.12 removed the private sftp_reply_version symbol; use the
    # (deprecated but exported) public sftp_server_init entry point instead.
    ./libssh_0_12.patch
  ];

  postPatch = ''
    # The source tarball has no .git, so `git describe` cannot determine the
    # version. Pin it instead.
    substituteInPlace ./CMakeLists.txt \
      --replace-fail "determine_version(MULTIPASS_VERSION)" "" \
      --replace-fail 'set(MULTIPASS_VERSION ''${MULTIPASS_VERSION})' 'set(MULTIPASS_VERSION "${version}")' \
      --replace-fail "find_package(Boost CONFIG REQUIRED COMPONENTS json uuid)" "find_package(Boost CONFIG REQUIRED COMPONENTS json)" \
      --replace-fail "find_package(OpenSSL CONFIG REQUIRED)" "find_package(OpenSSL REQUIRED)" \
      --replace-fail "add_compile_options(-Werror -Wall -pedantic -fPIC)" "add_compile_options(-Werror -Wall -pedantic -fPIC -Wno-error)"

    # The Flutter GUI loads this small C++ helper through dart:ffi.  The normal
    # GUI CMake target is disabled here (the Dart bundle is built separately),
    # so build and install just the helper.
    cat >> CMakeLists.txt <<'EOF'

    add_library(dart_ffi SHARED src/client/gui/ffi/dart_ffi.cpp)
    target_include_directories(dart_ffi PRIVATE
      ''${CMAKE_SOURCE_DIR}/include
      ''${CMAKE_SOURCE_DIR}/src)
    target_link_libraries(dart_ffi
      client_common
      client_platform
      namegen
      utils
      Qt6::Core)
    install(TARGETS dart_ffi LIBRARY DESTINATION lib)
    EOF
  '';

  preConfigure = ''
    # Cargo is invoked by CMake; point it at the vendored crate sources.
    export CARGO_HOME=$TMPDIR/cargo-home
    mkdir -p $CARGO_HOME
    cat > $CARGO_HOME/config.toml <<EOF
    [source.crates-io]
    replace-with = "vendored-sources"

    [source.vendored-sources]
    directory = "${cargoDeps}"
    EOF
    export CARGO_NET_OFFLINE=true
  '';

  cmakeFlags = [
    "-GNinja"
    "-DMULTIPASS_ENABLE_FLUTTER_GUI=OFF"
    "-DMULTIPASS_ENABLE_TESTS=OFF"
    "-DFORCE_ENABLE_VIRTUALBOX=OFF"
  ];

  nativeBuildInputs = [
    cargo
    cmake
    git
    ninja
    pkg-config
    qt6.wrapQtAppsHook
    rustc
  ];

  buildInputs = [
    boost
    fmt_11
    grpc
    libapparmor
    libssh
    libssh.dev
    neargye-semver
    openssl
    out-ptr
    protobuf
    qt6.qtbase
    qt6.qtwayland
    scope-guard
    xz-embedded
    yaml-cpp
  ];

  preFixup = ''
    # The daemon invokes these tools at runtime.
    qtWrapperArgs+=(--prefix PATH : ${
      lib.makeBinPath [
        dnsmasq
        iproute2
        iptables
        qemu
        qemu-utils
        xterm
      ]
    })
  '';

  postInstall = ''
    # Multipass looks for QEMU firmware next to the binary. Link the firmware
    # shipped by the nixpkgs QEMU package instead of copying it.
    mkdir -p $out/Resources
    ln -s ${qemu}/share/qemu $out/Resources/qemu
  '';

  meta = commonMeta // {
    description = "Backend server and client for managing on-demand Ubuntu VMs";
  };
}
