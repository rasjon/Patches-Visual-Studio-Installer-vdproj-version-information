param
(  
	[Parameter()]
    [string]
    $Sourcefolder = (Get-VstsInput -Name 'Sourcefolder' -Require),

	[Parameter()]
    [version]
    $Version = (Get-VstsInput -Name 'Version' -Require)
)
Trace-VstsEnteringInvocation $MyInvocation

If ($DeploymentType -eq 'Agent')
{
    
}

Function Patch-File
{
	param([string]$filepath)

	Write-Output "Patching $filepath"

	Try{
		$productCodePattern     = '\"ProductCode\" = \"8\:{([\d\w-]+)}\"'
		$packageCodePattern     = '\"PackageCode\" = \"8\:{([\d\w-]+)}\"'
		$productVersionPattern  = '\"ProductVersion\" = \"8\:[0-9]+(\.([0-9]+)){1,3}\"'
		$productCode            = '"ProductCode" = "8:{' + [guid]::NewGuid().ToString().ToUpper() + '}"'
		$packageCode            = '"PackageCode" = "8:{' + [guid]::NewGuid().ToString().ToUpper() + '}"'
		$productVersion         = '"ProductVersion" = "8:' + $Version.ToString(3) + '"'

		(Get-Content $filepath) | ForEach-Object {
			% {$_ -replace $productCodePattern, $productCode } |
			% {$_ -replace $packageCodePattern, $packageCode } |
			% {$_ -replace $productVersionPattern, $productVersion }
		} | Set-Content $filepath
	}
	Catch{
		Write-Error "Unable to patch [$filepath] confirm the vdproj file is present." -ErrorAction Stop
	}
}

Function Start-Patching
{
	$regex = "\d{1,2}.\d{1,2}.\d{1,4}"

	If(!($Version -match $regex))
	{
		Write-Error "Version number is invalid, must be of format '##.##.####'" -ErrorAction Stop
	}

    Write-Output "Starting patching for source folder [$Sourcefolder]"

    $files = Get-Childitem -Path $Sourcefolder -Include *.vdproj -Recurse		

	ForEach ($file in $files) {        
		Patch-File -filepath $file
	}
}

Start-Patching
Trace-VstsLeavingInvocation $MyInvocation