'========================================
' Tanium Trace Database Statistics
' 
' 
' 
' 
' 

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
'Dim iNowSeconds, i1DaySeconds, i7DaysSeconds, i30DaysSeconds
Dim i1DayCnt, i7DaysCnt, i30DaysCnt

Dim iTotalCnt
Dim iProcessCnt, iFileCnt, iNetworkCnt, iRegistryCnt, iDNSCnt, iDriverCnt
Dim iProcessRate, iFileRate, iNetworkRate, iRegistryRate, iDNSRate, iDriverRate


Dim tempString

sCreatedDate = DatabaseCreationDate()
sCreatedDate = Left(sCreatedDate,InStr(sCreatedDate," ")-1)
'WScript.Echo sCreatedDate 

sOldestItemDate = DatabaseOldestItemDate()
'WScript.Echo sOldestItemDate 

sOldestItemDate = Left(sOldestItemDate,InStr(sOldestItemDate," ")-1)
'WScript.Echo sOldestItemDate 

iLogSince = DateDiff("d", sOldestItemDate, Now() )
'WScript.Echo iLogSince

iMaxSizeMB = ReadTaniumRegistry("\Trace\MaxStorageSizeMB")
If iMaxSizeMB = "" Then
WScript.Echo "Trace not installed"
WScript.Quit
End If

iMaxSizeB = iMaxSizeMB * 1048576
'Wscript.Echo iMaxSizeMB & "|" & iMaxSizeB

iRealDBSize = objFSO.GetFile(strMonitorPath).Size 
iRealDBSizeMB = iRealDBSize / 1048576
'WScript.Echo iRealDBSize 

iRate = FormatPercent(iRealDBSize / iMaxSizeB,1)

'iNowSeconds = DateDiff("s", "01/01/1970 00:00:00", DateAdd("n", -GetTZOffsetMinutes(), Now()))
'i1DaySeconds = iNowSeconds - 60 * 60 * 24
'i7DaysSeconds = iNowSeconds - 60 * 60 * 24 * 7
'i30DaysSeconds = iNowSeconds - 60 * 60 * 24 * 30
'WSCript.Echo iNowSeconds & " " & i1DaySeconds & " " & i7DaysSeconds & " " & i30DaysSeconds


i1DayCnt = NumberOfIncreasedItemsByDay(1)
i7DaysCnt = NumberOfIncreasedItemsByDay(7)
i30DaysCnt = NumberOfIncreasedItemsByDay(30)

'WScript.Echo "1 Day   : " & i1DayCnt
'WScript.Echo "7 Days  : " & i7DaysCnt
'WScript.Echo "30 Days : " & i30DaysCnt

iProcessCnt = CLng(NumberOfTotalCountbyTable("ProcessEvents"))
iFileCnt = CLng(NumberOfTotalCountbyTable("FileEvents"))
iNetworkCnt = CLng(NumberOfTotalCountbyTable("NetworkEvents"))
iRegistryCnt = CLng(NumberOfTotalCountbyTable("RegistryEvents"))
iDNSCnt = CLng(NumberOfTotalCountbyTable("DNSEvents"))
iDriverCnt = CLng(NumberOfTotalCountbyTable("DriverEvents"))

'WSCript.Echo "Process  : " & iProcessCnt
'WSCript.Echo "File     : " & iFileCnt
'WSCript.Echo "Network  : " & iNetworkCnt
'WSCript.Echo "Registry : " & iRegistryCnt
'WSCript.Echo "DNS      : " & iDNSCnt
'WSCript.Echo "Driver   : " & iDriverCnt

iTotalCnt = iProcessCnt + iFileCnt + iNetworkCnt + iRegistryCnt + iDNSCnt + iDriverCnt

'WScript.Echo "Total : (" & iTotalCnt & ")"  

iProcessRate = FormatPercent(iProcessCnt / iTotalCnt,1)
iFileRate =  FormatPercent(iFileCnt / iTotalCnt ,1)
iNetworkRate = FormatPercent(iNetworkCnt / iTotalCnt,1)
iRegistryRate = FormatPercent(iRegistryCnt / iTotalCnt,1)
iDNSRate = FormatPercent(iDNSCnt / iTotalCnt ,1)
iDriverRate = FormatPercent(iDriverCnt / iTotalCnt ,1)


'WSCript.Echo "Process  : " & iProcessRate
'WSCript.Echo "File     : " & iFileRate
'WSCript.Echo "Network  : " & iNetworkRate
'WSCript.Echo "Registry : " & iRegistryRate
'WSCript.Echo "DNS      : " & iDNSRate
'WSCript.Echo "Driver   : " & iDriverRate


