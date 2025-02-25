#PBFORMS CREATED V1.51
'----------------------------------------------------------------------------------------------------------------------
' The first line in this file is a PB/Forms metastatement.
' It should ALWAYS be the first line of the file. Other
' PB/Forms metastatements are placed at the beginning and
' end of "Named Blocks" of code that should be edited
' with PBForms only. Do not manually edit or delete these
' metastatements or PB/Forms will not be able to reread
' the file correctly.  See the PB/Forms documentation for
' more information.
' Named blocks begin like this:    #PBFORMS BEGIN ...
' Named blocks end like this:      #PBFORMS END ...
' Other PB/Forms metastatements such as:
'     #PBFORMS DECLARATIONS
' are used by PB/Forms to insert additional code.
' Feel free to make changes anywhere else in the file.
'----------------------------------------------------------------------------------------------------------------------

#COMPILE EXE
#DIM ALL

'----------------------------------------------------------------------------------------------------------------------
'   ** Includes **
'----------------------------------------------------------------------------------------------------------------------
#PBFORMS BEGIN INCLUDES
#IF NOT %DEF(%WINAPI)
    #INCLUDE "WIN32API.INC"
#ENDIF
#PBFORMS END INCLUDES

#INCLUDE "COMMCTRL.INC"
#INCLUDE "COMDLG32.INC"

#INCLUDE "PBForms.INC"

#INCLUDE "GetFolder.inc"
'#INCLUDE "Settings_INI.inc"     'Save and load settings file

'----------------------------------------------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
'   ** Constants **
'----------------------------------------------------------------------------------------------------------------------
#PBFORMS BEGIN CONSTANTS
%IDC_BUTTON1  = 1004
%IDC_BUTTON2  = 1005
%IDC_BUTTON3  = 1006
%IDC_BUTTON4  = 1007
%IDC_BUTTON5  = 1008
%IDC_BUTTON6  = 1015
%IDC_BUTTON7  = 1017    '*
%IDC_LABEL1   = 1013
%IDC_LABEL2   = 1014
%IDC_LABEL3   = 1016
%IDC_LABEL4   = 1018
%IDC_LISTBOX1 = 1010
%IDC_LISTBOX2 = 1011
%IDC_TEXTBOX1 = 1001
%IDC_TEXTBOX2 = 1012
%IDD_DIALOG1  =  101
#PBFORMS END CONSTANTS
%FILEMAX  = 4000        ' max files in SCAN Frames, too many and programs slows WAY down
'----------------------------------------------------------------------------------------------------------------------

'--------------------------------------------------------------------------------
'   ** Version Information **
'--------------------------------------------------------------------------------
$Version="Version 0.1a © 2025 Bruce Clark"

$INIFile="REVOMOD.INI"

'------------------------------------------------------------------------------
'   ** Globals **
'------------------------------------------------------------------------------
GLOBAL hDlg  AS DWORD
GLOBAL Directory AS STRING
GLOBAL FileCount AS INTEGER
'------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
'   ** Declarations **
'----------------------------------------------------------------------------------------------------------------------
DECLARE CALLBACK FUNCTION ShowDIALOG1Proc()
DECLARE FUNCTION SampleListBox(BYVAL hDlg AS DWORD, BYVAL lID AS LONG, BYVAL lCount AS LONG) AS LONG
DECLARE FUNCTION ShowDIALOG1(BYVAL hParent AS DWORD) AS LONG
#PBFORMS DECLARATIONS

DECLARE SUB LoadList (DirPath AS STRING)
DECLARE SUB LoadINFList (DirPath AS STRING)
DECLARE FUNCTION GetDirectory() AS STRING
DECLARE FUNCTION OpenREVOFile() AS STRING
DECLARE FUNCTION LoadText(sFileName AS STRING) AS STRING
DECLARE FUNCTION SaveTextFile(sFileName AS STRING, NewFile AS STRING) AS LONG
DECLARE SUB CopyFolder( CBHdl AS DWORD, sFileInPath AS STRING,sFileName AS STRING,sNewFolderName AS STRING)
DECLARE SUB UpdateREVOProject(sFileName AS STRING,sNewFolderName AS STRING, AppendText AS STRING)
DECLARE FUNCTION EditShowHide(sFileName AS STRING, lShow AS LONG) AS LONG
'----------------------------------------------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
'   ** Main Application Entry Point **
'----------------------------------------------------------------------------------------------------------------------
FUNCTION PBMAIN()
    PBFormsInitComCtls (%ICC_WIN95_CLASSES OR %ICC_DATE_CLASSES OR %ICC_INTERNET_CLASSES)

