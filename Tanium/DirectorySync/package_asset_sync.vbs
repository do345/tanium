'========================================
' NAVER Asset Sync Service
' Asset Information Update (Package)
' Modified 2018/10/18 
'========================================
'@INCLUDE=i18n/UTF8Decode.vbs
'@INCLUDE=utils/x64Fix.vbs

Option Explicit

x64Fix

'/// Mac Address Query 
Dim strQuery, objWMIService, colItems, objItem
Dim i,j
Dim ihttpget
Dim macaddress
Dim DataFlag , ConnectionFlag

Dim AssetStream, tmpAssetInfo, tmpItem
Dim AssetItem(13) 

AssetItem(0) = "ASSET_ID"
AssetItem(1) = "COMP_SHORT_NM"
AssetItem(2) = "ORG_NM"
AssetItem(3) = "EMPNO"
AssetItem(4) = "EMPNM"
AssetItem(5) = "ASSET_STATUS_NM"
AssetItem(6) = "MANAGEMENT_TYPE_NM"
AssetItem(7) = "MAC_1"
AssetItem(8) = "MAC_2"
AssetItem(9) = "MAC_3"
AssetItem(10) = "MAC_4"
AssetItem(11) = "MAC_5"

'//20180717////////////
AssetItem(12) = "SYNC_DATETIME"


DataFlag = 0
ConnectionFlag = 0

On Error Resume Next

'/// Registry 
Const HKLM = &h80000002
Dim objReg, targetArch, targetKey, targetValueName, targetValue, targetValueType, words, strHive, constHive, targetDefaultKey
Set objReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")


WScript.Echo "This script is to syncronize Asset DB information with the endpoint(PC) through Tanium"
WScript.Echo "Synchronization Request Started"
WScript.Echo "[01] Getting current endpoint's MAC Address..."


' Display MAC Address
strQuery = "SELECT * FROM Win32_NetworkAdapterConfiguration WHERE MACAddress > '' AND (NOT MACAddress = '41:56:45:00:00:30' ) AND (NOT MACAddress = '02:05:85:7F:EB:80' ) AND (NOT MACAddress = '20:41:53:59:4E:FF' ) AND (NOT MACAddress = '46:35:00:00:00:31' ) AND (NOT MACAddress = '00:50:56:C0:00:01' ) AND (NOT MACAddress = '00:50:56:C0:00:08' ) AND (NOT MACAddress = '0A:00:27:00:00:00' ) AND (NOT MACAddress = '02:00:4C:4F:4F:50') AND (NOT MACAddress = '02:05:85:7F:EB:81') AND (NOT Description LIKE '%VMware%') AND (NOT Description LIKE '%VPN%') AND (NOT Description LIKE '%Juniper Network Agent Miniport%') AND (NOT Description LIKE '%Bluetooth%') AND (NOT Description LIKE '%Virtual%') AND (NOT Description LIKE '%VMNet%') " 


Set objWMIService = GetObject( "winmgmts://./root/CIMV2" )
Set colItems      = objWMIService.ExecQuery( strQuery, "WQL", 48 )


If Err.Number <> 0 Then
    WScript.Echo "[01-Error] Error on Getting Mac Address! ErrorNo : " & Err.Number & " - " & Err.Description
    Err.Number = 0


Else 

    For Each objItem in colItems
        If Not IsNull(objItem.MACAddress) Then

            WScript.Echo "[01-Result] MAC Address : " & objItem.MACAddress
            macaddress=Replace(objItem.MACAddress,":","-")
            
            WScript.Echo "[02] Translated MAC Address is " & macaddress 
           
            WScript.Echo "[03] Requesting User Information to Asset DB... " & "https://tem.navercorp.com:8000/api-auth/endpoint/" & macaddress

            Set ihttpget = CreateObject("MSXML2.ServerXMLHTTP.6.0")
            ihttpget.setOption 2, 13056
            ihttpget.open "GET", "https://tem.navercorp.com:8000/api-auth/endpoint/" & macaddress , False
