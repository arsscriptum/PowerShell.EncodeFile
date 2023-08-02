

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


function Test-NewEncodedObject([string]$ScriptPath,[string]$DataFilePath) {

    $ec = [EncodedDataFile]::new()
    Write-Host "Create with $ScriptPath, $DataFilePath" -f DarkYellow
    $Null = $ec.Serialize("$ScriptPath","$DataFilePath")
    $Null = mkdir "$PSScriptRoot\out" -Force -EA Ignore
    $SavedDataFile = "$PSScriptRoot\out\encoded_file.data"
    $SaveSuccess = $ec.Save($SavedDataFile)
    Write-Host "Saved with $SavedDataFile => $SaveSuccess" -f DarkYellow
    #$ec.Dump()
    return $SavedDataFile
}

function Test-ReadEncodedObject([string]$SavedDataFile) {


    $ec = [EncodedDataFile]::new()
    $LoadSuccess = $ec.Load($SavedDataFile)
    Write-Host "Loaded $SavedDataFile => $LoadSuccess" -f DarkYellow
    $Null = $ec.Deserialize("$PSScriptRoot\Deserialized")
}

[PsCustomObject]$TestFiles = Test-NewTestFiles 

$SavedDataFile = Test-NewEncodedObject -ScriptPath "$($TestFiles.script)" -DataFilePath "$($TestFiles.data)"
$SavedDataFile 
#Test-ReadEncodedObject -Path $SavedDataFile