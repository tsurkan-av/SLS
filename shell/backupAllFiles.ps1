$slsIP = "192.168.1.247"
$tokenSLS=""
$pathBackup = ".\_back\" + (Get-Date).ToString("yyyyMMdd_HHmm") + "\"
$fileSLSBackup = "backup_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".sls"
$url = $slsIP + "/api/storage?token=" + $tokenSLS + "&path=/"
md $pathBackup
# bacup all Files
$result = wget $url
if ($result.StatusCode -eq 200) {
	$data = ConvertFrom-Json $([String]::new($result.Content))
	$data.result | % {
		if ($_.is_dir -eq $false) {
			wget $($url + $_.name) -OutFile $($pathBackup + $_.name)
			$_.name
		}
	}
} else {
	Write-Host "Error request for Files: $($result.StatusCode)"
}
# native backup
$url = $slsIP + "/api/backup?token=" + $tokenSLS + "&action=create&config=1&zigbee=1"
$result = wget -Uri $url -Method Post -OutFile $($pathBackup + $fileSLSBackup)
if ((Test-Path -Path $($pathBackup + $fileSLSBackup) -PathType Leaf) -ne $false) {
	$fileSLSBackup
} else {
	Write-Host "Error request for native backup: File Not Found"
}