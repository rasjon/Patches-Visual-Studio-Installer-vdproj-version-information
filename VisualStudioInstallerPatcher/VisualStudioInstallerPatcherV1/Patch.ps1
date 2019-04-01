param
(
    [Parameter()]
    [string]
    $Version = (Get-VstsInput -Name 'Version' -Require),

    [Parameter()]
    [string]
    $Sourcefiles = (Get-VstsInput -Name 'Sourcefiles' -Require)
)
Trace-VstsEnteringInvocation $MyInvocation

If ($DeploymentType -eq 'Agent')
{
    
}
$scriptBlock = {
    $filename = $args[0]
    Write-Output "Patching [$filename]"

	Try{
		$productCodePattern     = '\"ProductCode\" = \"8\:{([\d\w-]+)}\"'
		$packageCodePattern     = '\"PackageCode\" = \"8\:{([\d\w-]+)}\"'
		$productVersionPattern  = '\"ProductVersion\" = \"8\:[0-9]+(\.([0-9]+)){1,3}\"'
		$productCode            = '"ProductCode" = "8:{' + [guid]::NewGuid().ToString().ToUpper() + '}"'
		$packageCode            = '"PackageCode" = "8:{' + [guid]::NewGuid().ToString().ToUpper() + '}"'
		$productVersion         = '"ProductVersion" = "8:' + $Version.ToString(3) + '"'

		(Get-Content $filename) | ForEach-Object {
			% {$_ -replace $productCodePattern, $productCode } |
			% {$_ -replace $packageCodePattern, $packageCode } |
			% {$_ -replace $productVersionPattern, $productVersion }
		} | Set-Content $filename
	}
	Catch{
		Write-Error "Unable to patch [$filename] confirm the vdproj file is present." -ErrorAction Stop
	}
}

$invokeCommandSplat = @{
    ScriptBlock = $scriptBlock
}
If($credential)
{
    $invokeCommandSplat.Credential = $credential
    $invokeCommandSplat.ComputerName = $machines
}
Invoke-Command @invokeCommandSplat -ArgumentList $Sourcefiles
Trace-VstsLeavingInvocation $MyInvocation