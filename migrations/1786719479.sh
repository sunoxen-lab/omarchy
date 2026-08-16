echo "Install the CS4208 speaker driver on 12-inch MacBooks"

# Fresh installs get the module and system service from the hardware setup, and
# the per-user WirePlumber rule from user setup. Existing users need all three:
# mainline detects the codec and PipeWire plays, but the speaker amp is never
# enabled and the speaker path has no usable hardware volume control.

product_name="${OMARCHY_MACBOOK12_AUDIO_MODEL:-$(cat /sys/class/dmi/id/product_name 2>/dev/null)}"
if [[ $product_name != "MacBook9,1" && $product_name != "MacBook10,1" ]]; then
  exit 0
fi

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
systemd_dir="${OMARCHY_SYSTEMD_DIR:-/etc/systemd/system}"
reboot_required=0

config_source="$OMARCHY_PATH/default/wireplumber/wireplumber.conf.d/51-macbook-cs4208-softvol.conf"
config_target="$config_home/wireplumber/wireplumber.conf.d/51-macbook-cs4208-softvol.conf"
if ! cmp -s "$config_source" "$config_target"; then
  install -Dm644 "$config_source" "$config_target"
  rm -rf "$state_home/wireplumber/default-routes"
  reboot_required=1
fi

service_source="$OMARCHY_PATH/install/hardware/apple/omarchy-cs4208-audio.service"
service_target="$systemd_dir/omarchy-cs4208-audio.service"
if ! cmp -s "$service_source" "$service_target"; then
  sudo install -Dm644 "$service_source" "$service_target"
  sudo systemctl daemon-reload
  reboot_required=1
fi
if ! systemctl is-enabled --quiet omarchy-cs4208-audio.service; then
  sudo systemctl enable omarchy-cs4208-audio.service
  reboot_required=1
fi

driver_installed=0
for module_name in macbook12-audio-driver macbook12-audio; do
  if dkms status -m "$module_name" -k "$(uname -r)" 2>/dev/null | grep -q ': installed'; then
    driver_installed=1
    break
  fi
done

if omarchy-pkg-missing macbook12-audio-driver-dkms; then
  if (( driver_installed == 0 )); then
    omarchy-pkg-add macbook12-audio-driver-dkms
    reboot_required=1
  fi
elif (( driver_installed == 0 )); then
  sudo dkms autoinstall -k "$(uname -r)"
  reboot_required=1
fi

# Rebooting loads the replacement codec module, applies the hardware mixer at a
# quiet point before login, and starts WirePlumber with the software-volume rule.
if (( reboot_required )); then
  omarchy-state set reboot-required
fi
