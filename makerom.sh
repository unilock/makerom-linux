#!/bin/bash

if ! command -v java &> /dev/null; then
    echo "Java not found!"
    exit -1
fi

if ! command -v python3 &> /dev/null; then
    echo "Python 3 not found!"
    exit -1
fi

# If I rewrote this to be entirely POSIX-compliant I would lose my mind.
# So if you don't have bash, cry.

PathScript="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PathTmp="$(mktemp -d)"

RomOrig=""
DevId=""

RomOrigSize=0

Fail=true
Fail2=true
Model=""

# Verify user input; if invalid, print help
if [[ $# != 2 || "$*" == *"-h"* || "$*" != *"--rom="* || "$*" != *"--deviceid="* ]]; then
    echo "Usage:"
    echo "$0 --rom=<VBIOS DUMP> --deviceid=<DEVICE ID>"
    exit -1

# If valid, interpret user input
else
    for i in "$@"; do
        case $i in
            --rom=*)
                RomOrig="$(echo $i | sed 's/.*=//')"
            ;;
            --deviceid=*)
                DevId=$(echo $i | sed 's/.*=//')
            ;;
        esac
    done
fi

# sed 's/.*=//'
#
# Remove all text before + including last "="
#
# "--rom=abcd"      --> "abcd"
# "--rom=abcd=wxyz" --> "wxyz"

# Check if `--rom=""` value is empty
if [[ -z "$RomOrig"  ]]; then
    echo "No VBIOS dump provided!"
    exit -1
fi

# Check if VBIOS dump exists
if [[ ! -e "${PWD}/${RomOrig}" ]]; then
    echo "VBIOS dump '${PWD}/${RomOrig}' does not exist!"
    exit -1
fi

# Verify device ID length
if [[ ${#DevId} != 4 ]]; then
    echo "Invalid device ID length"
    echo "Expected 4 characters, got ${#DevId}"
    echo ""
    echo "Example:"
    echo "If your PCI ID is 1002:679a,"
    echo "--deviceid=679a"
    exit -1
fi

RomOrigSize=$(java -cp "${PathScript}/Prgm" getSize "${PWD}/${RomOrig}")

while [[ ${Fail} == true ]]; do
    # Clear screen (preserve scrollback buffer)
    clear -x

    # Print menu
    echo "VBIOS dump        : ${RomOrig}"
    echo "VBIOS dump size   : ${RomOrigSize}"
    echo "Device ID         : ${DevId}"
    echo ""
    echo "Choose your GPU model:"
    echo ""
    echo "1) HD 7950"
    echo "2) HD 7970"
    echo "3) R9 280X"
    echo ""
    echo "q) Exit"
    echo ""
    # Get user input
    read -p "(1,2,3,q)? " ModelInput

    # Interpret user input
    case ${ModelInput} in
        1)
            Model="7950"
        ;;
        2)
            Model="7970"
        ;;
        3)
            Model="280X"
        ;;
        q)
            exit 0
        ;;
        *)
            echo ""
            read -p "Invalid input; press ENTER"
            Fail=true
        ;;
    esac

    if [[ ! -z "${Model}" ]]; then
        echo ""
        echo "Your selected model: '${Model}'"

        # Get + verify confirmation
        while [[ ${Fail2} == true ]]; do
            read -p "Is this correct? (y/n)? " ConfirmInput
            case ${ConfirmInput} in
                y|yes)
                    Fail=false
                    Fail2=false
                ;;
                n|no)
                    Fail=true
                    Fail2=false
                ;;
                *)
                    Fail2=true
                    echo "Invalid input"
                    echo ""
                ;;
            esac
        done
    fi
done

# Clear screen (preserve scrollback buffer)
clear -x

echo "[!] Copying Mac EFI code + ROM header + VBIOS dump to temporary directory..."
cp "${PathScript}/Efi/${Model}mac.efi" "${PathTmp}/mac.efi"
cp "${PathScript}/Rom/efiromheader_${Model}.rom" "${PathTmp}/header.rom"
cp "${PWD}/${RomOrig}" "${PathTmp}/orig.rom"

echo "[!] Patching EFI code + ROM header with appropriate device ID..."
java -cp "${PathScript}/Prgm" PatchRom "${PathTmp}/mac.efi" "${PathTmp}/header.rom" ${DevId}

echo "[!] Compressing patched EFI code..."
${PathScript}/Prgm/TianoCompress -e --uefi -o "${PathTmp}/mac.efi.compressed" "${PathTmp}/mac.efi"

echo "[!] Concatenating compressed EFI code to ROM header..."
dd if="${PathTmp}/mac.efi.compressed" of="${PathTmp}/header.rom" bs=1 seek=$((0x160)) conv=notrunc

echo "[!] Patched EFI is ready!"

echo "[!] Concatenating patched EFI to VBIOS dump..."
dd if="${PathTmp}/header.rom" of="${PathTmp}/orig.rom" bs=1 seek=${RomOrigSize} conv=notrunc

echo "[!] Finalizing patched VBIOS..."
python3 "${PathScript}/Prgm/fixrom3.py" "${PathTmp}/orig.rom" "${PathTmp}/orig.rom.mac"

echo "[!] Cleaning up..."
mv "${PathTmp}/orig.rom.mac" "${PWD}/${RomOrig}.mac"
rm -r "${PathTmp}"

echo "[!] Done! Your patched VBIOS is ready at ${RomOrig}.mac!"

exit 0
