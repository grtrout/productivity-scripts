$distroName = "Ubuntu"
$myName = "greg"
$destFilePath = "C:\WSLBackup\"
$theDate = (Get-Date).ToString("yyyy-MM-dd")
$7zipPath = "$env:ProgramFiles\7-Zip\7z.exe"
$fullFilePath = "$destFilePath\$distroName-$myName-$theDate"
Set-Alias 7zip $7zipPath

echo "Exporting WSL distro $distroName to $fullFilePath"
wsl --export $distroName "$fullFilePath.tar"
echo "Export to $fullFilePath.tar completed"

echo "Preparing to compress $fullFilePath.tar using 7zip"
7zip a "$fullFilePath.tar.7z" "$fullFilePath.tar"
rm "$fullFilePath.tar"
echo "$fullFilePath.tar.7z created; deleted original $fullFilePath.tar"
echo "WSL distro $distroName has been successfully backed up and compressed"