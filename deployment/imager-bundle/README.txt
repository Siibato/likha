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

STEP 3 — Fill in your school configuration
------------------------------------------
Open "school-config.txt" in a text editor and fill in:
  MESH_GROUP_ID=ESATQL-2026    (REQUIRED — all your Pis must share this ID)
  SCHOOL_CODE=ESATQL           (optional — shown in the admin dashboard)

Save the file.

STEP 4 — Run the launcher
-------------------------
  Mac:    Double-click "Launch Likha Imager.command"
  Windows: Double-click "Launch Likha Imager.bat"

This will open Raspberry Pi Imager with "Likha Classroom Server" already selected.
After flashing, the launcher will automatically copy your school config to the SD card.

STEP 5 — Choose your device and flash
------------------------------------------------
  1. Select "Raspberry Pi 4" or "Raspberry Pi 5"
  2. Click "Likha Classroom Server" (it should already be selected)
  3. (Optional) Click the gear icon to set hostname, WiFi, or enable SSH
  4. Select your SD card under "Storage"
  5. Click "Flash" and wait ~10 minutes

STEP 6 — Apply school config (auto or manual)
-------------------------------------------
When Pi Imager shows "Done", the launcher will try to copy school-config.txt
to the SD card automatically. If it can't find the card, follow the prompt to
copy it manually:
  1. Re-insert the SD card into your computer
  2. Copy "school-config.txt" to the boot partition
  3. Rename the copied file to "likha-config.txt"

STEP 7 — Put the SD card in the Pi
-----------------------------------
Once flashing is complete, eject the SD card, insert it into the Raspberry Pi,
connect the Ethernet cable, and plug in power.

Wait for the green LED to blink rapidly — this means the server is ready!

============================================================
