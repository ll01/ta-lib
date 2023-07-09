$downloadUrl = "https://netix.dl.sourceforge.net/project/ta-lib/ta-lib/0.4.0/ta-lib-0.4.0-msvc.zip"
$tempZipPath = "$env:TEMP\ta-lib.zip"
$extractPath = "$env:TEMP\ta-lib"

# Download the TA-Lib zip file
Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZipPath

# Extract the contents of the zip file
Expand-Archive -Path $tempZipPath -DestinationPath $extractPath -Force

# Move the extracted files to a desired location
$destinationPath = "C:\Program Files\TA-Lib"
Move-Item -Path (Join-Path $extractPath "ta-lib") -Destination $destinationPath -Force

# Add the TA-Lib binary directory to the system PATH
$env:Path = "$($destinationPath);$($env:Path)"

# Clean up temporary files
Remove-Item -Path $tempZipPath -Force
Remove-Item -Path $extractPath -Recurse -Force

# Verify installation
ta-lib | Select-Object -First 1