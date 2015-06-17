#!/bin/bash
REV=$(git log --pretty=format:'%h' -n 1)
echo "[BUILD]: Saved current hash as revision: $REV...";
#date of build
DATE=$(date +%Y%m%d_%H%M%S)
./scripts/dt.sh
cd ~/dt
cp ~/kernel/avant/arch/arm/boot/zImage aokp/zImage
cp ~/kernel/avant/arch/arm/boot/dt.img aokp/dt.img
./mkboot aokp zip/out/boot.img
rm ~/dt/zip/out/modules/*.ko
cp -r ~/kernel/avant/out/modules/* ~/dt/zip/out/modules/
cd ~/dt/zip/out
rm *.zip
mv ~/dt/zip/out/modules/wlan.ko ~/dt/zip/out/modules/pronto/pronto_wlan.ko
zip -r boosted_afyon-"$DATE"-aokp-4.4.4-$REV.zip *
