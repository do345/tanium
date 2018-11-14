'
' Tanium Trace Database Statistics

Option Explicit

If GetOSMajorVersion() < 6.1 Then ' Older Than Windows 7
    WScript.Echo "Platform is Not Supported"
    Wscript.Quit()
End If

Call runVersionChecks()

Dim savedQuestionName: savedQuestionName = "tanium-trace-database-health.vbs"
Dim savedQuestionVersion: savedQuestionVersion = "2.7.3.0004"
Dim objFSO: Set objFSO = CreateObject("Scripting.FileSystemObject")

If objFSO.FileExists(GetClientDir() & "Tools\Trace\RecorderDatabaseQuery.vbs") Then
    ImportTraceLibs "RecorderDatabaseQuery.vbs"
Else
    ImportTraceLibs "TaniumTraceQuery.vbs"
End If

Const MAX_SIZE_EXCEEDED_SLOP_PERCENTAGE = 10 ' allows for some temporary overage
Dim bHasError: bHasError = False
Dim dictOut: Set dictOut = CreateObject("Scripting.Dictionary")

Dim strMonitorPath: strMonitorPath = objFSO.BuildPath(GetClientDir(), "\monitor.db")



Dim sCreatedDate, sOldestItemDate, iLogSince, iMaxSizeMB, iMaxSizeB, iRealDBSize, iRealDBSizeMB, iRate
Dim i1DayCnt, i3DaysCnt, i7DaysCnt , i30DaysCnt

Dim iTotalCnt
Dim iProcessCnt, iFileCnt, iNetworkCnt, iRegistryCnt, iDNSCnt, iDriverCnt
Dim iProcessRate, iFileRate, iNetworkRate, iRegistryRate, iDNSRate, iDriverRate


sCreatedDate = DatabaseCreationDate()
sCreatedDate = Left(sCreatedDate,InStr(sCreatedDate," ")-1)

sOldestItemDate = DatabaseOldestItemDate()
sOldestItemDate = Left(sOldestItemDate,InStr(sOldestItemDate," ")-1)

iLogSince = DateDiff("d", sOldestItemDate, Now() )

iMaxSizeMB = ReadTaniumRegistry("\Trace\MaxStorageSizeMB")
If iMaxSizeMB = "" Then
WScript.Echo "Trace not installed"
WScript.Quit
End If

iMaxSizeB = iMaxSizeMB * 1048576

iRealDBSize = objFSO.GetFile(strMonitorPath).Size 
iRealDBSizeMB = Round(iRealDBSize / 1048576,1)

iRate = FormatPercent(iRealDBSizeMB / iMaxSizeMB,1)

i1DayCnt = NumberOfIncreasedItemsByDay(1)
i3DaysCnt = NumberOfIncreasedItemsByDay(3)
i7DaysCnt = NumberOfIncreasedItemsByDay(7)
'i30DaysCnt = NumberOfIncreasedItemsByDay(30)

iProcessCnt = CLng(NumberOfTotalCountbyTable("ProcessEvents"))
iFileCnt = CLng(NumberOfTotalCountbyTable("FileEvents"))
iNetworkCnt = CLng(NumberOfTotalCountbyTable("NetworkEvents"))
iRegistryCnt = CLng(NumberOfTotalCountbyTable("RegistryEvents"))
iDNSCnt = CLng(NumberOfTotalCountbyTable("DNSEvents"))
iDriverCnt = CLng(NumberOfTotalCountbyTable("DriverEvents"))


iTotalCnt = iProcessCnt + iFileCnt + iNetworkCnt + iRegistryCnt + iDNSCnt + iDriverCnt

'WScript.Echo "Total : (" & iTotalCnt & ")"  

iProcessRate = FormatPercent(iProcessCnt / iTotalCnt,1)
iFileRate =  FormatPercent(iFileCnt / iTotalCnt ,1)
iNetworkRate = FormatPercent(iNetworkCnt / iTotalCnt,1)
iRegistryRate = FormatPercent(iRegistryCnt / iTotalCnt,1)
iDNSRate = FormatPercent(iDNSCnt / iTotalCnt ,1)
iDriverRate = FormatPercent(iDriverCnt / iTotalCnt ,1)

