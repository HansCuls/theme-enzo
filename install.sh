#!/bin/bash
# Update TAMPILAN doang — cuma nyentuh 13 file frontend (tema + footer).
# TIDAK download panel.tar.gz penuh, TIDAK composer install, TIDAK migrate.
# app/, database/, config/, routes/, dan modifikasi custom kamu di situ
# nggak kesentuh sama sekali.

set -e

PANEL_DIR="/var/www/pterodactyl"
PATCH_FILE="theme-patch.tar.gz"   # taro file ini satu folder sama script ini, atau ganti path-nya

if [[ ! -f "$PATCH_FILE" ]]; then
  echo "!! $PATCH_FILE nggak ketemu di folder ini. Upload dulu file patch-nya ke server."
  exit 1
fi

cd "$PANEL_DIR"

echo ">> File yang bakal ketimpa (cuma ini doang, nggak lebih):"
tar -tzf "$PATCH_FILE"
echo ""
read -p "Lanjut? (y/n) " confirm
[[ "$confirm" == "y" ]] || { echo "Dibatalkan."; exit 0; }

BACKUP_DIR="/root/theme-backup-$(date +%s)"
echo ">> [1/4] Backup 13 file itu ke $BACKUP_DIR ..."
mkdir -p "$BACKUP_DIR"
for f in $(tar -tzf "$PATCH_FILE"); do
  if [[ -f "$f" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$f")"
    cp "$f" "$BACKUP_DIR/$f"
  fi
done

echo ">> [2/4] Extract patch tema ke $PANEL_DIR (cuma 13 file di atas)..."
tar -xzf "$PATCH_FILE" -C "$PANEL_DIR"

echo ">> [3/4] Build ulang frontend (yarn) — ini yang paling makan waktu..."
yarn install --frozen-lockfile
yarn build:production

echo ">> [4/4] Clear compiled view cache & fix ownership file baru..."
php artisan view:clear
chown -R www-data:www-data "$PANEL_DIR/public/assets" "$PANEL_DIR/resources/scripts" "$PANEL_DIR/tailwind.config.js"

echo ""
echo "Selesai. Yang keupdate cuma tampilan (13 file di atas + hasil build-nya)."
echo "app/, database/, config/, routes/ — sama sekali nggak kesentuh."
echo "Backup file lama ada di $BACKUP_DIR kalau perlu rollback manual."