'    LoadSettings(GetINIFileName)        'Load INI defaults or last settings

    ShowDIALOG1 %HWND_DESKTOP
END FUNCTION
'----------------------------------------------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
'   ** CallBacks **
'----------------------------------------------------------------------------------------------------------------------
CALLBACK FUNCTION ShowDIALOG1Proc()

LOCAL sFileName AS STRING
LOCAL sFileInPath AS STRING
LOCAL AppendText AS STRING
LOCAL SrchText AS STRING
LOCAL SeparateText AS STRING
LOCAL RepText AS STRING
DIM x  AS INTEGER
LOCAL LBHndl AS DWORD
LOCAL result AS LONG
LOCAL nFile AS LONG
LOCAL TmpAsciiz AS ASCIIZ*%Max_Path
LOCAL iFile AS LONG
LOCAL lAppendInstead AS LONG
LOCAL lAppendPrepend AS LONG
LOCAL sNewFolderName AS STRING
LOCAL lTotalItems AS LONG

    SELECT CASE AS LONG CBMSG
        CASE %WM_INITDIALOG
            ' Initialization handler
'            DragAcceptFiles CBHNDL,%TRUE              'we are currently not going to accept drag and drop
            DragAcceptFiles CBHNDL,%FALSE

        CASE %WM_DESTROY
            ' Quiting handler
            DragAcceptFiles CBHNDL,%FALSE

        CASE %WM_NCACTIVATE
            STATIC hWndSaveFocus AS DWORD
            IF ISFALSE CBWPARAM THEN
                ' Save control focus
                hWndSaveFocus = GetFocus()
            ELSEIF hWndSaveFocus THEN
                ' Restore control focus
                SetFocus(hWndSaveFocus)
                hWndSaveFocus = 0
            END IF

        CASE %WM_DROPFILES
            DragQueryFile (CBWPARAM,0,TmpAsciiz,SIZEOF(TmpAsciiz))
            DragFinish CBWPARAM
            IF LEFT$(RIGHT$(TmpAsciiz,4),1)="." THEN
                Directory=TmpAsciiz
            ELSE
                Directory=TmpAsciiz+"\"
            END IF

            CONTROL DISABLE hDlg,%IDC_TEXTBOX1
            CONTROL SET TEXT hDlg,%IDC_TEXTBOX1,Directory
            CONTROL HANDLE hDlg,  %IDC_LISTBOX1 TO LBHndl
            LISTBOX RESET hDlg, %IDC_LISTBOX1
            LoadList (directory)                                'Get all the files in the directory
            CONTROL ENABLE hDlg,%IDC_TEXTBOX1

        CASE %WM_COMMAND
            ' Process control notifications
            SELECT CASE AS LONG CBCTL
                CASE %IDC_BUTTON1
                    IF CBCTLMSG = %BN_CLICKED OR CBCTLMSG = 1 THEN
' we need to load the .REVO File and load contents of that file into the TEXTBOX2
                        sFileName = OpenREVOFile()                           'Open a file via the Common Controls in Win32
'                        settings.sFile=sFileName
                        IF sFileName="" THEN
                            EXIT SELECT
                        END IF
                        AppendText=LoadText(sFileName)
                        CONTROL SET TEXT hDlg,%IDC_TEXTBOX2,AppendText
                        CONTROL SET TEXT hDlg,%IDC_TEXTBOX1,sFileName