WScript.Echo sCreatedDate & "|" & sOldestItemDate  & "|" & iLogSince  & "|" & iRealDBSizeMB & "|" & iRate & "|" & iMaxSizeMB & "|" & i1DayCnt & "|" & i3DaysCnt & "|" & i7DaysCnt & "|" & iProcessRate & "|" & iFileRate & "|" & iNetworkRate & "|" & iRegistryRate & "|" & iDNSRate & "|" & iDriverRate




' --- END MAIN LINE ---- '
Function GetRecorderDatabaseQueryObj()
    On Error Resume Next
    Dim rdbq: Set rdbq = New RecorderDatabaseQuery
    If Err.Number <> 0 Then
        Set rdbq = New TaniumTraceQuery
    End If
    On Error Goto 0
    Set GetRecorderDatabaseQueryObj = rdbq
End Function



'//'

Function DatabaseCreationDate
    DatabaseCreationDate = False
    Dim x: Set x = GetRecorderDatabaseQueryObj()
    x.MaxLines = 2
    x.MaxSelectLines_DANGEROUS = 1
    x.QueryString = "SELECT HEX(info_value) from SystemInformation where info_name='CreateDate'"

    On Error Resume Next
        x.DoQuery(1)
        If Err.Number <> 0 Then
            bHasError = True
            AD dictOut, "Error: Potentially corrupted database error was: " & Trim(Replace(Err.Description, vbLf, "")), ""
        End If
    On Error Goto 0

    Dim arrResults: arrResults = x.ResultsArray
    Dim strQuery: strQuery = arrResults(0)

    DatabaseCreationDate = strQuery

End Function 'DatabaseCreationDate



Function DatabaseOldestItemDate
    DatabaseOldestItemDate = False
    Dim x: Set x = GetRecorderDatabaseQueryObj()
    x.MaxLines = 2
    x.MaxSelectLines_DANGEROUS = 1

'    x.QueryString = "SELECT HEX(info_value) from SystemInformation where info_name='CreateDate'"

    x.QueryString = "SELECT HEX(timestamp) from CombinedEventsSummary Limit 1"

    On Error Resume Next
        x.DoQuery(1)
        If Err.Number <> 0 Then
            bHasError = True
            AD dictOut, "Error: Potentially corrupted database error was: " & Trim(Replace(Err.Description, vbLf, "")), ""
        End If
    On Error Goto 0

    Dim arrResults: arrResults = x.ResultsArray
    Dim strQuery: strQuery = arrResults(0)

    DatabaseOldestItemDate = strQuery

End Function 'DatabaseOldestItemDate



Function NumberOfIncreasedItemsByDay (iDay)
    Dim sDay

    NumberOfIncreasedItemsByDay = False
    Dim x: Set x = GetRecorderDatabaseQueryObj()
    x.MaxLines = 2
    x.MaxSelectLines_DANGEROUS = 1

    if iDay = 1 then
        sDay = "1 day"
    elseif iDay = 3 then
        sDay = "3 days" 
    elseif iDay = 7 then
        sDay = "1 week" 
    elseif iday = 30 then
        sDay = "1 month"
    end if

    Dim timestamps: timestamps = TempGetTimeRange(Trim(UTF8Decode(sDay)),  Trim(UTF8Decode(" ")), x)

    x.QueryString = "SELECT HEX(count(id)) from CombinedEventsSummary where timestamp_raw >= " & timestamps(0)  & " AND timestamp_raw <= " & timestamps(1)

    On Error Resume Next
        x.DoQuery(1)
        If Err.Number <> 0 Then
            bHasError = True
            AD dictOut, "Error: Potentially corrupted database error was: " & Trim(Replace(Err.Description, vbLf, "")), ""
        End If
    On Error Goto 0

    Dim arrResults: arrResults = x.ResultsArray
    Dim strQuery: strQuery = arrResults(0)

    NumberOfIncreasedItemsByDay = strQuery

