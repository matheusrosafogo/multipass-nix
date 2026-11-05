{
  commonMeta,
  multipass_src,
  multipassd,
  version,

  autoPatchelfHook,
  flutter,
  gtkmm3,
  keybinder3,
  lib,
  libayatana-appindicator,
  libnotify,
  protobuf,
  protoc-gen-dart,
  qt6,
}:
flutter.buildFlutterApplication {
  inherit version;
  pname = "multipass-gui";
  src = multipass_src;

  sourceRoot = "${multipass_src.name}/src/client/gui";

  pubspecLock = lib.importJSON ./pubspec.lock.json;

  gitHashes = {
    dartssh2 = "sha256-y7Pk01PSOIpVQ8roOfKsQ01KF/9PIFVsIk3xSYkxq1c=";
    hotkey_manager_linux = "sha256-aO0h94YZvgV/ggVupNw8GjyZsnXrq3qTHRDtuhNv3oI=";
    tray_menu = "sha256-2f9glPp63IpDY/aNnPTfSTvYMjN4Us0FFbi0gl9SvLw=";
    window_size = "sha256-71PqQzf+qY23hTJvcm0Oye8tng3Asr42E2vfF1nBmVA=";
    xterm = "sha256-h8vIonTPUVnNqZPk/A4ZV7EYCMyM0rrErL9ZOMe4ZBE=";
  };

  buildInputs = [
    gtkmm3
    keybinder3
    libayatana-appindicator
    libnotify
    qt6.qtbase
    qt6.qtwayland
  ];

  nativeBuildInputs = [
    autoPatchelfHook
    protobuf
    protoc-gen-dart
    qt6.wrapQtAppsHook
  ];

  preBuild = ''
    # gdk-pixbuf 2.44 deprecates gdk_pixbuf_new_from_xpm_data, which the
    # Flutter Linux runner still uses. The upstream build treats warnings as
    # errors.
    substituteInPlace linux/CMakeLists.txt \
      --replace-fail 'target_compile_options(''${TARGET} PRIVATE -Wall -Werror)' \
                     'target_compile_options(''${TARGET} PRIVATE -Wall -Werror -Wno-error=deprecated-declarations)'

    mkdir -p lib/generated

    # Generate the Dart gRPC code for the Multipass GUI.
    protoc \
      --plugin=protoc-gen-dart=${lib.getExe protoc-gen-dart} \
      --dart_out=grpc:lib/generated \
      -I ../../rpc \
      ../../rpc/multipass.proto \
      google/protobuf/timestamp.proto
  '';

  runtimeDependencies = [ multipassd ];

  postInstall = ''
    mv $out/bin/multipass_gui $out/bin/multipass.gui

    install -Dm444 assets/icon.png \
      $out/share/icons/hicolor/256x256/apps/multipass.gui.png
    install -Dm444 assets/multipass.gui.autostart.desktop \
      $out/share/applications/multipass.gui.desktop
  '';

  meta = commonMeta // {
    description = "Flutter frontend application for managing Ubuntu VMs";
  };
}
