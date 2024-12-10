param(
	[int]$MaximumProfileAge = 60 # Profiles older than this will be deleted
)

$version = "v2.0 - Cedric MARCOUX - 26/06/2024";

Function LogWrite
{
    Param ([string]$logstring);
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss");
    $Line = "$Stamp - $logstring";
    $LogName=[io.path]::GetFileNameWithoutExtension("$($MyInvocation.PSCommandPath)");
    $LogFile = "$PSScriptRoot\logs\$($LogName).txt";
    $LogPath =Split-Path -Path $LogFile;
    if (Test-Path -path $LogPath)
    {
        Add-content $Logfile -value $Line;
    } else
    {
        New-Item -path "$PSScriptRoot\logs" -type directory | Out-Null;
        Add-content $Logfile -value $Line;
    }
}

function log($message)   { write-host -foregroundcolor green $message;Logwrite($message)}  
function error($message) { write-host -foregroundcolor magenta $message;Logwrite($message) }

clear;
Log "CleanProfiles version: $version";
$FreespaceBeforeStart=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
$FreespaceBefore=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;

#The list of accounts, for which profiles must not be deleted
$ExcludedUsers ="Public","Default","svc"
$ProfileDeleted = 0;

$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem;

$obj = Get-WMIObject -class Win32_UserProfile | Where {(!$_.Special -and $_.Loaded -eq $false )}

$output = @()
foreach ($littleobj in $obj) {
	if (!($ExcludedUsers -like $littleobj.LocalPath.Replace("C:\Users\",""))) {
		$lastwritetime = (Get-ChildItem -Path "$($littleobj.localpath)\AppData\Local\Microsoft\Windows\UsrClass.dat" -Force ).LastWriteTime
		if ($lastwritetime -lt (Get-Date).AddDays(-$MaximumProfileAge)) {
			$ProfileDeleted++;
			$littleobj | Remove-WmiObject;
			$output += [PSCustomObject]@{
				'LocalPath' = $littleobj.LocalPath
				'LastUseTime' = $litteobj.LastUseTime
				'LastWriteTime' = $lastwritetime
				'RemovedSID' = $littleobj.SID
			}
			try { remove-item -path "$littleobj.LocalPath" -Force -Recurse -ErrorAction SilentlyContinue; }  catch {$null = $_ }
		}
	}
}
if ($ProfileDeleted -eq 0) 
{
	Error "Sorry, no profile to delete within $MaximumProfileAge days"
} else {
	Log ($output | Sort LocalPath | ft | Out-String -Width 4096);
	$FreespaceAfter=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
	$FreeSpaceGainedAfterProfilesGB=[math]::round(($FreespaceAfter-$FreespaceBefore) / 1GB, 2)
	Log "Free space gained with profiles deletation: $FreeSpaceGainedAfterProfilesGB GB";
}

Log "Cleaning Temp directory of current user, free space gained:";
$FreespaceBefore=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
try { Remove-Item -Path $env:temp\* -Recurse -Force -ErrorAction SilentlyContinue; } catch {$null = $_ }
$FreespaceAfter=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
$FreeSpaceGainedAfterProfileTempGB=[math]::round(($FreespaceAfter-$FreespaceBefore) / 1GB, 2)
Log "$FreeSpaceGainedAfterProfileTempGB GB";

$FreespaceBefore=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
Log "Cleaning others temp, free space gained:"
$tempfolders = @(
"C:\Temp\*",
"C:\Tmp\*",
"C:\Windows\Temp\*",
"C:\Windows\Prefetch\*",
"C:\Documents and Settings\*\Local Settings\temp\*",
"C:\Users\*\Appdata\Local\Temp\*"
);
try { Remove-Item $tempfolders -force -recurse -ErrorAction SilentlyContinue; } catch {$null = $_ }
$FreespaceAfter=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
$FreeSpaceGainedAfterOthersTempGB=[math]::round(($FreespaceAfter-$FreespaceBefore) / 1GB, 2)
Log "$FreeSpaceGainedAfterOthersTempGB GB";

$FreespaceBefore=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
Log "Cleaning mini dumps and memory dump, free space gained:"
$minidumps = @(
"C:\Windows\Minidump\*",
"C:\Windows\MEMORY.DMP"
);
try { Remove-Item $minidumps -force -recurse -ErrorAction SilentlyContinue; } catch {$null = $_ }
$FreespaceAfter=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
$FreeSpaceGainedAfterDUMPSGB=[math]::round(($FreespaceAfter-$FreespaceBefore) / 1GB, 2)
Log "$FreeSpaceGainedAfterDUMPSGB GB";


$FreespaceBefore=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
Log "Cleaning crash dumps, free space gained:"
$crashdumpfolders = @(
"c:\Crashdumps\*"
);
try { Remove-Item $crashdumpfolders -force -recurse -ErrorAction SilentlyContinue; } catch {$null = $_ }
$FreespaceAfter=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
$FreeSpaceGainedAfterCrashDumpsGB=[math]::round(($FreespaceAfter-$FreespaceBefore) / 1GB, 2)
Log "$FreeSpaceGainedAfterCrashDumpsGB GB";

$FreespaceBefore=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
Log "Emptying recycle.bin, free space gained:"
$objShell = New-Object -ComObject Shell.Application;
$objFolder = $objShell.Namespace(0xA) ;
$objFolder.items() | %{ remove-item $_.path -Recurse -Confirm:$false} ;
$FreespaceAfter=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
$FreeSpaceGainedAfterRecycleGB=[math]::round(($FreespaceAfter-$FreespaceBefore) / 1GB, 2)
Log "$FreeSpaceGainedAfterRecycleGB GB";

$FreespaceBefore=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
Log "Cleaning knowntemp file, free space gained:"
$knownexts = @(
"*.tmp",
"*._mp",
"*.gid",
"*.chk",
"*.old",
"*.bak"
);
try { Remove-Item 'C:\*' -force -Recurse -Include $knownexts -Confirm:$false -ErrorAction SilentlyContinue; } catch {$null = $_ }
$FreespaceAfter=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
$FreeSpaceGainedAfterTempFilesGB=[math]::round(($FreespaceAfter-$FreespaceBefore) / 1GB, 2)
Log "$FreeSpaceGainedAfterTempFilesGB GB";


$FreespaceBefore=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
Log "Cleaning known folders, free space gained:"
$tempfolders = @(
"C:\nvidia\*",
"C:\amd\*",
"C:\intel\*",
"C:\System.sav\*",
"C:\Logs\*",
"C:\PerfLogs\*",
"C:\Windows\Downloaded Program Files\*",
"C:\Windows\LiveKernelReports\*",
"C:\swsetup\*"
);
try { Remove-Item $tempfolders -force -recurse -ErrorAction SilentlyContinue; } catch {$null = $_ }
$FreespaceAfter=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
$FreeSpaceGainedAfterKnownFoldersGB=[math]::round(($FreespaceAfter-$FreespaceBefore) / 1GB, 2)
Log "$FreeSpaceGainedAfterKnownFoldersGB GB";


$FreespaceAfter=Get-Volume -DriveLetter C | Select-Object -Property SizeRemaining -ExpandProperty SizeRemaining;
$FreeSpaceGained=$FreespaceAfter-$FreespaceBeforeStart;
$FreeSpaceGainedGB=[math]::round($FreeSpaceGained / 1GB, 2)
Log "Total Free space gained: $FreeSpaceGainedGB GB";
