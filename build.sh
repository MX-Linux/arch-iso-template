#!/usr/bin/env bash
set -euo pipefail

ME=${0##*/}

usage() {
    cat <<'EOF'
Usage:
  ./build.sh --arch [--out <dir>]

Options:
  --arch        Build the Arch ISO template tarball.
  --out <dir>   Output directory (default: ./build).
  -h, --help    Show this help.
EOF
}

mode=
out_dir=

while (( $# )); do
    case $1 in
        --arch) mode=arch; shift ;;
        --out) out_dir=${2:-}; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "$ME: unknown argument: $1" >&2; usage; exit 2 ;;
    esac
done

[[ -n $mode ]] || { usage; exit 2; }

script_dir=$(cd "$(dirname "$0")" && pwd)
template_dir="$script_dir/template"
out_dir=${out_dir:-"$script_dir/build"}

[[ -d $template_dir ]] || { echo "$ME: missing $template_dir" >&2; exit 2; }

version="26.01"

mkdir -p "$out_dir"

case $mode in
    arch)
        # Create temporary package build directory
        pkgbuild_dir=$(mktemp -d)
        pkg_dir="$pkgbuild_dir/pkg"
        work_dir=$(mktemp -d)

        # Copy template tree into a writable working directory
        cp -a "$template_dir/." "$work_dir/"

        # Copy GRUB assets from the arch template into the working tree
        chmod -R u+w "$work_dir/boot/grub/"
        cp -r "$template_dir/boot/grub/config" "$work_dir/boot/grub/"
        cp -r "$template_dir/boot/grub/fonts" "$work_dir/boot/grub/"
        cp -r "$template_dir/boot/grub/theme" "$work_dir/boot/grub/"
        cp "$template_dir/boot/grub/efi.img" "$work_dir/boot/grub/"
        cp "$template_dir/boot/grub/grubenv.cfg" "$work_dir/boot/grub/"
        cp "$template_dir/boot/grub/loopback.cfg" "$work_dir/boot/grub/"
        cp "$template_dir/boot/grub/unicode.pf2" "$work_dir/boot/grub/"

        # Create the source tarball first to get checksums
        tar --owner=0 --group=0 -czf "$pkgbuild_dir/iso-template.tar.gz" -C "$work_dir" .
        cp "$work_dir/arch/README" "$pkgbuild_dir/README"

        # Calculate checksums
        tar_sum=$(sha256sum "$pkgbuild_dir/iso-template.tar.gz" | cut -d' ' -f1)
        readme_sum=$(sha256sum "$pkgbuild_dir/README" | cut -d' ' -f1)

        # Create PKGBUILD
        cat > "$pkgbuild_dir/PKGBUILD" << EOF
pkgname=mx-iso-template-arch
pkgver=$version
pkgrel=1
pkgdesc="Arch ISO template for MX/antiX snapshot and remaster workflows"
arch=('any')
license=('GPL')
source=('iso-template.tar.gz'
        'README')
sha256sums=('$tar_sum'
            '$readme_sum')

package() {
    install -Dm644 "\$srcdir/iso-template.tar.gz" \
        "\$pkgdir/usr/lib/iso-template/arch/iso-template.tar.gz"

    install -Dm644 "\$srcdir/README" \
        "\$pkgdir/usr/share/doc/\$pkgname/README.arch-layout"
}
EOF

        # Build the package
        cd "$pkgbuild_dir"
        makepkg -f --noconfirm

        # Move the package to output directory
        mv *.pkg.tar.* "$out_dir/"
        package_file=$(ls "$out_dir"/*.pkg.tar.* | head -1)
        echo "$ME: wrote $package_file"

        # Cleanup
        rm -rf "$pkgbuild_dir" "$work_dir"
        ;;
esac
