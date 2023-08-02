

<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


$EncodedFileClassScript = (Resolve-Path "$PSScriptRoot\scripts\ScriptEncoder.ps1").Path
. "$EncodedFileClassScript"

function Test-NewTestFiles([string]$Path) {
    if(-not(Test-Path $Path)){ $Null = mkdir $Path -Force -EA Ignore }
    $BigScriptPath = "$Path\BigScript.ps1"
    $BigDataFilePath = "$Path\DataFile.txt"
    Set-Content -Path $BigScriptPath -Value ([string]::new('a',8096))
    Set-Content -Path $BigDataFilePath -Value ([string]::new('z',16192))
    $o = [PsCustomObject]@{
        data = $BigDataFilePath
        script = $BigScriptPath
    }
    return $o
}

function Start-EncodeTest {

    [PsCustomObject]$TestFiles = Test-NewTestFiles -Path "$PSScriptRoot\test"

    Write-Host "[New-EncodedFile] using `n - `"$($TestFiles.script)`"`n - `"$($TestFiles.data)`"" -f DarkYellow
    $SavedDataFile = New-EncodedFile -ScriptPath "$($TestFiles.script)" -DataFilePath "$($TestFiles.data)"

    $Null = Remove-Item -Path @("$($TestFiles.script)","$($TestFiles.data)") -Recurse -Verbose -Force -ErrorAction Ignore
                
    $Files = Restore-EncodedFiles -Path $SavedDataFile -OverwriteOriginalFiles
    Write-Host "[New-EncodedFile] Restored:" -f DarkYellow
    $Files.ForEach({
        Write-Host " - `"$($_)`"`n" -f Cyan -n
    })

    $Null = mkdir "$PSScriptRoot\out" -Force -EA Ignore
    $Files = Restore-EncodedFiles -Path $SavedDataFile -DestinationPath "$PSScriptRoot\out"
    Write-Host "[New-EncodedFile] Restored:" -f DarkYellow
    $Files.ForEach({
        Write-Host " - `"$($_)`"`n" -f Cyan -n
    })
}

Start-EncodeTest 

Read-Host "Press a Key to Continue, terminate the test and delete the files...."

$Null = Remove-Item -Path @("$PSScriptRoot\out", "$PSScriptRoot\test","$($TestFiles.script)","$($TestFiles.data)") -Recurse -Verbose -Force -ErrorAction Ignore