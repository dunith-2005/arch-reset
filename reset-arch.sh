#!/bin/bash
set -e

echo ">>> WARNING: This will completely reset Arch Linux on this machine."
echo ">>> All data on /dev/sda2 (root) and /dev/sda1 (EFI/boot) will be lost."
echo ">>> You will be dropped into the official Arch installer (archinstall) to configure everything."
read -p "Type 'YES' to continue: " confirm
if [ "$confirm" != "YES" ]; then
  echo "Aborted."
  exit 1
fi

echo ">>> Syncing package databases..."
sudo pacman -Sy --noconfirm

echo ">>> Installing archinstall package..."
sudo pacman -S --noconfirm archinstall

echo ">>> Launching Arch Installer..."
archinstall
