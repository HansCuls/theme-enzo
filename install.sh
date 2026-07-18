#!/bin/bash
# Update TAMPILAN doang — cuma nyentuh 13 file frontend (tema + footer).
# Bisa dijalanin via: bash <(curl -s https://raw.githubusercontent.com/USER/REPO/BRANCH/install.sh)
# TIDAK download panel.tar.gz penuh, TIDAK composer install, TIDAK migrate.
# app/, database/, config/, routes/ nggak kesentuh sama sekali.

set -e

PANEL_DIR="/var/www/pterodactyl"
WEBSERVER_USER="www-data"

# Kalau theme-patch.tar.gz udah ada di folder saat ini, langsung dipake.
# Kalau nggak ada, di-download dari sini — GANTI ke URL raw file kamu.
PATCH_URL="https://raw.githubusercontent.com/HansCuls/theme-enzo/main/theme-patch.tar.gz"
LOCAL_PATCH="theme-patch.tar.gz"
WORK_PATCH="/tmp/theme-patch.tar.gz"

if [[ -f "$LOCAL_PATCH" ]]; then
  echo ">> Pake $LOCAL_PATCH yang udah ada di folder ini."
  cp "$LOCAL_PATCH" "$WORK_PATCH"
else
  echo ">> $LOCAL_PATCH nggak ada di folder ini, download dari repo..."
  curl -sL -o "$WORK_PATCH" "$PATCH_URL"
fi

# Sanity check: pastiin yang kedownload beneran file tar, bukan halaman 404/HTML
if ! tar -tzf "$WORK_PATCH" &>/dev/null; then
  echo "!! File di $WORK_PATCH bukan tar.gz yang valid."
  echo "!! Cek lagi: apakah theme-patch.tar.gz beneran udah di-push ke repo, dan PATCH_URL/branch-nya bener?"
  rm -f "$WORK_PATCH"
  exit 1
fi

cd "$PANEL_DIR"

echo ""
echo ">> File yang bakal ketimpa (cuma ini, nggak lebih):"
tar -tzf "$WORK_PATCH"
echo ""
read -p "Lanjut? (y/n) " confirm
[[ "$confirm" == "y" ]] || { echo "Dibatalkan."; rm -f "$WORK_PATCH"; exit 0; }

BACKUP_DIR="/root/theme-backup-$(date +%s)"
echo ">> [1/4] Backup file lama ke $BACKUP_DIR ..."
mkdir -p "$BACKUP_DIR"
for f in $(tar -tzf "$WORK_PATCH"); do
  if [[ -f "$f" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$f")"
    cp "$f" "$BACKUP_DIR/$f"
  fi
done

echo ">> [2/4] Extract patch tema ke $PANEL_DIR ..."
tar -xzf "$WORK_PATCH" -C "$PANEL_DIR"
rm -f "$WORK_PATCH"

echo ">> [3/4] Build ulang frontend (yarn) — paling makan waktu..."
yarn install --frozen-lockfile
yarn build:production

echo ">> [4/4] Clear compiled view cache & fix ownership file baru..."
php artisan view:clear
chown -R "$WEBSERVER_USER":"$WEBSERVER_USER" "$PANEL_DIR/public/assets" "$PANEL_DIR/resources/scripts" "$PANEL_DIR/tailwind.config.js"

echo ""
echo "Selesai. Yang keupdate cuma tampilan. app/, database/, config/, routes/ nggak kesentuh."
echo "Backup file lama ada di $BACKUP_DIR."

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
