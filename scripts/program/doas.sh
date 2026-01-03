#!/bin/bash

# Check if doas is installed
if ! command -v doas &> /dev/null; then
    echo "Error: doas is not installed. Please install opendoas first."
    exit 1
fi

echo "=== Setting up doas for user 'spidy' ==="


# 2. Create or update the doas.conf file
echo "Creating /etc/doas.conf with permit spidy configuration..."
sudo tee /etc/doas.conf > /dev/null <<EOF
permit spidy
EOF

# 3. Set correct permissions for doas.conf
echo "Setting correct permissions for /etc/doas.conf..."
sudo chmod 0440 /etc/doas.conf

# 4. Verify the configuration
echo "Verifying doas configuration..."
if [ -f /etc/doas.conf ]; then
    echo "✓ /etc/doas.conf created successfully"
    echo "Contents:"
    sudo cat /etc/doas.conf
    echo ""
    
    # Check permissions
    perms=$(stat -c "%a" /etc/doas.conf)
    if [ "$perms" = "440" ]; then
        echo "✓ Correct permissions (440) set on /etc/doas.conf"
    else
        echo "✗ Incorrect permissions on /etc/doas.conf. Expected: 440, Got: $perms"
        echo "Setting correct permissions..."
        sudo chmod 0440 /etc/doas.conf
    fi
else
    echo "✗ Failed to create /etc/doas.conf"
    exit 1
fi

# 5. Test doas configuration
echo "Testing doas configuration..."
if sudo -u spidy doas -n whoami 2>/dev/null | grep -q "root"; then
    echo "✓ doas configuration test successful - user 'spidy' can execute commands as root"
else
    echo "⚠ doas configuration test failed or user 'spidy' may not exist"
    echo "Note: This is expected if user 'spidy' doesn't exist yet or if doas requires a password"
fi

echo "----------------------------------------------------"
echo "Setup Complete."
echo "User 'spidy' is now configured in /etc/doas.conf"
echo "The user can now use 'doas' to execute commands with elevated privileges"
echo ""
echo "Example usage:"
echo "  doas pacman -Syu"
echo "  doas systemctl restart service-name"