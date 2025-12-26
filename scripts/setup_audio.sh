#!/bin/bash

echo "=== Configuring Audio (PipeWire + RNNoise + Low Latency) ==="

# ==============================================================================
# 1. REALTIME KIT (RtKit)
# Matches security.rtkit.enable = true
# Required for PipeWire to acquire high-priority scheduling
# ==============================================================================
echo "Enabling RtKit..."
sudo systemctl enable --now rtkit-daemon

# ==============================================================================
# 2. PIPEWIRE LOW LATENCY
# Matches services.pipewire.extraConfig
# Updated with 'allowed-rates' to support 44.1kHz content properly
# ==============================================================================
echo "Configuring Low Latency (48kHz / 64 Quantum)..."
sudo mkdir -p /etc/pipewire/pipewire.conf.d

cat <<EOF | sudo tee /etc/pipewire/pipewire.conf.d/10-low-latency.conf
context.properties = {
    # Primary Sample Rate
    default.clock.rate = 48000

    # Supported Rates (Prevents resampling 44.1kHz audio if hardware supports it)
    default.clock.allowed-rates = [ 48000 44100 ]

    # Low Latency Settings (1.33ms target)
    default.clock.quantum = 64
    default.clock.min-quantum = 64
    default.clock.max-quantum = 512
}
EOF

# ==============================================================================
# 3. WIREPLUMBER CONFIGURATION (Bluetooth & Camera)
# Arch uses WirePlumber 0.5+ (SPA-JSON format, Lua is deprecated)
# ==============================================================================
echo "Configuring WirePlumber..."
sudo mkdir -p /etc/wireplumber/wireplumber.conf.d

# Bluetooth Tweaks (LDAC, Hardware Volume, etc.)
cat <<EOF | sudo tee /etc/wireplumber/wireplumber.conf.d/51-bluez-config.conf
monitor.bluez.properties = {
    bluez5.enable-sbc-xq = true
    bluez5.enable-msbc = true
    bluez5.enable-hw-volume = true
    bluez5.headset-roles = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
    bluez5.a2dp.ldac.quality = "auto"
    bluez5.a2dp.aac.bitratemode = 0
    bluez5.default.rate = 48000
    bluez5.default.channels = 2
}
EOF

# Disable Camera Audio (V4L2 / Libcamera monitors)
# Prevents webcams from showing up as poor-quality audio devices
cat <<EOF | sudo tee /etc/wireplumber/wireplumber.conf.d/51-disable-camera.conf
monitor.v4l2.rules = [
  {
    matches = [
      { node.name = "~.*" }
    ]
    actions = {
      update-props = {
        node.disabled = true
      }
    }
  }
]

monitor.libcamera.rules = [
  {
    matches = [
      { node.name = "~.*" }
    ]
    actions = {
      update-props = {
        node.disabled = true
      }
    }
  }
]
EOF

# ==============================================================================
# 4. BLUETOOTH DAEMON CONFIG
# Matches hardware.bluetooth.settings
# ==============================================================================
echo "Configuring Bluez Daemon..."
CONF="/etc/bluetooth/main.conf"

# Enable Experimental features (Battery reporting, etc.)
if [ -f "$CONF" ]; then
    sudo sed -i 's/^#Experimental = false/Experimental = true/' "$CONF"
    sudo sed -i 's/^#FastConnectable = false/FastConnectable = true/' "$CONF"
fi

sudo systemctl enable --now bluetooth

# ==============================================================================
# 5. RNNOISE CONFIGURATION (Noise Suppression)
# Matches 99-input-denoising.conf from NixOS
# USES: /usr/lib/ladspa/librnnoise_ladspa.so (from noise-suppression-for-voice)
# ==============================================================================
echo "Configuring RNNoise Filter Chain..."

# Check if the plugin exists to prevent pipewire errors
PLUGIN_PATH="/usr/lib/ladspa/librnnoise_ladspa.so"

if [ ! -f "$PLUGIN_PATH" ]; then
    echo "WARNING: $PLUGIN_PATH not found!"
    echo "Please ensure 'noise-suppression-for-voice' package is installed."
else
    cat <<EOF | sudo tee /etc/pipewire/pipewire.conf.d/99-input-denoising.conf
context.modules = [
{   name = libpipewire-module-filter-chain
    args = {
        node.description =  "Noise Canceling Source"
        media.name =  "Noise Canceling Source"
        filter.graph = {
            nodes = [
                {
                    type = ladspa
                    name = rnnoise
                    plugin = $PLUGIN_PATH
                    label = noise_suppressor_stereo
                    control = {
                        "VAD Threshold (%)" = 70.0
                        "VAD Grace Period (ms)" = 200
                        "Retroactive VAD Grace (ms)" = 0
                    }
                }
            ]
        }
        capture.props = {
            node.name =  "capture.rnnoise_source"
            node.passive = true
            audio.rate = 48000
        }
        playback.props = {
            node.name =  "rnnoise_source"
            media.class = Audio/Source
            audio.rate = 48000
        }
    }
}
]
EOF
fi

# ==============================================================================
# 6. ENABLE SERVICES
# ==============================================================================
echo "Restarting Audio Services..."
# Restart user-level PipeWire services to apply changes
systemctl --user enable --now pipewire pipewire-pulse wireplumber
systemctl --user restart pipewire wireplumber

echo "Audio setup complete."
echo "Low Latency: Active (64/48000)"
echo "RNNoise: Active (Look for 'Noise Canceling Source' in your input list)"
