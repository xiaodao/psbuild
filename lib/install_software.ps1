$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. $scriptDir\util.ps1
. $scriptDir\path.ps1
ls $scriptDir\softwares -filter install_* | % { . $_.FullName }

Function Install-Software($software){
	Prepare-Repo
	Given-Software-Supported $software {
		if (iex "$software-Installed"){
			Write-Host "$software is already installed on this computer, will by pass installation"
			return 
		}
		
		iex "Download-$software"
		iex "Silent-Install-$software"
		Wait-For-Software-Install $software

		$endingAction = Get-Command -Module ChefDotNet | % { $_.Name } | ? { $_ -eq "Execute-Ending-Action-For-$software" }
		if ($endingAction) {
		    iex "Execute-Ending-Actions-For-$software"	
        }
	}
}

Function Given-Software-Supported ($software, [ScriptBlock] $block) {
	If(!(Software-Supported($software))) {
		Write-Host
		Write-Host -fore yellow "The software - $software isn't supported, we only support the softwares listed below: "
		Write-Host
		Supported-Softwares | % { Write-Host -fore green " " $_}
		Write-Host
		return
	}
	& $block
}

Function Software-Supported($software) {
	Supported-Softwares | ? {$_ -eq $software}
}

Function Supported-Softwares {
	ls -path "$scriptDir\softwares" -filter *.ps1 | % { $_.Name} | % {($_ -split "install_(.*).ps1", 0, "RegexMatch")[1]}
}

Function Wait-For-Software-Install($software) {
	$seconds = [int](Get-InstallTime($software))
	Write-Host "$software is installing." -NoNewLine

	while (!(iex "$software-Installation-Completed")) {
		Sleep 1
		$seconds--
		Write-Host "." -NoNewLine
		if ($seconds -eq 0) { exit -1 }
	}

	Write-Host "."
	Write-Host "$software installation finished."
}

Function Get-InstallTime($software) {
	Get-Content "$scriptDir/softwares/supported_software" | ? { $_.StartsWith($software) } | % { $_.Split(";")[1].Trim() }
}

Function Prepare-Repo {
	$repo = "$home/.psbuild_repo"
	if (-not (Test-Path "$repo")) {
		mkdir $repo
	} 
}