'            ihttpget.open "GET", "https://10.105.83.143:8000/api-auth/endpoint/" & macaddress , False
            ihttpget.send

            If Err.Number <> 0 Then
                WScript.Echo "[03-Error] Error on HTTPS Connection! ErrorNo : " & Err.Number & " - " & Err.Description
                Err.Number = 0
                Exit For

            Else 

                WScript.Echo "[03-Result] Return Code : " &  ihttpget.Status 

                If ihttpget.Status = 200 Then
                    ConnectionFlag = 1

                    WScript.Echo "[03-Result] Received User Information: " & ihttpget.responseText
                    AssetStream = ihttpget.responseText

                    If Len(AssetStream) > 10 Then

                        WScript.Echo "[04] Saving User Inormation on Registry " 
                        tmpAssetInfo = Split(AssetStream,",")
          
                        j = 0
                        
                        For each tmpItem in tmpAssetInfo

                            WScript.Echo "[04-" & j & "]" & AssetItem(j) &  " = " & tmpItem 
                            targetArch = LCase("both")
                            targetKey = UTF8Decode("HKEY_LOCAL_MACHINE\Software\Tanium\Tanium Client\NAVER")
                        
                            'Split up strKey into the hive constant and the registry key
                            words = Split(targetKey, "\")
                            strHive = words(0)
                            constHive = GetHiveConst(strHive)
                            
                            targetDefaultKey = Right(targetKey, Len(targetKey) - Len(strHive) -1)

                            targetValueName = UTF8Decode(AssetItem(j))
                            targetValue = tmpItem
                            targetValueType = UTF8Decode("REG_SZ")


                            SetValue64or32orBoth objReg, targetArch, "", targetDefaultKey, targetValueName, targetValue, targetValueType, strHive, constHive

                            j=j+1
                        Next 


                        If Err.Number <> 0 Then
                            WScript.Echo "[04-Error] Error While Saving on Registry ! ErrorNo : " & Err.Number & " - " & Err.Description
                            Err.Number = 0
                            Exit For
                        End If


                        DataFlag = 1

                        Exit For
                        
                    End If
                

                Else
                    WScript.Echo "[03-Failure] Failure on HTTPS Connection! : Return Code is " &  ihttpget.Status

                End If


            End If

            
        End If

        ihttpget = nothing

    Next

End If




if DataFlag = 0 and ConnectionFlag = 1 Then
    WScript.Echo "[Result Summary] User Information Missing on DB  "


    For each tmpItem in AssetItem

        'Asset Infomation -> Registry 
        targetArch = LCase("both")
        targetKey = UTF8Decode("HKEY_LOCAL_MACHINE\Software\Tanium\Tanium Client\NAVER")
        targetValueName = UTF8Decode(AssetItem(j))
        targetValue = "No data"
        targetValueType = UTF8Decode("REG_SZ")

        'Split up strKey into the hive constant and the registry key
        words = Split(targetKey, "\")
        strHive = words(0)
        constHive = GetHiveConst(strHive)

        targetDefaultKey = Right(targetKey, Len(targetKey) - Len(strHive) -1)



        SetValue64or32orBoth objReg, targetArch, "", targetDefaultKey, targetValueName, targetValue, targetValueType, strHive, constHive


        j=j+1
    Next 

    setSyncDate


elseif ConnectionFlag = 0 Then
    WScript.Echo "[Result Summary] Connection Failure "


    For each tmpItem in AssetItem

        'Asset Infomation -> Registry 
        targetArch = LCase("both")
        targetKey = UTF8Decode("HKEY_LOCAL_MACHINE\Software\Tanium\Tanium Client\NAVER")
        targetValueName = UTF8Decode(AssetItem(j))
        targetValue = "Connection Failure"
        targetValueType = UTF8Decode("REG_SZ")

        'Split up strKey into the hive constant and the registry key
        words = Split(targetKey, "\")
        strHive = words(0)
        constHive = GetHiveConst(strHive)

        targetDefaultKey = Right(targetKey, Len(targetKey) - Len(strHive) -1)


        If Not RegKeyExists(objReg, constHive, targetDefaultKey) Then 
            WScript.Echo "[Result Summary] Newly Registry Created"
            
            SetValue64or32orBoth objReg, targetArch, "", targetDefaultKey, targetValueName, targetValue, targetValueType, strHive, constHive

        End If

        j=j+1
    Next 

    setSyncDate

elseif DataFlag = 1 and ConnectionFlag = 1 Then

    WScript.Echo "[Result Summary] All Completed "

End if


Function setSyncDate

    Dim sSyncDate, iDateTime

    WScript.Echo "[Additional Task] Sync Data"

    iDateTime = Now()

    sSyncDate = Year(iDateTime ) & Month(iDateTime ) & Day(iDateTime ) & DatePart("h",iDateTime )
    WScript.Echo sSyncDate

    'Asset Infomation -> Registry 
    targetArch = LCase("both")
    targetKey = UTF8Decode("HKEY_LOCAL_MACHINE\Software\Tanium\Tanium Client\NAVER")
    targetValueName = UTF8Decode("SYNC_DATETIME")
    targetValue = sSyncDate
    targetValueType = UTF8Decode("REG_SZ")

    'Split up strKey into the hive constant and the registry key
    words = Split(targetKey, "\")
    strHive = words(0)
    constHive = GetHiveConst(strHive)

    targetDefaultKey = Right(targetKey, Len(targetKey) - Len(strHive) -1)

    SetValue64or32orBoth objReg, targetArch, "", targetDefaultKey, targetValueName, targetValue, targetValueType, strHive, constHive

End Function 'setSyncDate


Function SetValue64or32orBoth(objReg, targetArch, targetPreFix, targetKey, targetValueName, targetValue, targetValueType, strHive, constHive)
    Dim targetWowKey
    targetWowKey = targetKey
    'Catch the 32-bit entries for any 64-bit machines


    If Is64 Then

        If targetArch = "32" Or targetArch = "both" Then
            'WScript.Echo "is64, but setting 32.  need to check for software/ and add wow6432node"
        
            If Left(LCase(targetWowKey), Len("software\")) = "software\" Then
                'need to insert wow6432node
                targetWowKey = "software\wow6432node\" & Right(targetWowKey, Len(targetWowKey) - Len("software\"))
            End If

            If targetWowKey <> targetKey Then
                'Catch Wow6432Node keys on 64-bit machines, if necessary
                SetValue objReg, constHive, targetPreFix & targetWowKey, targetValueName, targetValue, targetValueType, targetArch, strHive
            Else
                ' setting a 64-bit value somewhere which is not under the Software key
                SetValue objReg, constHive, targetPreFix & targetKey, targetValueName, targetValue, targetValueType, targetArch, strHive
            End If
        End If
        
        If targetArch = "64" Or targetArch = "both" Then
            'Catch "64" and "both" for 64-bit machines
            SetValue objReg, constHive, targetPreFix & targetKey, targetValueName, targetValue, targetValueType, targetArch, strHive
        End If
    Else

        'Catch "32" and "both" for 32-bit machines, "64" on 32-bit machines already ruled out with Quit
        SetValue objReg, constHive, targetPreFix & targetKey, targetValueName, targetValue, targetValueType, targetArch, strHive
    End If
End Function ' SetValue64or32orBoth

Function SetValue(objReg, constHive, targetKey, targetValueName, targetValue, targetValueType, targetArch, strHive)
    'WScript.Echo "Setting registry value:"
    'WScript.Echo "  Arch:  " & targetArch
    'WScript.Echo "  Hive:  " & strHive
    'WScript.Echo "  Key:   " & targetKey
    'WScript.Echo "  Name:  " & targetValueName
    'WScript.Echo "  Value: " & targetValue
    'WScript.Echo "  Type:  " & targetValueType
    
    If Not RegKeyExists(objReg, constHive, targetKey) Then 
        CreateKey objReg, constHive, targetKey, targetArch, strHive
    End If
    
    If RegKeyExists(objReg, constHive, targetKey) Then
        'Delete the value first so we can recreate if different type
        objReg.DeleteValue constHive, targetKey, targetValueName
    
        'WScript.Echo targetValue

        Select Case targetValueType
            Case "REG_SZ"
                'WScript.Echo "Data Type: String" & targetValue
                objReg.SetStringValue constHive, targetKey, targetValueName, targetValue
            Case "REG_EXPAND_SZ"
                'WScript.Echo "Data Type: Expanded String" & targetValue
                objReg.SetExpandedStringValue constHive, targetKey, targetValueName, targetValue
            Case "REG_BINARY"
                'WScript.Echo "Data Type: Binary" & targetValue
    
                'Convert string to Dec Array
                Dim arrValues : arrValues = Array()
                For i = 0 To Len(targetValue)-1
                    ReDim Preserve arrValues(UBound(arrValues) + 1)
                    arrValues(i) = Asc(Mid(targetValue,i+1,1))
                Next
                objReg.SetBinaryValue constHive, targetKey, targetValueName, arrValues
            Case "REG_DWORD"
                'WScript.Echo "Data Type: DWORD" & targetValue
                objReg.SetDWordValue constHive, targetKey, targetValueName, targetValue
            Case "REG_QWORD"
                'WScript.Echo "Data Type: QWORD" & targetValue
                objReg.SetQWordValue constHive, targetKey, targetValueName, targetValue
            Case "REG_MULTI_SZ"
                'WScript.Echo "Data Type: Multi String" & targetValue
                ' this is a difference in 6.5 and 7.0.  In earlier versions, new lines were split by 
                ' the ` character.  But in the 7.0 non-flash gui, they can be split by LF
                ' so we have to account for both
                Dim splitString
                If(InStr(targetValue, "`") > 0) Then 
                    splitString = Split(targetValue, "`")
                Else 
                    splitString = Split(targetValue, vbLf)
                End If
                objReg.SetMultiStringValue constHive, targetKey, targetValueName, splitString
            Case Else
                'WScript.Echo "Data type not found: " & targetValueType
        End Select 
    End If
End Function


Function DeleteKey64or32orBoth(objReg, targetArch, targetPreFix, targetKey, strHive, constHive)
	Dim targetWowKey
	targetWowKey = targetKey
	'Catch the 32-bit entries for any 64-bit machines
	If Is64 Then
		If targetArch = "32" Or targetArch = "both" Then
			WScript.Echo "is64, but deleting 32.  need to check for software/ and add wow6432node"
		
			If Left(LCase(targetWowKey), Len("software\")) = "software\" Then
				'need to insert wow6432node
				targetWowKey = "software\wow6432node\" & Right(targetWowKey, Len(targetWowKey) - Len("software\"))
			End If
			
			If targetWowKey <> targetKey Then
				'Catch Wow6432Node keys on 64-bit machines, if necessary
				DeleteKey objReg, constHive, targetPreFix & targetWowKey, targetArch, strHive
			Else
				' Deleting a 64-bit value somewhere which is not under the Software key
				DeleteKey objReg, constHive, targetPreFix & targetKey, targetArch, strHive
			End If
		End If
		
		If targetArch = "64" Or targetArch = "both" Then
			'Catch "64" and "both" for 64-bit machines
			DeleteKey objReg, constHive, targetPreFix & targetKey, targetArch, strHive
		End If
	Else
		'Catch "32" and "both" for 32-bit machines, "64" on 32-bit machines already ruled out with Quit
		DeleteKey objReg, constHive, targetPreFix & targetKey, targetArch, strHive
	End If
End Function ' DeleteKey64or32orBoth


Function GetHiveConst(hive)
    Const HKEY_CLASSES_ROOT   = &H80000000
    Const HKEY_CURRENT_USER   = &H80000001
    Const HKEY_LOCAL_MACHINE  = &H80000002
    Const HKEY_USERS          = &H80000003

    Select Case UCase(hive)
        Case "HKLM"
            GetHiveConst = HKEY_LOCAL_MACHINE
        Case "HKEY_LOCAL_MACHINE"
            GetHiveConst = HKEY_LOCAL_MACHINE
        Case "HKCR"
            GetHiveConst = HKEY_CLASSES_ROOT
        Case "HKEY_CLASSES_ROOT"
            GetHiveConst = HKEY_CLASSES_ROOT
        Case "HKEY_CURRENT_USER"
            GetHiveConst = HKEY_CURRENT_USER
        Case "HKEY_USERS"
            GetHiveConst = HKEY_USERS
    End Select
    
    If IsEmpty(GetHiveConst) Then
        WScript.Echo "Invalid registry hive: " & hive
        WScript.Quit
    End If
End Function

Function Is64 
    Dim objWMIService, colItems, objItem
    Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2")
    Set colItems = objWMIService.ExecQuery("Select SystemType from Win32_ComputerSystem")
    For Each objItem In colItems
        If InStr(LCase(objItem.SystemType), "x64") > 0 Then
            Is64 = True
        Else
            Is64 = False
        End If
    Next
End Function

Function CreateKey(objReg, constHive, targetKey, targetArch, strHive)
    WScript.Echo "Creating registry key:"
    WScript.Echo "  Arch:  " & targetArch
    WScript.Echo "  Hive:  " & strHive
    WScript.Echo "  Key:   " & targetKey

    objReg.CreateKey constHive, targetKey
    
    If RegKeyExists(objReg, constHive, targetKey) Then
        WScript.Echo "Key successfully created or already existed: " & targetKey
    Else
        WScript.Echo "Key failed creation: " & targetKey
    End If
End Function


Function DeleteKey(ojReg, constHive, targetKey, targetArch, strHive)
	WScript.Echo "Deleting registry key:"
	WScript.Echo "  Arch:  " & targetArch
	WScript.Echo "  Hive:  " & strHive
	WScript.Echo "  Key:   " & targetKey

	objReg.DeleteKey constHive, targetKey
	
	If RegKeyExists(objReg, constHive, targetKey) Then
		WScript.Echo "Unable to delete key: " & targetKey
	Else
		WScript.Echo "Key deleted (or didn't exist): " & targetKey
	End If
End Function


Function RegKeyExists(objRegistry, sHive, sRegKey)
    Dim aValueNames, aValueTypes
    If objRegistry.EnumValues(sHive, sRegKey, aValueNames, aValueTypes) = 0 Then
        RegKeyExists = True
    Else
        RegKeyExists = False
    End If
End Function

'------------ INCLUDES after this line. Do not edit past this point -----
'- Begin file: i18n/UTF8Decode.vbs
'========================================
' UTF8Decode
'========================================
' Used to convert the UTF-8 style parameters passed from 
' the server to sensors in sensor parameters.
' This function should be used to safely pass non english input to sensors.

' To include this file, copy/paste: INCLUDE=i18n/UTF8Decode.vbs


Function UTF8Decode(str)
    Dim arraylist(), strLen, i, sT, val, depth, sR
    Dim arraysize
    arraysize = 0
    strLen = Len(str)
    for i = 1 to strLen
        sT = mid(str, i, 1)
        if sT = "%" then
            if i + 2 <= strLen then
                Redim Preserve arraylist(arraysize + 1)
                arraylist(arraysize) = cbyte("&H" & mid(str, i + 1, 2))
                arraysize = arraysize + 1
                i = i + 2
            end if
        else
            Redim Preserve arraylist(arraysize + 1)
            arraylist(arraysize) = asc(sT)
            arraysize = arraysize + 1
        end if
    next
    depth = 0
    for i = 0 to arraysize - 1
        Dim mybyte
        mybyte = arraylist(i)
        if mybyte and &h80 then
            if (mybyte and &h40) = 0 then
                if depth = 0 then
                    Err.Raise 5
                end if
                val = val * 2 ^ 6 + (mybyte and &h3f)
                depth = depth - 1
                if depth = 0 then
                    sR = sR & chrw(val)
                    val = 0
                end if
            elseif (mybyte and &h20) = 0 then
                if depth > 0 then Err.Raise 5
                val = mybyte and &h1f
                depth = 1
            elseif (mybyte and &h10) = 0 then
                if depth > 0 then Err.Raise 5
                val = mybyte and &h0f
                depth = 2
            else
                Err.Raise 5
            end if
        else
            if depth > 0 then Err.Raise 5
            sR = sR & chrw(mybyte)
        end if
    next
    if depth > 0 then Err.Raise 5
    UTF8Decode = sR
End Function
'- End file: i18n/UTF8Decode.vbs
'- Begin file: utils/x64Fix.vbs
' x64Fix.vbs

' To include this file, copy/paste: INCLUDE=utils/x64Fix.vbs

Function x64Fix
' This is a function which should be called before calling any vbscript run by 
' the Tanium client that needs 64-bit registry or filesystem access.
' It's for when we need to catch if a machine has 64-bit windows
' and is running in a 32-bit environment.
'  
' In this case, we will re-launch the sensor in 64-bit mode.
' If it's already in 64-bit mode on a 64-bit OS, it does nothing and the sensor 
' continues on
    
    Const WINDOWSDIR = 0
    Const HKLM = &h80000002
    
    Dim objShell: Set objShell = CreateObject("WScript.Shell")
    Dim objFSO: Set objFSO = CreateObject("Scripting.FileSystemObject")
    Dim objSysEnv: Set objSysEnv = objShell.Environment("PROCESS")
    Dim objReg, objArgs, objExec
    Dim strOriginalArgs, strArg, strX64cscriptPath, strMkLink
    Dim strProgramFilesX86, strProgramFiles, strLaunchCommand
    Dim strKeyPath, strTaniumPath, strWinDir
    Dim b32BitInX64OS

    b32BitInX64OS = false

    ' we'll need these program files strings to check if we're in a 32-bit environment
    ' on a pre-vista 64-bit OS (if no sysnative alias functionality) later
    strProgramFiles = objSysEnv("ProgramFiles")
    strProgramFilesX86 = objSysEnv("ProgramFiles(x86)")
    ' WScript.Echo "Are the program files the same?: " & (LCase(strProgramFiles) = LCase(strProgramFilesX86))
    
    ' The windows directory is retrieved this way:
    strWinDir = objFso.GetSpecialFolder(WINDOWSDIR)
    'WScript.Echo "Windir: " & strWinDir
    
    ' Now we determine a cscript path for 64-bit windows that works every time
    ' The trick is that for x64 XP and 2003, there's no sysnative to use.
    ' The workaround is to do an NTFS junction point that points to the
    ' c:\Windows\System32 folder.  Then we call 64-bit cscript from there.
    ' However, there is a hotfix for 2003 x64 and XP x64 which will enable
    ' the sysnative functionality.  The customer must either have linkd.exe
    ' from the 2003 resource kit, or the hotfix installed.  Both are freely available.
    ' The hotfix URL is http://support.microsoft.com/kb/942589
    ' The URL For the resource kit is http://www.microsoft.com/download/en/details.aspx?id=17657
    ' linkd.exe is the only required tool and must be in the machine's global path.

    If objFSO.FileExists(strWinDir & "\sysnative\cscript.exe") Then
        strX64cscriptPath = strWinDir & "\sysnative\cscript.exe"
        ' WScript.Echo "Sysnative alias works, we're 32-bit mode on 64-bit vista+ or 2003/xp with hotfix"
        ' This is the easy case with sysnative
        b32BitInX64OS = True
    End If
    If Not b32BitInX64OS And objFSO.FolderExists(strWinDir & "\SysWow64") And (LCase(strProgramFiles) = LCase(strProgramFilesX86)) Then
        ' This is the more difficult case to execute.  We need to test if we're using
        ' 64-bit windows 2003 or XP but we're running in a 32-bit mode.
        ' Only then should we relaunch with the 64-bit cscript.
        
        ' If we don't accurately test 32-bit environment in 64-bit OS
        ' This code will call itself over and over forever.
        
        ' We will test for this case by checking whether %programfiles% is equal to
        ' %programfiles(x86)% - something that's only true in 64-bit windows while
        ' in a 32-bit environment
    
        ' WScript.Echo "We are in 32-bit mode on a 64-bit machine"
        ' linkd.exe (from 2003 resource kit) must be in the machine's path.
        
        strMkLink = "linkd " & Chr(34) & strWinDir & "\System64" & Chr(34) & " " & Chr(34) & strWinDir & "\System32" & Chr(34)
        strX64cscriptPath = strWinDir & "\System64\cscript.exe"
        ' WScript.Echo "Link Command is: " & strMkLink
        ' WScript.Echo "And the path to cscript is now: " & strX64cscriptPath
        On Error Resume Next ' the mklink command could fail if linkd is not in the path
        ' the safest place to put linkd.exe is in the resource kit directory
        ' reskit installer adds to path automatically
        ' or in c:\Windows if you want to distribute just that tool
        
        If Not objFSO.FileExists(strX64cscriptPath) Then
            ' WScript.Echo "Running mklink" 
            ' without the wait to completion, the next line fails.
            objShell.Run strMkLink, 0, true
        End If
        On Error GoTo 0 ' turn error handling off
        If Not objFSO.FileExists(strX64cscriptPath) Then
            ' if that cscript doesn't exist, the link creation didn't work
            ' and we must quit the function now to avoid a loop situation
            ' WScript.Echo "Cannot find " & strX64cscriptPath & " so we must exit this function and continue on"
            ' clean up
            Set objShell = Nothing
            Set objFSO = Nothing
            Set objSysEnv = Nothing
            Exit Function
        Else
            ' the junction worked, it's safe to relaunch            
            b32BitInX64OS = True
        End If
    End If
    If Not b32BitInX64OS Then
        ' clean up and leave function, we must already be in a 32-bit environment
        Set objShell = Nothing
        Set objFSO = Nothing
        Set objSysEnv = Nothing
        
        ' WScript.Echo "Cannot relaunch in 64-bit (perhaps already there)"
        ' important: If we're here because the client is broken, a sensor will
        ' run but potentially return incomplete or no values (old behavior)
        Exit Function
    End If
    
    ' So if we're here, we need to re-launch with 64-bit cscript.
    ' take the arguments to the sensor and re-pass them to itself in a 64-bit environment
    strOriginalArgs = ""
    Set objArgs = WScript.Arguments
    
    For Each strArg in objArgs
        strOriginalArgs = strOriginalArgs & " " & Chr(34) & strArg & Chr(34)
    Next
    ' after we're done, we have an unnecessary space in front of strOriginalArgs
    strOriginalArgs = LTrim(strOriginalArgs)
    
    ' If this is running as a sensor, we need to know the path of the tanium client
    strKeyPath = "Software\Tanium\Tanium Client"
    Set objReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
    
    objReg.GetStringValue HKLM,strKeyPath,"Path", strTaniumPath

    ' WScript.Echo "StrOriginalArgs is:" & strOriginalArgs
    If objFSO.FileExists(Wscript.ScriptFullName) Then
        strLaunchCommand = Chr(34) & Wscript.ScriptFullName & Chr(34) & " " & strOriginalArgs
        ' WScript.Echo "Script full path is: " & WScript.ScriptFullName
    Else
        ' the sensor itself will not work with ScriptFullName so we do this
        strLaunchCommand = Chr(34) & strTaniumPath & "\VB\" & WScript.ScriptName & chr(34) & " " & strOriginalArgs
    End If
    ' WScript.Echo "launch command is: " & strLaunchCommand

    Set objExec = objShell.Exec(strX64cscriptPath & " " & strLaunchCommand)
    
    ' skipping the two lines and space after that look like
    ' Microsoft (R) Windows Script Host Version
    ' Copyright (C) Microsoft Corporation
    '
    objExec.StdOut.SkipLine
    objExec.StdOut.SkipLine
    objExec.StdOut.SkipLine

    ' sensor output is all about stdout, so catch the stdout of the relaunched
    ' sensor
    Wscript.Echo objExec.StdOut.ReadAll()
    
    ' critical - If we've relaunched, we must quit the script before anything else happens
    WScript.Quit
    ' Remember to call this function only at the very top
    
    ' Cleanup
    Set objReg = Nothing
    Set objArgs = Nothing
    Set objExec = Nothing
    Set objShell = Nothing
    Set objFSO = Nothing
    Set objSysEnv = Nothing
    Set objReg = Nothing
End Function 'x64Fix
'- End file: utils/x64Fix.vbs