' then we need to extract the path ./data/ to load the SCAN PROJECT file folders
                        sFileInPath=LEFT$(sFileName,INSTR(-1,sFileName,"\"))         'Extracts just the Path
                        sFileInPath=sFileInPath+"data\"
                        Directory=sFileInPath
'                        msgbox sFileInPath
                        CONTROL HANDLE hDlg,  %IDC_LISTBOX1 TO LBHndl
'                        DeleteList (LBHndl)                                 'Clear out and reload ListBox contents
                        LISTBOX RESET hDlg, %IDC_LISTBOX1
                        IF Directory>"" THEN
                            LoadList (directory)                            'Get all the folders in the directory
                        END IF
                    END IF

'                CASE %IDC_TEXTBOX1
'                    IF CBCTLMSG=%EN_CHANGE THEN
'                    END IF


                CASE %IDC_BUTTON4
'Duplicate Folder (SCAN DATA)
                    IF CBCTLMSG = %BN_CLICKED OR CBCTLMSG = 1 THEN
' Ask for new name of folder

                        CONTROL GET TEXT hDlg,%IDC_TEXTBOX1 TO sFileName

' then we need to extract the path ./data/ to load the SCAN PROJECT file folders
                        sFileInPath=LEFT$(sFileName,INSTR(-1,sFileName,"\"))         'Extracts just the Path
                        sFileInPath=sFileInPath+"data\"

                        CONTROL HANDLE hDlg,  %IDC_LISTBOX1 TO LBHndl
                        CopyFolder( LBHndl, sFileInPath ,sFileName,sNewFolderName)

' Update the REVO project folder
' Save updated REVO project folder
                        CONTROL GET TEXT hDlg,%IDC_TEXTBOX2 TO AppendText
                        UpdateREVOProject(sFileName,sNewFolderName, AppendText)
' Force reload of project to reflect the new changes
                       AppendText=LoadText(sFileName)
                        CONTROL SET TEXT hDlg,%IDC_TEXTBOX2,AppendText
                        CONTROL SET TEXT hDlg,%IDC_TEXTBOX1,sFileName

' then we need to extract the path ./data/ to load the SCAN PROJECT file folders
                        sFileInPath=LEFT$(sFileName,INSTR(-1,sFileName,"\"))         'Extracts just the Path
                        sFileInPath=sFileInPath+"data\"
                        Directory=sFileInPath
'                        msgbox sFileInPath
                        CONTROL HANDLE hDlg,  %IDC_LISTBOX1 TO LBHndl
'                        DeleteList (LBHndl)                                 'Clear out and reload ListBox contents
                        LISTBOX RESET hDlg, %IDC_LISTBOX1
                        IF Directory>"" THEN
                            LoadList (directory)                            'Get all the folders in the directory
                        END IF


                    END IF

                CASE %IDC_BUTTON5
                    IF CBCTLMSG = %BN_CLICKED OR CBCTLMSG = 1 THEN
' Save REVO Project File
'
                        CONTROL GET TEXT hDlg,%IDC_TEXTBOX1 TO sFileName
                        CONTROL GET TEXT hDlg,%IDC_TEXTBOX2 TO AppendText

'Write Updated REVO to disk
                        result=SaveTextFile( sFileName, AppendText)
                        IF result >0 THEN
                            MSGBOX "Error Saving Project File",%MB_ICONERROR, STR$(ERR)
                        END IF

                    END IF


                CASE %IDC_BUTTON6
                    IF CBCTLMSG = %BN_CLICKED OR CBCTLMSG = 1 THEN
' Get highlighted Folder to view frames
' Load second listbox with .inf file in "frame" order
                        LISTBOX GET SELECT hDlg, %IDC_LISTBOX1 TO result
                        IF result=0 THEN
                            EXIT SELECT
                        END IF

                        LISTBOX GET TEXT hDlg, %IDC_LISTBOX1 TO AppendText
                        CONTROL GET TEXT hDlg,%IDC_TEXTBOX1 TO sFileName

' then we need to extract the path ./data/ to load the SCAN PROJECT file folders
                        sFileInPath=LEFT$(sFileName,INSTR(-1,sFileName,"\"))         'Extracts just the Path
                        sFileInPath=sFileInPath+"data\"+AppendText+"\cache\"
                        Directory=sFileInPath

 '                       CONTROL HANDLE hDlg,  %IDC_LISTBOX2 TO LBHndl
                        LISTBOX RESET hDlg, %IDC_LISTBOX2
                        IF Directory>"" THEN
                            LoadINFList (directory)                            'Get all the folders in the directory
                        END IF

                    END IF

                CASE %IDC_BUTTON2
                    IF CBCTLMSG = %BN_CLICKED OR CBCTLMSG = 1 THEN
' Hide Frames
' TRaverse list looking for select files
                        LISTBOX GET COUNT hDlg,  %IDC_LISTBOX2 TO lTotalItems
                        FOR x=1 TO lTotalItems
                            LISTBOX GET STATE hDlg, %IDC_LISTBOX2, x TO result
                            IF result<>0  THEN
                                LISTBOX GET TEXT hDlg,%IDC_LISTBOX2, x TO AppendText
                                sFileInPath=Directory+AppendText
'                                msgbox sFileInPath
' open file and toggle hide/show byte
                                result=EditShowHide(sFileInPath, 0)
                            END IF
                        NEXT lItem

' close file
' deselect list when done
                        CONTROL SEND hDlg, %IDC_BUTTON6, %BM_CLICK, 0, 0

                    END IF

                CASE %IDC_BUTTON3
                    IF CBCTLMSG = %BN_CLICKED OR CBCTLMSG = 1 THEN
' Show Frames
' TRaverse list looking for select files
                        LISTBOX GET COUNT hDlg,  %IDC_LISTBOX2 TO lTotalItems
                        FOR x=1 TO lTotalItems
                            LISTBOX GET STATE hDlg, %IDC_LISTBOX2, x TO result
                            IF result<>0  THEN
                                LISTBOX GET TEXT hDlg,%IDC_LISTBOX2, x TO AppendText
                                sFileInPath=Directory+AppendText
'                                msgbox sFileInPath
' open file and toggle hide/show byte
                                result=EditShowHide(sFileInPath, 1)
                            END IF
                        NEXT lItem

' close file
' deselect list when done
                        CONTROL SEND hDlg, %IDC_BUTTON6, %BM_CLICK, 0, 0
                    END IF
'                CASE %IDC_LISTBOX1


            END SELECT
    END SELECT
END FUNCTION
'----------------------------------------------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
'   ** Sample Code **
'----------------------------------------------------------------------------------------------------------------------
FUNCTION SampleListBox(BYVAL hDlg AS DWORD, BYVAL lID AS LONG, BYVAL lCount AS LONG) AS LONG
    LOCAL i AS LONG

    FOR i = 1 TO lCount
        LISTBOX ADD hDlg, lID, USING$("Test Item #", i)
    NEXT i
END FUNCTION
'----------------------------------------------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
'   ** Dialogs **
'----------------------------------------------------------------------------------------------------------------------
FUNCTION ShowDIALOG1(BYVAL hParent AS DWORD) AS LONG
    LOCAL lRslt AS LONG

#PBFORMS BEGIN DIALOG %IDD_DIALOG1->->

    DIALOG NEW hParent, "REVO PROJECT MOD", 14, 23, 712, 412, %WS_POPUP OR %WS_BORDER OR %WS_DLGFRAME OR %WS_SYSMENU _
        OR %WS_CLIPSIBLINGS OR %WS_VISIBLE OR %DS_MODALFRAME OR %DS_3DLOOK OR %DS_NOFAILCREATE OR %DS_SETFONT, _
        %WS_EX_CONTROLPARENT OR %WS_EX_LEFT OR %WS_EX_LTRREADING OR %WS_EX_RIGHTSCROLLBAR, TO hDlg
    CONTROL ADD BUTTON,  hDlg, %IDC_BUTTON4, "DUPLICATE FOLDER", 5, 370, 100, 25
    CONTROL ADD TEXTBOX, hDlg, %IDC_TEXTBOX2, "", 215, 65, 240, 300, %WS_CHILD OR %WS_VISIBLE OR %WS_TABSTOP OR _
        %WS_HSCROLL OR %WS_VSCROLL OR %ES_LEFT OR %ES_MULTILINE OR %ES_AUTOHSCROLL OR %ES_AUTOVSCROLL, _
        %WS_EX_CLIENTEDGE OR %WS_EX_LEFT OR %WS_EX_LTRREADING OR %WS_EX_RIGHTSCROLLBAR
    CONTROL ADD BUTTON,  hDlg, %IDC_BUTTON2, "HIDE FRAME", 465, 370, 100, 25
    CONTROL ADD BUTTON,  hDlg, %IDC_BUTTON3, "SHOW FRAME", 585, 370, 100, 25
    CONTROL ADD BUTTON,  hDlg, %IDC_BUTTON1, "OPEN REVO PROJECT", 5, 15, 100, 25
    CONTROL ADD BUTTON,  hDlg, %IDC_BUTTON5, "SAVE REVO PROJECT", 285, 370, 100, 25
    CONTROL ADD LISTBOX, hDlg, %IDC_LISTBOX1, , 5, 65, 210, 300, %WS_CHILD OR %WS_VISIBLE OR %WS_BORDER OR _
        %WS_TABSTOP OR %WS_VSCROLL OR %LBS_SORT OR %LBS_NOTIFY, %WS_EX_CLIENTEDGE OR %WS_EX_LEFT OR _
        %WS_EX_LTRREADING OR %WS_EX_RIGHTSCROLLBAR
    CONTROL ADD LISTBOX, hDlg, %IDC_LISTBOX2, , 460, 65, 230, 300, %WS_CHILD OR %WS_VISIBLE OR %WS_BORDER OR _
        %WS_TABSTOP OR %WS_VSCROLL OR %LBS_MULTIPLESEL OR %LBS_SORT OR %LBS_NOTIFY OR %LBS_EXTENDEDSEL, _
        %WS_EX_CLIENTEDGE OR %WS_EX_LEFT OR %WS_EX_LTRREADING OR %WS_EX_RIGHTSCROLLBAR
    CONTROL ADD TEXTBOX, hDlg, %IDC_TEXTBOX1, "", 110, 25, 570, 20, %WS_CHILD OR %WS_VISIBLE OR %WS_TABSTOP OR _
        %ES_LEFT, %WS_EX_CLIENTEDGE OR %WS_EX_LEFT OR %WS_EX_LTRREADING OR %WS_EX_RIGHTSCROLLBAR
    CONTROL ADD LABEL,   hDlg, %IDC_LABEL1, "SCANS IN PROJECT", 5, 50, 210, 10
    CONTROL ADD LABEL,   hDlg, %IDC_LABEL2, "REVO PROJECT", 225, 50, 210, 10
    CONTROL ADD BUTTON,  hDlg, %IDC_BUTTON6, "SELECT FOLDER", 110, 370, 100, 25
    CONTROL ADD LABEL,   hDlg, %IDC_LABEL3, "SCAN FRAMES", 460, 50, 210, 10
    CONTROL ADD LABEL,   hDlg, %IDC_LABEL4, $VERSION, 345, 5, 335, 15
#PBFORMS END DIALOG

'    SampleListBox  hDlg, %IDC_LISTBOX1, 30

    DIALOG SHOW MODAL hDlg, CALL ShowDIALOG1Proc TO lRslt

#PBFORMS BEGIN CLEANUP %IDD_DIALOG1
#PBFORMS END CLEANUP

    FUNCTION = lRslt
END FUNCTION
'----------------------------------------------------------------------------------------------------------------------

'------------------------------------------------------------------------------



FUNCTION GetDirectory() AS STRING

LOCAL   Success AS LONG,_
        InName AS STRING

    InName=GetFolder(%HWND_DESKTOP, "Select a Folder", CURDIR$)

'    InName = UCASE$(InName)       'Convert to upper case
    InName = REMOVE$(InName, ANY $DQ)

    IF MID$(InName,-1)<>"\" THEN
        InName=InName+"\"
    END IF

    FUNCTION=InName
END FUNCTION

'------------------------------------------------------------------------------

'------------------------------------------------------------------------------
SUB LoadList (DirPath AS STRING)

LOCAL FileCount AS LONG
LOCAL sFile AS STRING


        FileCount=0
'        sFile=DIR$(DirPath+"*.*")                  'Get the first file in the path
        sFile=DIR$(DirPath,16)                      'Just list Folders (16 = %SUBDIR )
        WHILE LEN(sFile) AND FileCount < %FILEMAX ' max = 10000
            INCR FileCount
            LISTBOX ADD hDlg,%IDC_LISTBOX1, sFile
            sFile = DIR$
        WEND

END SUB

'------------------------------------------------------------------------------

'------------------------------------------------------------------------------
SUB LoadINFList (DirPath AS STRING)

LOCAL FileCount AS LONG
LOCAL sFile AS STRING


        FileCount=0
        sFile=DIR$(DirPath+"*.INF")                  'Get the first file in the path
'        sFile=DIR$(DirPath,16)                      'Just list Folders (16 = %SUBDIR )
        WHILE LEN(sFile) AND FileCount < 10000 ' max = 10000
            INCR FileCount
            LISTBOX ADD hDlg,%IDC_LISTBOX2, sFile
            sFile = DIR$
        WEND

END SUB

'------------------------------------------------------------------------------

'--------------------------------------------------------------------------------
'   Open REVO file (open dialog)
'--------------------------------------------------------------------------------
FUNCTION OpenREVOFile() AS STRING

LOCAL   Success AS LONG,_
        sName AS STRING

    '       *** Get input file name ***
        Success=OpenFileDialog(%HWND_DESKTOP,_
            "Open File",_
            sName,_
            CURDIR$,_
            "REVO Project File|*.REVO|All Files|*.*",_
            "REVO",_
            %OFN_FILEMUSTEXIST OR %OFN_HIDEREADONLY OR %OFN_LONGNAMES)

    sName = UCASE$(sName)       'Convert to upper case
    sName = REMOVE$(sName, ANY $DQ)
'    Settings.FileInPath=LEFT$(sName,INSTR(-1,sName,"\"))         'Extracts just the Path
    FUNCTION=sName
END FUNCTION
'--------------------------------------------------------------------------------

'--------------------------------------------------------------------------------
'   Load Text file in one large chunck
'--------------------------------------------------------------------------------
FUNCTION LoadText(sFileName AS STRING) AS STRING
'sFileName      --  text file name passed in to load data
'RETURN         --  Is the unprocessed data chunk loaded in from disk via binary method

    DIM iFile AS LONG
    DIM sTextFile AS STRING

    ERRCLEAR
    iFile=FREEFILE
    OPEN sFileName FOR BINARY AS #iFile    'Open the file as a binary for one large read
    IF ERR >0 THEN
        MSGBOX "Unable to Open File",%MB_ICONERROR, STR$(ERR)
        EXIT FUNCTION
    END IF
    SEEK #iFile,1                          'Set the file position to start of file
    GET$ #iFile, LOF(#iFile), sTextFile    'Load the file into memory in one go
    IF ERR >0 THEN
        MSGBOX "Unable to Read File",%MB_ICONERROR, STR$(ERR)
        EXIT FUNCTION
    END IF
    CLOSE #iFile                           'Close up file and free handle
'    sTextFile=REMOVE$(sTextFile, ANY $LF)

    FUNCTION=sTextFile
END FUNCTION
'--------------------------------------------------------------------------------

'--------------------------------------------------------------------------------
'   Save text file in one go
'--------------------------------------------------------------------------------
FUNCTION SaveTextFile(sFileName AS STRING, NewFile AS STRING) AS LONG
'sFileName      --  Text file name passed in to save data
'NewFile        --  Is the PROCESSED string containing all the modified data
'RETURN         --  is empty
'--------------------------------------------------------------------------------
    DIM iFile AS LONG
    DIM sTextFile AS STRING
    DIM lLength AS LONG
    DIM lLoop AS LONG

    ERRCLEAR
    iFile=FREEFILE                     'Get a free file handle
    OPEN sFileName FOR BINARY AS iFile    'Open the file as a binary for one large read
    SEEK #iFile,1                      'Set the file write position to start of file
    PUT$ #iFile,NewFile               'Write the file
    SETEOF #iFile                      'Put the EOF at the end of our data--prevent runon data from used used
    CLOSE iFile                        'Close up file and free handle
    FUNCTION = ERR
END FUNCTION

'------------------------------------------------------------------------------
'   CopyFolder       (Callback Handle,
'                       sFileInPath - Path of Folder
'                       sFileName   - Path and Name of REVO file
'                       sNewFolderName - name of new folder
'
' more info to come
'
'------------------------------------------------------------------------------
SUB CopyFolder( CBHdl AS DWORD, sFileInPath AS STRING,sFileName AS STRING,sNewFolderName AS STRING)

LOCAL LastI AS LONG
LOCAL ItemNum AS LONG
LOCAL IsSelct AS LONG
LOCAL ttlLen AS LONG
LOCAL ATtlLen AS LONG
LOCAL sText AS STRING
LOCAL COUNT AS LONG
LOCAL NumText AS STRING
LOCAL formatText AS STRING
LOCAL result AS LONG
LOCAL TempText AS STRING
LOCAL EndText AS STRING
LOCAL StartText AS STRING
LOCAL TextLen AS LONG
LOCAL sOldFolderName AS STRING


    LastI=SendMessage(CBHDL, %LB_GETCOUNT,0,0)                                  ' get count of items in ListBox
    IF lastI=0 THEN                                                             'exit sub if no folder is highlighted
        EXIT SUB
    END IF

    IF LastI>0 THEN                                                             ' If Count >0 then step through list
        DECR LastI                                                              'Adjust count for zero start
        FOR ItemNum=0 TO LastI                                                  ' start at index zero
            IF SendMessage(CBHDL, %LB_GETSEL, ItemNum, 0)<>0 THEN
                INCR COUNT
            END IF
        NEXT ItemNum
    END IF

'get the highlighted folder name
    LastI=SendMessage(CBHDL, %LB_GETCOUNT,0,0)                                  ' get count of items in ListBox
    IF LastI>0 THEN                                                             ' If Count >0 then step through list
        DECR LastI                                                              'Adjust count for zero start
        FOR ItemNum=0 TO LastI                                                  ' start at index zero
            IsSelct=SendMessage(CBHDL, %LB_GETSEL, ItemNum, 0)                  'Is the item selected?
            IF IsSelct<>0 THEN                                                  'Yes?
                ttlLen=SendMessage(CBHDL, %LB_GETTEXTLEN, ItemNum, 0)           'Get the Total Length of text of item selected (in Chars)
                sText=SPACE$(ttlLen+1)                                          'Reserve space in array
                ATtlLen=SendMessage(CBHDL, %LB_GETTEXT, ItemNum, STRPTR(sText)) 'Now, get the actual text string
                sText=LEFT$(sText,ATtlLen)                                      'Trim any excess chars away

            END IF
        NEXT ItemNum
    END IF

'Get name of new folder for scan data

    TempText = INPUTBOX$("Name for NEW SCAN data","Enter a Folder Name", sText+"(1)")
    IF TempText="" THEN                                                   'exit if they enter blank data
        EXIT SUB
    END IF

'get the highlighted folder name
'make new folder names
   sOldFolderName=sFileInPath+"\"+sText
   sNewFolderName=sFileInPath+TempText

'Copy the folder using command line XCOPY

'temp disable to save space/time
   SHELL ENVIRON$("COMSPEC") + " /C XCOPY.EXE /E "+sOldFolderName+"\*.* "+sNewFolderName+"\"

'msgbox "XCOPY /E "+sOldFolderName+"\*.* "+sNewFolderName+"\"

END SUB

'------------------------------------------------------------------------------

'------------------------------------------------------------------------------
' UpdateREVOProject
'   sFileName as STRING     - Name of REVO Project File including PATH data
'   sNewFolderName as STRING - Name of New Scan DATA Folder to include in Project File
'   AppendText as STRING    - Text of REVO File.  We are loading in from TEXTBOX, incase user manually edited the file
'
' we want to automagically update the REVO project file to include the new
' folder/scan data and then write the updated project file to disk
'------------------------------------------------------------------------------
SUB UpdateREVOProject(sFileName AS STRING,sNewFolderName AS STRING, AppendText AS STRING)
LOCAL sBackText AS STRING           'text before the addition
LOCAL sFrontText AS STRING          'Text AFTER the insertion
LOCAL sMiddleText AS STRING         'Our updated text
LOCAL sNewScanName AS STRING
LOCAL lInsert AS LONG
LOCAL result AS LONG


'Extract Folder Name only from sNewFolderName string, which contains path data as well


'    sNewScanName=left$(sNewFolderName,INSTR(-1,sNewFolderName,"\"))               'Extracts just the Path
    sNewScanName= REMAIN$(INSTR(-1,sNewFolderName,"\"),sNewFolderName,"\")         'Extract JUST the name

'Search REVO data for text "nodes" and insert our new folder name
'    "nodes": [
'        {
'            "childs": [],
'            "guid": "[NEWFOLDERNAME]",
'            "name": "[NEWFOLDERNAME]",
'            "type": 2
'        },

    lInsert = INSTR(AppendText, "[")
    sBackText=LEFT$(AppendText, lInsert)
    sFrontText= MID$(AppendText, lInsert+1)

    sMiddleText=  $CRLF+    "        {"+$CRLF
    sMiddleText=sMiddleText+"            "+$DQ+"childs"+$DQ+": [],"+$CRLF
    sMiddleText=sMiddleText+"            "+$DQ+"guid"+$DQ+": "+$DQ+sNewScanName+$DQ+"," +$CRLF
    sMiddleText=sMiddleText+"            "+$DQ+"name"+$DQ+": "+$DQ+sNewScanName+$DQ+"," +$CRLF
    sMiddleText=sMiddleText+"            "+$DQ+"type"+$DQ+": 2" +$CRLF
    sMiddleText=sMiddleText+"        },"


'Write Updated REVO to disk
    AppendText=sBackText+sMiddleText+sFrontText
    result=SaveTextFile( sFileName, AppendText)
    IF result >0 THEN
        MSGBOX "Error Saving Project File",%MB_ICONERROR, STR$(ERR)
    END IF

END SUB


'--------------------------------------------------------------------------------
'   Binary Edit SHOW/HIDE of INF file
'--------------------------------------------------------------------------------
FUNCTION EditShowHide(sFileName AS STRING, lShow AS LONG) AS LONG
'sFileName      --  text file name passed in to load data
'lShow          --  State of Show or hide 0=HIDE, >0 SHOW
'RETURN         --  Returns ERR state

    DIM iFile AS LONG
    DIM sTextFile AS STRING
    DIM lLength AS LONG
    DIM lLoop AS LONG

    ERRCLEAR
    iFile=FREEFILE
    OPEN sFileName FOR BINARY AS #iFile    'Open the file as a binary for one large read
    IF ERR >0 THEN
        MSGBOX "Unable to Open File",%MB_ICONERROR, STR$(ERR)
        EXIT FUNCTION
    END IF
    SEEK #iFile,6                          'Set the file position to start of file
'    GET$ #iFile, LOF(#iFile), sTextFile    'Load the file into memory in one go
    IF lShow<>0 THEN
        PUT$ #iFile,CHR$(02)+CHR$(00)   'Show
    ELSE
        PUT$ #iFile,CHR$(03)+CHR$(01)   'Hide
    END IF
                       'Write the file
    IF ERR >0 THEN
        MSGBOX "Unable to write File",%MB_ICONERROR, STR$(ERR)
        EXIT FUNCTION
    END IF

    CLOSE iFile                        'Close up file and free handle
    FUNCTION = ERR
END FUNCTION

'------------------------------------------------------------------------------