End Function 'NumberOfIncreasedItemsByDay




Function NumberOfTotalCountbyTable (sTableName)

    NumberOfTotalCountbyTable = False
    Dim x: Set x = GetRecorderDatabaseQueryObj()
    x.MaxLines = 2
    x.MaxSelectLines_DANGEROUS = 1

    x.QueryString = "SELECT HEX(count(*)) from " & sTableName 

    On Error Resume Next
        x.DoQuery(1)
        If Err.Number <> 0 Then
            bHasError = True
            AD dictOut, "Error: Potentially corrupted database error was: " & Trim(Replace(Err.Description, vbLf, "")), ""
        End If
    On Error Goto 0

    Dim arrResults: arrResults = x.ResultsArray
    Dim strQuery: strQuery = arrResults(0)

    NumberOfTotalCountbyTable = strQuery

End Function 'NumberOfTotalCountbyTable



Function GetSchemaFromDatabaseQuery
    GetSchemaFromDatabaseQuery = -1
    Dim x: Set x = GetRecorderDatabaseQueryObj()
    x.MaxLines = 2
    x.MaxSelectLines_DANGEROUS = 1
    x.QueryString = "SELECT HEX(trace_database) from TraceVersion order by id desc limit 1"

    On Error Resume Next
        x.DoQuery(1)
        If Err.Number <> 0 Then
            bHasError = True
            AD dictOut, "Error: Potentially corrupted database error was: " & Trim(Replace(Err.Description, vbLf, "")), ""
        End If
    On Error Goto 0

    Dim arrResults: arrResults = x.ResultsArray
    Dim strSchemaQuery: strSchemaQuery = arrResults(0)
    Dim intSchemaQuery
    If IsNumeric(strSchemaQuery) Then
        intSchemaQuery = CInt(strSchemaQuery)
    End If
    If intSchemaQuery > 0 Then
        GetSchemaFromDatabaseQuery = intSchemaQuery
    End If
End Function 'GetSchemaFromDatabaseQuery




Sub AD(ByRef dict,ByVal item,ByVal val)
    If Not dict.Exists(item) Then
        dict.Add item,val
    End If
End Sub 'AD


Sub EchoDict(ByRef dict, hasError)
    Dim str
    For Each str In dict.Keys
        WScript.Echo str
    Next
    If hasError = False Then
        WScript.Echo "Health Check Passed"
    Else
        WScript.Echo "Health Check Failed"
    End If
End Sub 'EchoDict
'------------ INCLUDES after this line. Do not edit past this point -----
'- Begin file: utils/import-trace-libs.vbs

Sub ImportTraceLibs(strCommaSeparatedFiles)

    Dim objFSO,strLibFile,strCode
    Set objFSO = CreateObject("Scripting.FileSystemObject")

    For Each strLibFile In Split(strCommaSeparatedFiles, ",")
        Dim strFoundFilePath1: strFoundFilePath1 = GetClientDir() & "Tools\Trace\" & strLibFile
        Dim strFoundFilePath2: strFoundFilePath2 = "..\..\Tools\Trace\" & strLibFile
        ' Remove strFoundFilePath3 when Trace 2.2.1 & earlier is no longer supported
        Dim strFoundFilePath3: strFoundFilePath3 = GetClientDir() & "Tools\VBLib\" & strLibFile
        If objFSO.FileExists(strFoundFilePath1) Then
            strCode = objFSO.OpenTextFile(strFoundFilePath1).ReadAll
        ElseIf objFSO.FileExists(strFoundFilePath2) Then
            strCode = objFSO.OpenTextFile(strFoundFilePath2).ReadAll
        ElseIf objFSO.FileExists(strFoundFilePath3) Then
            strCode = objFSO.OpenTextFile(strFoundFilePath3).ReadAll
        End If
        ' fallback
        If objFSO.FileExists(strLibFile) Then
            ' WScript.Echo "Alternate/Full path to lib file specified: " & strLibFile
            strCode = objFSO.OpenTextFile(strLibFile).ReadAll
        End If
        If strCode <> "" Then
            ExecuteGlobal strCode
        Else
            WScript.Echo "Trace Endpoint Tools not installed"
            WScript.Quit
        End If
    Next
