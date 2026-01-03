#!/bin/bash

# Check for sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit
fi

echo "=== Configuring Audio (PipeWire + RNNoise + Low Latency) ==="

# ==============================================================================
# 1. REALTIME KIT (RtKit)
# ==============================================================================
echo "Enabling RtKit..."
systemctl enable --now rtkit-daemon

# ==============================================================================
# 2. PIPEWIRE LOW LATENCY
# ==============================================================================
echo "Configuring Low Latency (48kHz / 64 Quantum)..."
mkdir -p /etc/pipewire/pipewire.conf.d

cat <<EOF | tee /etc/pipewire/pipewire.conf.d/10-low-latency.conf
context.properties = {
    # Primary Sample Rate
    default.clock.rate = 48000
    # Supported Rates
    default.clock.allowed-rates = [ 48000 44100 ]
    # Low Latency Settings
    default.clock.quantum = 128
    default.clock.min-quantum = 64
    default.clock.max-quantum = 1024
}
EOF

# ==============================================================================
# 3. WIREPLUMBER CONFIGURATION (Fixed for v0.5+)
# ==============================================================================
echo "Configuring WirePlumber..."
mkdir -p /etc/wireplumber/wireplumber.conf.d

# FIXED: Added commas and quotes for valid SPA-JSON syntax
cat <<EOF | tee /etc/wireplumber/wireplumber.conf.d/51-bluez-config.conf
monitor.bluez.properties = {
    "bluez5.enable-sbc-xq": true,
    "bluez5.enable-msbc": true,
    "bluez5.enable-hw-volume": true,
    "bluez5.headset-roles": "[ hsp_hs hsp_ag hfp_hf hfp_ag ]",
    "bluez5.a2dp.ldac.quality": "auto",
    "bluez5.a2dp.aac.bitratemode": 0,
    "bluez5.default.rate": 48000,
    "bluez5.default.channels": 2
}
EOF

# FIXED: Added commas
cat <<EOF | tee /etc/wireplumber/wireplumber.conf.d/51-disable-camera.conf
monitor.v4l2.rules = [
  {
    matches = [
      { "node.name": "~.*" }
    ],
    actions = {
      update-props = {
        "node.disabled": true
      }
    }
  }
]

monitor.libcamera.rules = [
  {
    matches = [
      { "node.name": "~.*" }
    ],
    actions = {
      update-props = {
        "node.disabled": true
      }
    }
  }
]
EOF

# ==============================================================================
# 4. BLUETOOTH DAEMON CONFIG
# ==============================================================================
echo "Configuring Bluez Daemon..."
CONF="/etc/bluetooth/main.conf"

if [ -f "$CONF" ]; then
    sed -i 's/^#Experimental = false/Experimental = true/' "$CONF"
    sed -i 's/^#FastConnectable = false/FastConnectable = true/' "$CONF"
fi

systemctl enable --now bluetooth

# ==============================================================================
# 5. RNNOISE CONFIGURATION
# ==============================================================================
echo "Configuring RNNoise Filter Chain..."

PLUGIN_PATH="/usr/lib/ladspa/librnnoise_ladspa.so"

if [ ! -f "$PLUGIN_PATH" ]; then
    echo "WARNING: $PLUGIN_PATH not found!"
    echo "Install via: sudo pacman -S noise-suppression-for-voice"
else
    # FIXED: Added commas
    cat <<EOF | tee /etc/pipewire/pipewire.conf.d/99-input-denoising.conf
context.modules = [
{   name = libpipewire-module-filter-chain
    args = {
        "node.description": "Noise Canceling Source",
        "media.name": "Noise Canceling Source",
        "filter.graph": {
            nodes = [
                {
                    type = ladspa
                    name = rnnoise
                    plugin = "$PLUGIN_PATH"
                    label = noise_suppressor_stereo
                    control = {
                        "VAD Threshold (%)": 70.0,
                        "VAD Grace Period (ms)": 200,
                        "Retroactive VAD Grace (ms)": 0
                    }
                }
            ]
        },
        "capture.props": {
            "node.name": "capture.rnnoise_source",
            "node.passive": true,
            "audio.rate": 48000
        },
        "playback.props": {
            "node.name": "rnnoise_source",
            "media.class": "Audio/Source",
            "audio.rate": 48000
        }
    }
}
]
EOF
fi

# ==============================================================================
# 6. FINISH
# ==============================================================================
echo "=== Audio Setup Complete ==="
echo "NOTE: To apply changes, please run the following command as your NORMAL USER (not sudo):"
echo "      systemctl --user restart pipewire wireplumber"
echo "      (Or simply reboot your computer)"