#!/bin/sh

set -e

USER=`whoami`
INSTALL_PATH="$HOME/smqdrv"
REPO_URL="https://github.com/lysenkooo/smqu-rpi.git"

if [ "$USER" = "root" ]; then
    echo 'You are root'
    exit 1
fi

# essentials
sudo apt-get update
sudo apt-get install -y curl git build-essential vim

# nodejs
if [ ! -f /usr/local/bin/node ]; then
    sudo wget https://nodejs.org/dist/v10.15.0/node-v10.15.0-linux-armv6l.tar.xz -O /tmp/node.tar.xz
    sudo tar --strip-components 1 -xf /tmp/node.tar.xz -C /usr/local
    sudo rm /tmp/node.tar.xz
fi

# repo
mkdir -p "$HOME/.ssh"
ssh-keyscan -t rsa github.com > "$HOME/.ssh/known_hosts"
test -d "$INSTALL_PATH/.git" || git clone $REPO_URL $INSTALL_PATH
cd $INSTALL_PATH && git fetch origin && git reset --hard origin/master

# install driver
cd $INSTALL_PATH
cp -n .env.sample .env
npm install

# run service
sudo tee /etc/systemd/system/smqu-client.service <<EOT
[Unit]
Description=SMQU Client
After=network.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${INSTALL_PATH}
ExecStart=/usr/local/bin/node driver.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOT

sudo systemctl daemon-reload
sudo systemctl enable smqu-client.service
sudo systemctl restart smqu-client.service

echo "Done!"
