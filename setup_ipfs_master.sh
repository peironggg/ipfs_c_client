#!/bin/sh

WORK_DIR=~

cd $WORK_DIR

# Install libcurl for client HTTP requests
sudo apt-get install libcurl4-openssl-dev

# Clone own forked version of filebench
git clone https://github.com/peironggg/filebench.git
cd filebench

# Setup filebench
libtoolize
aclocal
autoheader
automake --add-missing
autoconf

./configure
make
sudo make install

# Set filebench path
echo "export PATH=""/usr/local/lib/:$PATH" >> ~/.profile
source ~/.profile
# Disable randomize_va_space
sudo sysctl -w kernel.randomize_va_space=0

cd $WORK_DIR

# Install IPFS
wget https://dist.ipfs.tech/kubo/v0.15.0/kubo_v0.15.0_linux-amd64.tar.gz
tar -xvzf kubo_v0.15.0_linux-amd64.tar.gz
cd kubo
sudo bash install.sh

cd $WORK_DIR
rm -rf kubo*

# Setup IPFS private network
ipfs init
ipfs bootstrap rm --all

# Create swarm key if does not exist
if [ ! -f ~/.ipfs/swarm.key ]; then
  randomKey=`tr -dc 'a-f0-9' < /dev/urandom | head -c64`
  printf "/key/swarm/psk/1.0.0/\n/base16/\n${randomKey}" > ~/.ipfs/swarm.key
fi

# Grab peer ID of node
peerID=`ipfs id | grep 'ID' | cut -d':' -f2 | cut -d'"' -f2`
ipfs bootstrap add /ip4/10.10.1.1/tcp/4001/ipfs/${peerID}

# Disable local caching
ipfs config Datestore.StorageGCWatermark 0
ipfs config Datestore.StorageMax 0GB

bash -c "export LIBP2P_FORCE_PNET=1"

ipfs daemon --enable-gc