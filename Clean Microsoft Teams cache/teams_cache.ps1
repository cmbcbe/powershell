Write-Host "Closing Teams"  
try{ 
	if (Get-Process -ProcessName Teams -ErrorAction SilentlyContinue) {  
	Get-Process -ProcessName Teams | Stop-Process -Force 
	Start-Sleep -Seconds 3 
	Write-Host "Teams sucessfully closed"  
}else{ 
	Write-Host "Teams is already closed"  
} 
}catch{ 
	echo $_ 
} 

Write-Host "Clearing Teams cache"  
try{ 
	Get-ChildItem -Path "C:\Users\*\AppData\Roaming\Microsoft\Teams\Service Worker\CacheStorage" | Remove-Item -Recurse -Confirm:$false 
	Write-Host "Teams cache removed"  
}catch{ 
	echo $_ 
} 

Write-Host "Cleanup complete.... Launch Teams" 