End Sub 'ImportTraceLibs


Function GetClientDir()
    Dim strResult
    
    strResult = GetEnvironmentValue("TANIUM_CLIENT_ROOT")
    
    If IsNull(strResult) Then 
        Dim objSh
        strResult = ""
        Set objSh = CreateObject("WScript.Shell")
    
        On Error Resume Next
        If strResult="" Then strResult=Eval("objSh.RegRead(""HKLM\Software\Tanium\Tanium Client\Path"")") : Err.Clear
        If strResult="" Then strResult=Eval("objSh.RegRead(""HKLM\Software\Wow6432Node\Tanium\Tanium Client\Path"")") : Err.Clear
        If strResult="" Then Err.Clear
        On Error Goto 0
    End If
    
    If strResult="" Then Call fRaiseError(5, "GetClientDir", _
        "TSE-Error:Can not locate client directory", False)
        
    If Right(strResult, 1) <> "\" Then strResult = strResult & "\"

    GetClientDir = strResult
End Function


Function fRaiseError(errCode, errSource, errorMsg, RaiseError)
    If RaiseError Then
      On Error Resume Next
      Call Err.Raise(errCode, errSource, errorMsg)
      Exit Function
    Else
      WScript.Echo errorMsg
      Wscript.Quit
    End If
End Function


Function GetEnvironmentValue(strName) 
    Dim objShell, strSub, strResult
    Set objShell = CreateObject("WScript.Shell")
    strSub = "%" & strName & "%"
    strResult = objShell.ExpandEnvironmentStrings(strSub)
    
    If strResult = strSub Then 
        GetEnvironmentValue = Null
    Else 
        GetEnvironmentValue = strResult
    End If
End Function ' GetEnvironmentValue

