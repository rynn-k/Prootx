![Banner](https://napkinsdev.s3.us-east-1.amazonaws.com/next-s3-uploads/767790e0-516c-4cb7-97bc-8ea92d25f799/8218c6db585c.png)

# Prootx

Simple installer/uninstaller for Linux distros in Termux using `proot-distro`. Rootfs is stored in `$HOME` instead of `$PREFIX`.

## Usage

```bash
curl -sL https://raw.githubusercontent.com/rynn-k/Prootx/main/install.sh -o install.sh && bash install.sh
```

## What it does

- Asks for an alias (e.g. `ubuntu`, `debian`, `alpine`) — used as the image, container name, and login command
- Installs the distro and moves its rootfs to `$HOME/<alias>-rootfs`
- Creates a launcher so you can just type the alias to log in
- Uninstall option removes the distro, rootfs, and launcher

## Notes

- Alias must be a valid Docker Hub image (e.g. `ubuntu`, `debian`, `alpine`, `archlinux/archlinux`)
- No tag = `:latest`

## Example

After install, just run:
```bash
<alias>
```
to log in anytime.
