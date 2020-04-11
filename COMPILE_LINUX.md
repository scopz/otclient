## Ubuntu

First install required development packages using apt-get

```sh
sudo apt-get install -y build-essential cmake git-core
sudo apt-get install -y libboost-all-dev libphysfs-dev libssl-dev liblua5.1-0-dev
sudo apt-get install -y libglew-dev libvorbis-dev libopenal-dev zlib1g-dev
```

and if you are using 18.04, you may also need `sudo apt-get install -y libogg-dev`

Get the sources, compile and run

```sh
git clone git://github.com/edubart/otclient.git
cd otclient && mkdir -p build && cd build && cmake .. && make
./otclient
```

#### Common Ubuntu problems:

If you have this error at make:
```
Linking CXX executable otclient /usr/lib/gcc/x86_64-linux-gnu/5/../../../x86_64-linux-gnu/libphysfs.a: error adding symbols: Archive has no index; run ranlib to add one collect2: 
```

Then do:
```
sudo apt-get install libncurses5-dev
sudo apt-get install mercurial
hg clone -r stable-3.0 http://hg.icculus.org/icculus/physfs/
cd physfs
sudo mkdir build
cd build
sudo cmake ..
sudo make
sudo make install
sudo mv /usr/local/lib/libphysfs.a /usr/lib/x86_64-linux-gnu/.
```


## Manjaro/Arch 

First upgrade your system and install required development packages using pacman

```sh
sudo pacman -Syu && sudo pacman -S base-devel git cmake boost physfs openssl lua51 glew libvorbis openal zlib libogg
```

Get the sources, compile and run

```sh
git clone git://github.com/edubart/otclient.git
cd otclient && mkdir build && cd build && cmake .. && make
./otclient
```


## Fedora

These instructions were tested on Fedora 20. Some packages that I suggest to be installed might not actually be needed and there might be a simpler way to link in Lua, but I am not aware of it. In case of a problem, contact d33tah.

#### Install Lua 5.1 to /opt/lua5.1

```
sudo yum install readline-devel
yum-builddep lua
wget "http://www.lua.org/ftp/lua-5.1.5.tar.gz" -O- | tar zxvf -
cd lua-5.1.5
make linux
mkdir /opt/lua5.1
make INSTALL_TOP=/opt/lua5.1 install
```

#### Install needed packages

```
yum install boost-devel physfs-devel mesa-libGLw mesa-libGL-devel glew-devel openal-devel libvorbis-devel boost-system boost-thread boost-chrono boost-filesystem
```

#### Build otclient

The final command, `make`, will take most time. If you have a multi-core processor, try `make -j$(nproc)` to speed up the build process.

```
mkdir build && cd build
cmake  -DUSE_STATIC_LIBS=OFF -DLUA_LIBRARY=/opt/lua5.1/lib/liblua.a -DLUA_INCLUDE_DIR=/opt/lua5.1/include/ ..
make
```

#### Test if it runs

```
./otclient
```