Function UpdateParam(paramIn, treatInputAsRegEx)
    If treatInputAsRegEx Then
        If paramIn = "" Then
            ' Probably intend to match everything
            paramIn = ".*"
        End If
    Else
        Dim arrEscapeThese, charToEsc
        ' Input parameters (paramIn) are percent encoded
        arrEscapeThese = Array("\", "%", "_")
        For Each charToEsc In arrEscapeThese
            paramIn = Replace(paramIn, charToEsc, "\" & charToEsc)
        Next
        paramIn = "%" & paramIn & "%"
    End If
    UpdateParam = paramIn
End Function 'UpdateParam

Function GetYesNoTrueFalse(value)
    GetYesNoTrueFalse = "" ' would be invalid as boolean
    On Error Resume Next
    value = CStr(value)
    If Err.Number <> 0 Then
        WScript.Echo "Error: Could not convert parameter value to string ("&Err.Description&")"
        WScript.Quit
    End If
    On Error Goto 0
    value = LCase(value)

    Select Case value
        Case "yes"
            GetYesNoTrueFalse = True
        Case "true"
            GetYesNoTrueFalse = True
        Case "1"
            GetYesNoTrueFalse = True
        Case "no"
            GetYesNoTrueFalse = False
        Case "false"
            GetYesNoTrueFalse = False
        Case "0"
            GetYesNoTrueFalse = False
        Case Else
            WScript.Echo "Error: Parameter requires Yes or No as input value, was given: " &value
            WScript.Quit
    End Select
End Function 'GetYesNoTrueFalse

Function GetPrintableDateFromSQLiteDate(strSQLiteDate, objTTQ)

    Dim strDateOut: strDateOut = strSQLiteDate
    On Error Resume Next ' just fail open and print something
   
    If Left(strSQLiteDate,1) = "0" Then
        strDateOut = "[N/A]"
    ElseIf strSQLiteDate <> "[removed]" AND Trim(strSQLiteDate) <> "" Then
        strDateOut = strSQLiteDate & "+00:00"
    End If
    On Error Goto 0
    GetPrintableDateFromSQLiteDate = strDateOut
End Function 'GetPrintableDateFromSQLiteDate

Dim paramCounter
Function genSqlPhrase(conjunction, colName, param, ttq)
    Dim operator: operator = "REGEXP"
    Dim likeEscape: likeEscape = ""
    If Trim(param) = "" OR Trim(param) = "*" OR Trim(param) = ".*" Then
        genSqlPhrase = ""
        Exit Function
    End If
    If Not ttq.TreatInputAsRegEx Then
        operator = "LIKE"
        likeEscape = "ESCAPE '\'"
    End If

    If TypeName(paramCounter) = "Empty" Then
        paramCounter = 1
    End If
    genSqlPhrase = " " & conjunction & " " & colName & " " & _
        operator & " ${$" & paramCounter & ", string} " & likeEscape & " "
    Call ttq.AddParameter(param, 0)
    paramCounter = paramCounter + 1
End Function


Function runVersionChecks()
    Dim objFSO: Set objFSO = CreateObject("Scripting.FileSystemObject")
    Dim minVersion: minVersion = "2.0.6"


    Dim dOld: Set dOld = CreateObject("Scripting.Dictionary")
    Call dOld.Add(GetClientDir() & "Tools\VBLib\TaniumTraceQuery.vbs", ">=")
    Call dOld.Add(GetClientDir() & "Tools\VBLib\aspJSON.vbs", ">=")
    If endpointLibrariesOk(dOld, minVersion, False, True) Then
        ' If the files exist in the old VBLib directory and pass the version check, then exit this function
        Exit Function
    End If

    Dim d: Set d = CreateObject("Scripting.Dictionary")
    Call d.Add(GetClientDir() & "Tools\Trace\aspJSON.vbs", ">=")

    ' Once Trace 2.5.x & earlier is no longer supported, simplify this block to just: `Call d.Add(rdbq, ">=")`
    Dim rdbq: rdbq = GetClientDir() & "Tools\Trace\RecorderDatabaseQuery.vbs"
    Dim ttq: ttq = GetClientDir() & "Tools\Trace\TaniumTraceQuery.vbs"
    If objFSO.FileExists(rdbq) Then
        Call d.Add(rdbq, ">=")
    ElseIf objFSO.FileExists(ttq) Then
        Call d.Add(ttq, ">=")
    Else
        Call d.Add(rdbq, ">=")
    End If

    If Not endpointLibrariesOk(d, minVersion, True, True) Then
        WScript.Echo "Error: Redeploy ""Distribute Tanium Trace Tools"", as one or more incompatible endpoint " _
            & "resident libraries were found (minimum required version = " & minVersion & ")"
         WScript.Quit()
    End If
End Function




Function endpointLibrariesOk(dictOfErlPaths, minRequiredVersion, printErrors, failIfMissingTFV)

    Dim passedCheck: passedCheck = True
    Dim objFSO: Set objFSO = CreateObject("Scripting.FileSystemObject")
    Dim filename: For Each filename in dictOfErlPaths
        If Not objFSO.FileExists(filename) Then
            passedCheck = False
            If printErrors Then
                WScript.Echo "Error: Missing required file: " & filename
            End If
        Else
            Dim objFile: Set objFile = objFSO.OpenTextFile(filename, 1)  ' 1 = Reading Mode
            Dim contents: contents = objFile.ReadAll()

            If InStr(contents, "Tanium File Version:") <> 0 Then
                ' Extract the actual Tanium File Version
                Dim actualVersion: actualVersion = Trim(Split(Split(contents, "Tanium File Version:")(1), VbLf)(0))

                ' Skip the check if the version token (00.00.000.0000" + ".VER.0) has Not been replaced, because
                ' some Product Modules (e.g. Trace) dynamically generate versions of sensors at runtime.
                If actualVersion <> "00.00.000.0000" & ".VER.0" Then
                    Dim singleCheckPassed: singleCheckPassed = compareVersionArrays(versionStrToArray(actualVersion), _
                        dictOfErlPaths(filename), versionStrToArray(minRequiredVersion))
                    passedCheck = passedCheck And singleCheckPassed
                    If printErrors And Not singleCheckPassed Then
                        WScript.Echo "Error: """ & objFSO.GetFileName(filename) & """ is outdated"
                    End If
                End If
            Else
                If failIfMissingTFV Then
                    passedCheck = False
                    If printErrors Then
                        WScript.Echo "Error: Expected string ""Tanium File Version:"" Not found in: " & filename
                    End If
                End If
            End If
        End If
    Next
    endpointLibrariesOk = passedCheck
End Function

Function versionStrToArray(versionStr)

    Dim verArray: verArray = Split(versionStr, ".")
    Dim i: For i=0 To UBound(verArray)
        On Error Resume Next
        verArray(i) = CInt(verArray(i))
        On Error Goto 0
    Next
    versionStrToArray = verArray
End Function

Function compareVersionArrays(verArray1, operator, verArray2)

    If operator <> ">" AND operator <> ">=" AND operator <> "==" AND operator <> "<=" AND operator <> "<" Then
        WScript.Echo "Error: Unrecognized comparison operator used in Function compareVersionArrays()"
        WScript.Quit()
    End If

    Dim i: For i = 0 To UBound(verArray1)
        ' e.g. verArray1 = [1, 2, 3] and verArray2 = [1, 2]
        If UBound(verArray2) < i Then
            If operator = ">=" OR operator = ">" Then
                compareVersionArrays = True
            Else
                compareVersionArrays = False
            End If
            Exit Function
        End If

        If verArray1(i) > verArray2(i) Then
            If operator = "==" OR operator = "<=" OR operator = "<" Then
                compareVersionArrays = False
            Else
                compareVersionArrays = True
            End If
            Exit Function
        ElseIf verArray1(i) < verArray2(i) Then
            If operator = "==" OR operator = ">=" OR operator = ">" Then
                compareVersionArrays = False
            Else
                compareVersionArrays = True
            End If
            Exit Function
        End If
    Next


    If UBound(verArray2) = UBound(verArray1) Then
        If operator = "==" OR operator = ">=" OR operator = "<=" Then
            compareVersionArrays = True
        Else
            compareVersionArrays = False
        End If
        Exit Function
    End If

    If UBound(verArray2) > UBound(verArray1) AND (operator = "==" OR operator = ">=" OR operator = ">") Then
        compareVersionArrays = False
    Else
        compareVersionArrays = True
    End If
End Function

Function GetTaniumRegistryPath
    Dim objShell
    Dim keyNativePath, keyWoWPath, strPath, strFoundTaniumRegistryPath

    Set objShell = CreateObject("WScript.Shell")

    keyNativePath = "HKLM\Software\Tanium\Tanium Client"
    keyWoWPath = "HKLM\Software\Wow6432Node\Tanium\Tanium Client"

    On Error Resume Next
    strPath = objShell.RegRead(keyWoWPath&"\Path")
    On Error Goto 0
    strFoundTaniumRegistryPath = keyWoWPath

    If strPath = "" Then
        ' Could not find 64-bit mode path, checking 32bit
        On Error Resume Next
        strPath = objShell.RegRead(keyNativePath&"\Path")
        On Error Goto 0
        strFoundTaniumRegistryPath = keyNativePath
    End If

    If Not strPath = "" Then
        GetTaniumRegistryPath = strFoundTaniumRegistryPath
    Else
        GetTaniumRegistryPath = False
        tLog.log "Error: Cannot locate Tanium Registry Path"
    End If
End Function 'GetTaniumRegistryPath


Function GetOSMajorVersion
    Dim strVersion,arrVersion
    
    strVersion = GetOSVersion()

    arrVersion = Split(strVersion,".")
    If UBound(arrVersion) >= 1 Then
        strVersion = arrVersion(0)&"."&arrVersion(1)
    End If

    GetOSMajorVersion = strVersion
End Function 'GetOSMajorVersion


Function GetOSVersion
' Returns the OS Version
    Dim objWMIService,colItems,objItem
    Dim strVersion
    
    strVersion = Null

    Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2")
    Set colItems = GetObject("WinMgmts:root/cimv2").ExecQuery("select Version from win32_operatingsystem")
    For Each objItem In colItems
        strVersion = objItem.Version ' like 6.2.9200
    Next
    
    If IsNull(strVersion) Then
        fRaiseError 5, "GetOSVersion", "Error:  Can not determine OS Version", False
    End If
    
    GetOSVersion = strVersion
End Function ' GetOSMajor




Function ReadTaniumRegistryImpl(strSubKey, printError)
Dim objShell, keyPath
keyPath = GetTaniumRegistryPath & strSubKey
Set objShell = CreateObject("WScript.Shell")
On Error Resume Next
ReadTaniumRegistryImpl = objShell.RegRead(keyPath)
If Err.Number <> 0 Then
if printError Then
WScript.Echo Err.Description
End If
Err.Clear
ReadTaniumRegistryImpl = Empty
End If
On Error Goto 0
End Function

Function ReadTaniumRegistryAndPrintErrors(strSubKey)
ReadTaniumRegistryAndPrintErrors = ReadTaniumRegistryImpl(strSubKey, True)
End Function

Function ReadTaniumRegistry(strSubKey)
ReadTaniumRegistry = ReadTaniumRegistryImpl(strSubKey, False)
End Function

Function GetTaniumRegistryPath
Dim objShell
Dim keyNativePath, keyWoWPath, strPath, strFoundTaniumRegistryPath
Set objShell = CreateObject("WScript.Shell")
keyNativePath = "HKLM\Software\Tanium\Tanium Client"
keyWoWPath = "HKLM\Software\Wow6432Node\Tanium\Tanium Client"
On Error Resume Next
strPath = objShell.RegRead(keyWoWPath&"\Path")
On Error Goto 0
strFoundTaniumRegistryPath = keyWoWPath
If strPath = "" Then
On Error Resume Next
strPath = objShell.RegRead(keyNativePath&"\Path")
On Error Goto 0
strFoundTaniumRegistryPath = keyNativePath
End If
If Not strPath = "" Then
GetTaniumRegistryPath = strFoundTaniumRegistryPath
Else
GetTaniumRegistryPath = False
tLog.log "Error: Cannot locate Tanium Registry Path"
End If
End Function


Function TempGetTimeRange(offset, absTimeRange, rdbq)
    If offset = "30 minutes" Then
        Dim endTime: endTime = DateDiff("s", "01/01/1970 00:00:00", _
            DateAdd("n", -GetTZOffsetMinutes(), Now()))
        TempGetTimeRange = rdbq.GetTimeRange("absolute time range", _
            (endTime - 30 * 60) * 1000 & "|" & (endTime * 1000))
    Else
        TempGetTimeRange = rdbq.GetTimeRange(offset, absTimeRange)
    End If
End Function



Function GetTZOffsetMinutes
' returns local machine's offset in minutes
    Dim objWMIService,colTimeZone,objTimeZone,intTZBiasInMinutes
    Set objWMIService = GetObject("winmgmts:" _
        & "{impersonationLevel=impersonate}!\\.\root\cimv2")
    Set colTimeZone = objWMIService.ExecQuery("Select * from Win32_ComputerSystem")
    For Each objTimeZone in colTimeZone
        intTZBiasInMinutes = objTimeZone.CurrentTimeZone
    Next
    GetTZOffsetMinutes = intTZBiasInMinutes
End Function 'GetTZOffsetMinutes
