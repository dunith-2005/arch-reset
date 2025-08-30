#!/bin/bash
set -e

echo ">>> WARNING: This will reinstall Arch Linux on /dev/sda2 and reinstall bootloader on /dev/sda1."
echo ">>> Existing data on root (/) will be replaced, but since partitions are mounted, they will NOT be reformatted."
read -p "Type 'YES' to continue: " confirm
if [ "$confirm" != "YES" ]; then
  echo "Aborted."
  exit 1
fi

# Check mounts
if mount | grep -q "/dev/sda2 "; then
  echo ">>> /dev/sda2 is mounted (current root). Skipping format."
else
  echo ">>> Formatting /dev/sda2..."
  mkfs.ext4 -F /dev/sda2
fi

if mount | grep -q "/dev/sda1 "; then
  echo ">>> /dev/sda1 is mounted (boot). Skipping format."
else
  echo ">>> Formatting /dev/sda1..."
  mkfs.fat -F32 /dev/sda1
fi

echo ">>> Mounting target system..."
mount /dev/sda2 /mnt || true
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot || true

echo ">>> Bootstrapping fresh Arch install..."
pacstrap -K /mnt base linux linux-firmware nano vim git grub efibootmgr

echo ">>> Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo ">>> Entering chroot to configure system..."
arch-chroot /mnt /bin/bash -c "
  set -e
  echo '>>> Setting timezone...'
  ln -sf /usr/share/zoneinfo/UTC /etc/localtime
  hwclock --systohc

  echo '>>> Configuring locales...'
  sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
  locale-gen
  echo 'LANG=en_US.UTF-8' > /etc/locale.conf

  echo '>>> Setting hostname...'
  echo 'archlinux' > /etc/hostname
  cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   archlinux.localdomain archlinux
EOF

  echo '>>> Installing GRUB bootloader...'
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
  grub-mkconfig -o /boot/grub/grub.cfg

  echo '>>> Set root password now:'
  passwd
"

echo ">>> Unmounting..."
umount -R /mnt || true

echo ">>> Done! Reboot into your fresh Arch system."
