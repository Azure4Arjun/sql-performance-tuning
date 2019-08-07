strComputer = "." 
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2") 
Set colItems = objWMIService.ExecQuery( _
    "SELECT * FROM Win32_DiskPartition",,48) 
'Wscript.Echo "-----------------------------------"
'Wscript.Echo "Win32_DiskPartition instance"
For Each objItem in colItems 
    Wscript.Echo "DiskIndex: " & objItem.DiskIndex & "  -- Name: " & objItem.Name & "  --  StartingOffset: " & objItem.StartingOffset /1024
Next
