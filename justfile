#nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#just

default:
    @just --list
    @just --fmt

@guide:
    echo "just git && just check_disk && just nix-disko 'deck' && just make-passwd 't' && just nix-install 'deck'"

git repo_url='https://github.com/Timmybrick/nixconf.git':
    #!/usr/bin/env bash
    set -euo pipefail
    nix --extra-experimental-features 'nix-command flakes' \
        shell nixpkgs#git --command git clone {{ repo_url }} ./nixos
    sudo mkdir -p /etc/nixos
    sudo cp -a ./nixos/. /etc/nixos

@check_disk:
    lsblk -o NAME,SIZE,MODEL,TYPE,MOUNTPOINTS

@nix-disko host='deck':
    sudo nix --experimental-features 'nix-command flakes' \
        run github:nix-community/disko -- --mode disko --flake .#{{ host }}

make-passwd original_password='t':
    #!/usr/bin/env bash
    set -euo pipefail

    mountpoint -q /mnt/persist || {
        echo "ERROR: /mnt/persist is not mounted. Run just nix-disko deck first." >&2
        exit 1
    }

    password_hash="$(
        printf '%s\n' {{ quote(original_password) }} |
            nix --experimental-features 'nix-command flakes' \
                shell nixpkgs#mkpasswd --command mkpasswd --stdin --method=sha-512
    )"

    sudo install -D -m 0600 /dev/null /mnt/persist/passwd
    printf '%s\n' "${password_hash}" | sudo tee /mnt/persist/passwd >/dev/null

@nix-install host='deck':
    #!/usr/bin/env bash
    set -euo pipefail
    sudo nixos-install \
        --root /mnt \
        --flake .#{{ host }} \
        --option accept-flake-config true \
        --option experimental-features 'nix-command flakes' \
        --option extra-substituters 'https://nyx-cache.chaotic.cx/' \
        --option extra-trusted-public-keys \
            'nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk='
    sync
