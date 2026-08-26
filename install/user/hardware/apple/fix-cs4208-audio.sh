# Use software volume for the CS4208 speaker path on 12-inch MacBooks.

product_name="${OMARCHY_MACBOOK12_AUDIO_MODEL:-$(cat /sys/class/dmi/id/product_name 2>/dev/null)}"
if [[ $product_name == "MacBook9,1" || $product_name == "MacBook10,1" ]]; then
  config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  state_home="${XDG_STATE_HOME:-$HOME/.local/state}"

  install -Dm644 \
    "$OMARCHY_PATH/default/wireplumber/wireplumber.conf.d/51-macbook-cs4208-softvol.conf" \
    "$config_home/wireplumber/wireplumber.conf.d/51-macbook-cs4208-softvol.conf"
  rm -rf "$state_home/wireplumber/default-routes"
fi
