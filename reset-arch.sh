#!/bin/bash
set -euo pipefail

# === SAFETY WARNING ===
echo ">>> WARNING: This will COMPLETELY WIPE /dev/sda1 and /dev/sda2 and reinstall Arch Linux."
echo ">>> All data will be LOST. Make backups before continuing!"
read -p "Type YES to continue: " confirm
if [[ "$confirm" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

# === Ensure dependencies ===
echo ">>> Installing required packages..."
pacman -Sy --noconfirm arch-install-scripts grub efibootmgr

# === Unmount previous mounts if busy ===
echo ">>> Cleaning up /mnt if mounted..."
umount -R /mnt 2>/dev/null || true

# === Format partitions ===
echo ">>> Formatting partitions..."
mkfs.ext4 -F /dev/sda2
mkfs.fat -F32 /dev/sda1

# === Mount partitions ===
echo ">>> Mounting target system..."
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

# === Bootstrap new Arch system ===
echo ">>> Bootstrapping Arch Linux..."
pacstrap -K /mnt base linux linux-firmware vim nano git grub efibootmgr

# === Generate fstab ===
echo ">>> Generating fstab..."
genfstab -U /mnt > /mnt/etc/fstab

# === Chroot and configure system ===
echo ">>> Entering chroot to configure system..."
arch-chroot /mnt /bin/bash -e <<'EOF'
set -euo pipefail

echo ">>> Setting timezone..."
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

echo ">>> Configuring locale..."
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo ">>> Setting hostname..."
echo "archlinux" > /etc/hostname
cat > /etc/hosts <<EOT
127.0.0.1   localhost
::1         localhost
127.0.1.1   archlinux.localdomain archlinux
EOT

echo ">>> Installing GRUB bootloader..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
grub-mkconfig -o /boot/grub/grub.cfg

echo ">>> Set a new root password now:"
passwd
EOF

# === Cleanup ===
echo ">>> Unmounting target system..."
umount -R /mnt || true

echo ">>> Reset complete! Reboot into your fresh Arch install."
