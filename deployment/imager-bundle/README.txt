============================================================
  Likha Classroom Server — SD Card Flasher
============================================================

WHAT YOU NEED
-------------
1. A computer (Windows or Mac)
2. A blank SD card (32 GB or larger)
3. An SD card reader / USB adapter

STEP 1 — Install Raspberry Pi Imager
------------------------------------
If you don't already have it, download and install from:
  https://www.raspberrypi.com/software/

(You only need to do this once.)

STEP 2 — Insert your SD card
----------------------------
Put the blank SD card into your computer using a card reader or USB adapter.

STEP 3 — Run the launcher
-------------------------
  Mac:    Double-click "Launch Likha Imager.command"
  Windows: Double-click "Launch Likha Imager.bat"

This will open Raspberry Pi Imager with "Likha Classroom Server" already selected.

STEP 4 — Choose your device and fill in details
------------------------------------------------
  1. Select "Raspberry Pi 4" or "Raspberry Pi 5"
  2. Click "Likha Classroom Server" (it should already be selected)
  3. Click the gear icon (top right)
  4. Type your School Code / Mesh Group ID (e.g., ESATQL-2026)
  5. (Optional) Add WiFi details if your Pi will connect to existing school WiFi
  6. Select your SD card under "Storage"
  7. Click "Flash" and wait ~10 minutes

STEP 5 — Put the SD card in the Pi
-----------------------------------
Once flashing is complete, eject the SD card, insert it into the Raspberry Pi,
connect the Ethernet cable, and plug in power.

Wait for the green LED to blink rapidly — this means the server is ready!

============================================================
