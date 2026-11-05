# Multipass para Nix

Pacote do [Multipass](https://multipass.run) 1.17.0 para Nix, com CLI, daemon
(`multipassd`), GUI Flutter e módulo NixOS.

O Multipass foi **removido do nixpkgs em 29/11/2025** por falta de mantenedor
(`multipass: remove unmaintained package and module`). Este projeto ressuscita o
pacote a partir da última versão que esteve no nixpkgs (1.16.1) e o atualiza para
a 1.17.0, que trouxe mudanças grandes de build: Rust (`rxx`), novas dependências
C++ e remoção dos backends LXD/libvirt.

## Uso rápido

```console
$ nix build .#multipass
$ ./result/bin/multipassd --help   # daemon
$ ./result/bin/multipass.gui       # GUI (precisa do daemon rodando)
```

O cliente `multipass` precisa do daemon e do certificado em
`/usr/local/etc/multipassd`; em uma instalação NixOS use o módulo abaixo.

Para usar como flake:

```nix
{
  inputs.multipass.url = "github:SEU_USUARIO/multipass-nix";

  outputs = { self, nixpkgs, multipass, ... }: {
    nixosConfigurations.minha-maquina = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        multipass.nixosModules.default
        {
          services.multipass.enable = true;
        }
      ];
    };
  };
}
```

Ou diretamente com o módulo do nixpkgs (quando o pacote for enviado upstream):

```nix
{
  services.multipass.enable = true;
}
```

## O que está incluído

- `multipass` (CLI + `multipassd` + `sshfs_server` + `bridge_helper`)
- `multipass.gui` (aplicação Flutter, com `libdart_ffi.so`)
- `nixosModules.multipass`: systemd service (`services.multipass`), diretórios
  de estado e pacote
- Teste NixOS (`checks.x86_64-linux.multipass`) que sobe o daemon e executa
  `multipass version` / `multipass list`

## Dependências novas empacotadas aqui

A 1.17.0 usa quatro bibliotecas que ainda não estão no nixpkgs:

| Pacote | Versão | Tipo |
| --- | --- | --- |
| `scope-guard` | 1.1.0 | header-only |
| `neargye-semver` | 1.0.0-rc | header-only + CMake |
| `out-ptr` | 2025-04-07 | header-only |
| `xz-embedded` | 2024-12-30 | C estático |

Elas ficam em `pkgs/` e são passadas ao pacote pelo `flake.nix`. Para enviar ao
nixpkgs, cada uma deve virar um pacote próprio em `pkgs/by-name/` (ou ser
substituída por uma equivalente já existente).

## Notas de empacotamento

O upstream baixa e compila tudo via vcpkg. O build daqui desativa o vcpkg e usa
as bibliotecas do nixpkgs; os patches em `pkgs/multipass/` fazem:

- `vcpkg_no_install.patch`: não faz bootstrap do vcpkg nem usa o toolchain dele.
- `qemu_paths.patch`: não copia QEMU/firmware do vcpkg; usa o QEMU do nixpkgs.
- `libssh_0_12.patch`: o libssh 0.12 removeu o símbolo privado
  `sftp_reply_version`; usa-se `sftp_server_init` (público, ainda exportado).
- Ajustes em `postPatch` para versão sem `.git`, Boost sem o componente `uuid`
  (header-only), OpenSSL via FindOpenSSL e warnings com `-Wno-error`.
- `dart_ffi`: a GUI carrega `libdart_ffi.so` via `dart:ffi`; ele é compilado
  junto do daemon e instalado em `$out/lib`.

## Testes

```console
$ nix build .#checks.x86_64-linux.multipass
```

O teste usa `nixosTest`, então precisa de KVM (ou roda com TCG, mais lento).

## Enviar para o nixpkgs

O pacote foi estruturado no estilo nixpkgs, mas ainda não foi enviado. Para
upstream, seria necessário:

1. Mover `pkgs/multipass` para `pkgs/by-name/mu/multipass/`.
2. Criar `pkgs/by-name/{sc/scope-guard,ne/neargye-semver,ou/out-ptr,xz/xz-embedded}`
   (ou reutilizar pacotes existentes).
3. Re-adicionar `nixos/modules/virtualisation/multipass.nix`, registrá-lo em
   `nixos/modules/module-list.nix` e re-adicionar o teste em
   `nixos/tests/all-tests.nix`.
4. Remover o `throw` de `multipass` em `pkgs/top-level/aliases.nix`.
5. Adicionar um mantenedor real em `meta.maintainers`.

## Limitações

- Apenas `x86_64-linux` está habilitado no `meta.platforms` (o upstream suporta
  mais arquiteturas, mas os caminhos de firmware/QEMU precisam de ajuste).
- O daemon grava certificados em `/usr/local/etc/multipassd` (caminho upstream
  para instalações que não são snap). O módulo cria esse diretório via
  `systemd.tmpfiles`.
- Não há AppArmor profile no NixOS; o daemon usa o perfil gerado em runtime.
