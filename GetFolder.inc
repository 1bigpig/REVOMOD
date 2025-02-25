'------------------------------------------------------------------------------
'   Browse for Folder dialog
'------------------------------------------------------------------------------
'The Call:
'
'zText = GetFolder(hWndMain, "Browse for Folder", zText)
'
'(edit notation, the call is ALWAYS made with a valid path in my application)
'(and zText is Static zText As Asciiz * 255)


DECLARE FUNCTION GetFolder(BYVAL hParent AS LONG, BYVAL sTitle AS STRING, BYVAL sPath AS STRING) AS STRING
DECLARE FUNCTION BrowseCallbackProc (BYVAL hWnd AS LONG, BYVAL uMsg AS LONG, BYVAL lParam AS LONG, BYVAL lpData AS LONG) AS LONG


FUNCTION GetFolder(BYVAL hParent AS LONG, BYVAL sTitle AS STRING, BYVAL sPath AS STRING) AS STRING
    LOCAL iPathID   AS LONG
    LOCAL BI        AS BROWSEINFO
    LOCAL zPath     AS ASCIIZ * %MAX_PATH
    LOCAL zTitle    AS ASCIIZ * %MAX_PATH
    zTitle          = sTitle
    BI.hWndOwner    = hParent                        'set some properties for the folder dialog
                        'http://msdn.microsoft.com/library/default.asp?url=/library/en-us/shellcc/platform/shell/reference/structures/browseinfo.asp
    BI.ulFlags      = %BIF_DONTGOBELOWDOMAIN OR _    'Do not include network folders below the domain level in the dialog box's tree view control
                      %BIF_STATUSTEXT OR _
                      %BIF_NEWDIALOGSTYLE OR _
                      %BIF_EDITBOX OR _
                      %BIF_RETURNONLYFSDIRS

    BI.lpszTitle    = VARPTR(zTitle)                 'set our title
    BI.lpfnCallback = CODEPTR(BrowseCallbackProc)
    BI.lParam       = STRPTR(sPath)
    iPathID         = SHBrowseForFolder(BI)          'show the Browse-For-Folder dialog
    IF iPathID THEN
        IF SHGetPathFromIDList(BYVAL iPathID, zPath) THEN
            FUNCTION = RTRIM$(zPath, ANY CHR$(0,32))  'return our results
        END IF
        CALL CoTaskMemFree(iPathID)                  'free allocated memory
    END IF
END FUNCTION

FUNCTION BrowseCallbackProc (BYVAL hWnd AS LONG, BYVAL uMsg AS LONG, _
                  BYVAL lParam AS LONG, BYVAL lpData AS LONG) EXPORT AS LONG
    STATIC szStartFolder    AS ASCIIZ * %MAX_PATH
    LOCAL  szPointer        AS ASCIIZ POINTER
    LOCAL szDummy           AS ASCIIZ * %MAX_PATH
    SELECT CASE uMsg
        CASE %BFFM_INITIALIZED
            SendMessage hWnd, %BFFM_SETSELECTION, %TRUE, BYREF szStartFolder
        CASE %BFFM_SELCHANGED
            szPointer = lpData
            szStartFolder = @szPointer
            SHGetPathFromIDList(BYVAL lParam, szDummy)
            SendMessage hWnd, %BFFM_SETSTATUSTEXT, 0, BYREF szDummy
    END SELECT
    FUNCTION = 0
END FUNCTION
