

<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


$EncodedFileClassScript = (Resolve-Path "$PSScriptRoot\scripts\ScriptEncoder.ps1").Path
. "$EncodedFileClassScript"

function Test-NewTestFiles() {

    $Path = "$PSScriptRoot\test"
    if(-not(Test-Path $Path)){ $Null = mkdir $Path -Force -EA Ignore }
    $BigScriptPath = "$Path\BigScript.ps1"
    $BigDataFilePath = "$Path\DataFile.txt"
    Set-Content -Path $BigScriptPath -Value ([string]::new('a',8096))
    Write-Host "Wrote `"$BigScriptPath`" " -f DarkYellow
    Set-Content -Path $BigDataFilePath -Value ([string]::new('z',16192))
    Write-Host "Wrote `"$BigDataFilePath`" " -f DarkYellow
    $o = [PsCustomObject]@{
        data = $BigDataFilePath
        script = $BigScriptPath
    }
    return $o
}




[PsCustomObject]$TestFiles = Test-NewTestFiles 

$SavedDataFile = New-EncodedFile -ScriptPath "$($TestFiles.script)" -DataFilePath "$($TestFiles.data)"
$Null = mkdir "$PSScriptRoot\out" -Force -EA Ignore
Restore-EncodedFiles -Path $SavedDataFile -DestinationPath "$PSScriptRoot\out"
Restore-EncodedFiles -Path $SavedDataFile -OverwriteOriginalFiles