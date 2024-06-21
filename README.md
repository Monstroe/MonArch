# MonArch

## Minimalist Arch Linux Install Script.
This project installs Arch Linux with a very minimal amount of packages. The script was originally going to install and rice the [DWM](https://dwm.suckless.org/) window manager with rest of the [Suckless](https://suckless.org/) suite, but it was later decided this was out of scope (AKA I got lazy). That will be the next step if I ever revisit this project.

## Usage
1. Follow the [Arch Linux Installation Wiki](https://wiki.archlinux.org/title/Installation_guide) up to step 1.9.
2. Install git via ```pacman -Sy git``` (NOTE: You will need to be connected to the internet. Once again, refer to the [Arch Wiki](https://wiki.archlinux.org/) for guidance)
3. Clone this repository: ```git clone https://github.com/Monstroe/MonArch.git```
4. Execute the following commands:
```
cd MonArch
chmod +x monarch.sh
./monarch.sh
```

This will run the script, which will first prompt the user with some questions necessary for the installation. Once these questions have been answered, the script will begin the installation process.