WScript.Echo sCreatedDate & "|" & sOldestItemDate  & "|" & iLogSince  & "|" & iRealDBSizeMB & "|" & iRate & "|" & iMaxSizeMB & "|" & i1DayCnt & "|" & i7DaysCnt & "|" & i30DaysCnt & "|" & iTotalCnt & "|" & iProcessRate & "|" & iFileRate & "|" & iNetworkRate & "|" & iRegistryRate & "|" & iDNSRate & "|" & iDriverRate



' print output
'Call EchoDict(dictOut, bHasError)


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


Function GetFileSizeBytes(strPath)
    If Not objFSO.FileExists(strPath) Then
        WScript.Echo "Error: Cannot find Trace Database"
        WScript.Quit
    End If
    GetFileSizeBytes = objFSO.GetFile(strMonitorPath).Size
End Function 'GetFileSizeBytes


Function GetRange(value)
    If value = 0  Then
        GetRange = "0 - 100 MB"
        Exit Function
    End If
    Dim bottom: bottom = Floor(value / 100) * 100
    Dim top: top = Ceil(value / 100) * 100

    If top = bottom Then
        top = top + 100
    End If
    GetRange = bottom & " - " & top & " MB"
End Function 'GetRange

Function Ceil(Number)
    Ceil = Int(Number)
    If Ceil <> Number Then
        Ceil = Ceil + 1
    End If
End Function ' Ceil

Function Floor(Number)
    Floor = Int(Number)
End Function ' Floor

'///////////////////////////////////////////////'
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
    elseif iDay = 7 then
        sDay = "1 week" 
    elseif iday = 30 then
        sDay = "1 month"
    end if

    Dim timestamps: timestamps = TempGetTimeRange(Trim(UTF8Decode(sDay)),  Trim(UTF8Decode("")), x)

    'WScript.Echo timestamps(0) & " " & timestamps(1)

    x.QueryString = "SELECT HEX(count(id)) from CombinedEventsSummary where timestamp_raw >= " & timestamps(0)  & " AND timestamp_raw <= " & timestamps(1)

   ' x.QueryString = "SELECT HEX(timestamp) from CombinedEventsSummary Limit 1"

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


'///////////////////////////////////////////////'


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





