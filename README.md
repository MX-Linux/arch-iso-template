# MX/antiX Arch ISO Template

This repository packages an Arch ISO template used by MX/antiX snapshot and remaster workflows. It ships a prepared bootloader tree and a placeholder `arch/` layout that is populated at build time.

## What’s Included
- `arch-iso-template/` — the template filesystem used to build the ISO.
- `arch-iso-template/boot/grub/` — GRUB configs, themes, and boot assets.
- `arch-iso-template/arch/README` — expected layout for the Arch ISO files.
- `build.sh` — builds a distributable Arch package containing the template.

## Build
Build the package from the repo root:

```bash
./build.sh --arch
```

To write artifacts to a custom directory:

```bash
./build.sh --arch --out /path/to/output
```

The package is written to `build/` by default.

## Expected Arch Layout
The `arch-iso-template/arch/README` file documents the expected layout. In short, the build process expects files like:

- `arch/boot/x86_64/vmlinuz-linux`
- `arch/boot/x86_64/archiso.img`
- `arch/x86_64/airootfs.sfs`

Additional optional metadata files are described in the README inside the template.

## Notes
- `build.sh` uses `makepkg` and assumes a working Arch-style packaging toolchain.
- Large binary assets under `arch-iso-template/boot/grub/` are vendored; update them only when intentionally changing boot visuals or configs.

## License
See `LICENSE`.
