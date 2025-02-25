# REVOMOD
REVOPoint Key Frame Editor

ALWAYS WORK FROM A COPY OF YOUR SCAN DATA!!!

This is a very basic RevoPoint REVO Scan 5 frame editor that will HIDE/SHOW frames.  It will also duplicate SCAN project folders to allow a single scan to be broken up into mutiliple scans.
This can be useful when you have a scan that has lost tracking but are unable to rescan the item (due to time, travel or other factors).

More info is forth coming, but here are the basic steps:
1. Open REVO Scan 5.  Open the program and on the "home" screen, select the program you want to edit.
2. Click the the dots [...] and select "Open Folder"
3. In the address (file location) bar, copy the file location.  It should look something like this: C:\Users\Owner\AppData\Roaming\RevoScan5\Projects\Project20250225_12234526
4. Now RUN REVOMOD.EXE and Click [Open REVO Project] ![REVO_1](https://github.com/user-attachments/assets/5a7463ba-0345-4d48-8059-844315ef0e2b)
5. Past into the File Open Dialog the (File Location) and click on the .REVO project file
6. You should now see something like this![REVO_2](https://github.com/user-attachments/assets/53bf5138-e4f1-4908-b37d-e7f5f05a507f)
7. Now you have 2 directions to choose.  I like to do this:
8. Open the project in REVO Scan 5 and click on the SCAN that has tracking problem.
9. Click on the 3 dots [...] and select "Edit Key Frames" ![REVO_3](https://github.com/user-attachments/assets/aa958598-0d60-4560-9dd7-42358c4b6f13)
10. We can the example the scan is way out of alignment.  Press the [PLAY] button and watch the scan progress.  We are looking for 2 things.  How many time there are alignment issues and which frame.  Makes note on number of errors and which frames they occure.
11. In this example, the alignments goes bad at frame 500. ![REVO_4](https://github.com/user-attachments/assets/9c57cf1d-fcf0-4eed-b5f3-fd3b54e6cc90)
12. When you have made your notes on number of alignment errors and which frames that start, go back to the REVOMOD app.
13. Select the Model in the [Scan in Project] list and then Press [DUPLICATE FOLDER] ![Revo_5](https://github.com/user-attachments/assets/46c157d0-3171-4810-a3ef-63eec150a65e)
14. You will be asked to create a new name.  We need to select and duplicate the folder (with a different name) for each alignment error.
15. This does take up a lot of space as you are duplicating the project in FULL for each copy.  As you make each copy, the second window [REVO PROJECT] with update to reflect the new "SCAN PROJECT" you have created.
16. Now, for the most part, we are done with REVOMOD.  You need to close and reopen REVO Scan 5 and reload your modified project.  You will now see ALL the additional scans that were created.
17. You need to now edit each SCAN's Key Frames by removing the frames AFTER the alignment error.  For each additional SCAN, you need to remove all the FRAMES before the Alignment Error and after the next Alignment Error.
18. Fuse these scans and then MERGE them.  They should now align and give a good scan result.![Revo_6](https://github.com/user-attachments/assets/244a6699-727f-4e8e-b96b-750a06ab9254)

19. That is the basic.  The rest needs more work but here is what I know so far...
20. REVO Scan 5 does not really delete Key Frames.  It just FLAGs them as invisible to the model.  You are recover deleted key frames by selecting the [SCANS IN PROJECT] and then pressing [SELECT FOLDER]
21. The [SCAN FRAMES] window will populate with ALL the scan flag files in each Scan Project.
22. You can select all files and then press [SHOW FRAMES] and it will reset the flags to VISIBLE in that SCAN PROJECT FOLDER.  You must quit and reload the REVO Project for these changes to take effect (I am guessing CASHE memory clearing required)
23. You can also HIDE and SHOW KEY FRAMES in this window.  REVO Scan5 starts with FRAME 0 and then increaments by 2 [0,2,4,6 etc].  The list _SHOULD_ be in the the same order but I have been unable to fully verify that.
![Revo_7](https://github.com/user-attachments/assets/7d0fd302-127a-4b71-925d-529fc41ad2d7)
NOTE:  The SHOW/HIDE flag is not fully vetted.  This is what I know so far.  ALWAYS WORK FROM A COPY

My working notes...

1. Need to load the Project*.REVO file.  This file will set the location for the 
./data/ [FOLDERS]

./data/[FOLDER]/cache/

# IF # there is color scanning enabled, there will be 3 FILES.  If not color scanning is enabled, there will only be 2

--> 3 files for each "frame".  Each 3 files have the exact same name, just extension is different
----> .dph = depth data
----> .img = JPG format image file !- Only present if color scanning is enabled
----> .inf = unknown binary data (probably camera/sensor/IMU data), also contains "DELETED" frame flag from KEY FRAMES

00 00 00 00 01 02 00 02 00 1B B7 00 FF FF FF FF <--- SHOWS file in Key Frame listbox
00 00 00 00 01 03 01 02 00 00 00 00 FC FF FF FF <--- HIDES file in Key Frame listbox
== == == == == ^^ ^^ == == ^^ ^^ == ^^ == == ==
  +------------|| ||
  |
  This flag seems to control if the file is "HIDDEN" in the key frame view.
  02 00 = SHOW
  03 01 = HIDE
  !- File must be closed and then reopened to clear out the program data cache and reload the data for flag change to show up

Bruce Clark
02-25-02025