Function GetMaxStorageSizeMBFromReg
    Dim strTaniumRegPath,strValName, objShell
    Dim intMaxStorageSizeMB

    strTaniumRegPath = GetTaniumRegistryPath() & "\Trace"
    strValName = "MaxStorageSizeMB"
    Set objShell = CreateObject("WScript.Shell")
    On Error Resume Next
    intMaxStorageSizeMB = objShell.RegRead(strTaniumRegPath & "\" & strValName)
    If Err.Number <> 0 Then
        intMaxStorageSizeMB = 1500 ' Default value if value is not present
    End If
    GetMaxStorageSizeMBFromReg = intMaxStorageSizeMB
End Function 'GetMaxStorageSizeMB


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
    ' Default is to pull from Tanium Client libs directory
    ' can fallback to a relative path
    Dim objFSO,strLibFile,strCode
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    ' possibilities for locating vbs library files
    ' Sensor Execution (tanium root is working dir)
    ' Package Execution (downloads\Action_XXXX is working dir)
    ' Full path specified
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
'- End file: utils/import-trace-libs.vbs
'- Begin file: utils/settings/GetClientDir.vbs
' Returns the directory of the client
' Note:  GetClientDir always returns ending with a \
' To include this file, copy/paste: INCLUDE=utils/settings/GetClientDir.vbs


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
'- End file: utils/settings/GetClientDir.vbs
'- Begin file: utils/RaiseError.vbs
' To include this file, copy/paste: INCLUDE=utils/RaiseError.vbs

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
'- End file: utils/RaiseError.vbs
'- Begin file: utils/os/GetEnvironmentValue.vbs
' Returns the passed in environment variable value.
' Returns either the value as set in the environment, or Null if not set

' To include this file, copy/paste: INCLUDE=utils/os/GetEnvironmentValue.vbs


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
'- End file: utils/os/GetEnvironmentValue.vbs
'- Begin file: utils/trace-common-libraries.vbs
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
    ' Returns a console printable date time from SQLite date
    Dim strDateOut: strDateOut = strSQLiteDate
    On Error Resume Next ' just fail open and print something
    ' This date indicates it's blanked (no start or end date?
    ' would otherwise come out to be 1999 date        
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
'- End file: utils/trace-common-libraries.vbs
'- Begin file: utils/sensor-version-check.vbs

Function runVersionChecks()
    Dim objFSO: Set objFSO = CreateObject("Scripting.FileSystemObject")
    Dim minVersion: minVersion = "2.0.6"

    ' Remove this code block when Trace 2.2.1 & earlier is no longer supported
    ' Check the old VBLib directory, where TaniumTraceQuery.vbs and aspJSON.vbs use to live
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
'- End file: utils/sensor-version-check.vbs
'- Begin file: endpoint_libs/endpoint-library-checks.vbs
' Example Usage:
'
'   '@INCLUDE=utils/endpoint-library-checks.vbs
'   Dim d: Set d = CreateObject("Scripting.Dictionary")
'   Call d.Add(GetClientDir() & "Tools\VBLib\TaniumTraceQuery.vbs", ">=")
'   Call d.Add(GetClientDir() & "Tools\VBLib\aspJSON.vbs", "==")
'   If Not endpointLibrariesOk(d, "2.7.3.0004", True, True) Then
'       WScript.Quit()
'   End If
'




Function endpointLibrariesOk(dictOfErlPaths, minRequiredVersion, printErrors, failIfMissingTFV)
    ' Returns True if all endpoint resident libraries (ERLs) meet the version requirements, False otherwise.
    '
    '   Each endpoint library will specify its version after the string "' Tanium File Version: " (i.e. TFV string).
    '
    '   Args:
    '     dictOfErlPaths (Dictionary): Keys are paths to the endpoint resident libraries (i.e. ERLs) that
    '       need to be checked, and Values indicate the version comparsion to perform (">=" or "==").
    '         Example: {"C:\blah\Tanium Client\Tools\VBLib\file.vbs": True, "C:\another_erl.vbs": False}
    '     minRequiredVersion (String): The minimum required version for all ERLs (e.g. "1.2.3.4")
    '     printErrors (Boolean): When True, errors with be printed to StdOut, otherwise nothing will be
    '         printed by this function.
    '     failIfMissingTFV (Boolean): When True, any ERL missing the TFV string will fail this check (that is,
    '       an error will be printed out and False will be returned).
    '
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
    ' Converts a version number from a string form into an Array of integers
    '
    '   Example: "1.2.3.4" ==> [1, 2, 3, 4]
    '
    Dim verArray: verArray = Split(versionStr, ".")
    Dim i: For i=0 To UBound(verArray)
        On Error Resume Next
        verArray(i) = CInt(verArray(i))
        On Error Goto 0
    Next
    versionStrToArray = verArray
End Function

Function compareVersionArrays(verArray1, operator, verArray2)
    ' Returns True if the version check passes, False otherwise
    '
    '   Both function arguments should be integer arrays
    '   Examples:
    '     verArray1 = [1, 2, 3, 4], verArray2 = [1, 3, 1, 1], operator = ">=", then result = False
    '     verArray1 = [1, 2, 3, 9], verArray2 = [1, 2, 3, 8], operator = ">=", then result = True
    '
    '   Five "operator" values are accepted (any others result in an error): ">", ">=", "==", "<=", "<"
    '
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

    ' e.g. verArray1 = [1, 2, 3] and verArray2 = [1, 2, 3]
    If UBound(verArray2) = UBound(verArray1) Then
        If operator = "==" OR operator = ">=" OR operator = "<=" Then
            compareVersionArrays = True
        Else
            compareVersionArrays = False
        End If
        Exit Function
    End If

    ' e.g. verArray1 = [1, 2] and verArray2 = [1, 2, 3]
    If UBound(verArray2) > UBound(verArray1) AND (operator = "==" OR operator = ">=" OR operator = ">") Then
        compareVersionArrays = False
    Else
        compareVersionArrays = True
    End If
End Function
'- End file: endpoint_libs/endpoint-library-checks.vbs
'- Begin file: utils/get-tanium-registry-path.vbs
' get-tanium-registry-path.vbs

'GetTaniumRegistryPath works in x64 or x32
'looks for a valid Path value

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
'- End file: utils/get-tanium-registry-path.vbs
'- Begin file: utils/os/GetOSMajorVersion.vbs
' Used to return just the first 2 digits of the Windows version
' be aware that it is returned as string with "X.Y", not a number

' To include this file, copy/paste: INCLUDE=utils/os/GetOSMajorVersion.vbs


Function GetOSMajorVersion
    Dim strVersion,arrVersion
    
    strVersion = GetOSVersion()

    arrVersion = Split(strVersion,".")
    If UBound(arrVersion) >= 1 Then
        strVersion = arrVersion(0)&"."&arrVersion(1)
    End If

    GetOSMajorVersion = strVersion
End Function 'GetOSMajorVersion
'- End file: utils/os/GetOSMajorVersion.vbs
'- Begin file: utils/os/GetOSVersion.vbs
' Used to return the full version number on Windows

' To include this file, copy/paste: INCLUDE=utils/os/GetOSVersion.vbs


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
