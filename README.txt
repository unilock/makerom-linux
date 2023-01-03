


MAKEROM.SH FOR LINUX



-- COMPATIBILITY --

GPUs: Radeon HD 7950
             HD 7970
             R9 280X

LINUX amd64: Any distribution should work, as long as you know what you're doing, and so long as its using GLIBC later than 2.33.
             (I probably should've compiled TianoCore for i386...)

OTHER OS / ARCH: You'll need to recompile TianoCompress. See ./Docs/TianoCompress.txt.



-- PREREQUISITES --

You'll need to install both Java (any version) and Python 3.
E.g. for Debian-based distros (Ubuntu should have these already):
$ sudo apt install default-jre python3

Dump the VBIOS from your GPU using e.g. `amdvbflash`. ( https://www.techpowerup.com/download/ati-atiflash/ )
Give it a useful name, e.g. "MSI-HD7950.rom".
Keep a copy of your VBIOS dump somewhere safe!

Find your GPU's 4 digit device ID using `lspci -nn`.
For example, if it's "1002:679a", you'll want only "679a".



-- USAGE --

./makerom.sh --rom=<VBIOS DUMP> --deviceid=<DEVICE ID>

It's pretty self-explanatory from there.



-- WARNING -- 

If you have a GOP (EFI code) in your VBIOS already (i.e. if it's larger than 64kb), then it will be overwritten with the new Mac EFI code, and your GPU will no longer function with UEFI Windows.



-- MISC --

If you recompile TianoCore + port this to PowerShell, this may even run on Windows!?



-- THANKS --

netkas: Created the original makerom.sh (bundle.tar.bz2)
jwilliams1967 (MacRumors): Provided the HD 7970 + R9 280X EFI code + headers (bundle2.zip)
ema1972 (MacRumors): Provided a valid VBIOS to test EfiCompress.macosx vs. TianoCompress
unilock (me): Ported makerom.sh to Linux & fixrom.py to Python 3



With love,
unilock <3
