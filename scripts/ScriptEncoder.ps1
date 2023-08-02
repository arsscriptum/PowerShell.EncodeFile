


<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


class EncodedDataFile {
    [UInt64]$ScriptSize
    [byte[]]$ScriptBytes
    [Int16]$ScriptFilePathLength
    [string]$ScriptFilePath
    [Int16]$ScriptFileNameLength
    [string]$ScriptFileName
    [UInt64]$DataSize
    [byte[]]$DataBytes
    [Int16]$DataFilePathLength
    [string]$DataFilePath
    [Int16]$DataFileNameLength
    [string]$DataFileName

    EncodedDataFile(){
        $this.ScriptBytes = $Null 
        $this.DataBytes = $Null 
        $this.DataSize = 0 
        $this.ScriptSize = 0 
        $this.ScriptFilePath = ''
        $this.ScriptFileName = ''
        $this.DataFilePath = ''
        $this.DataFileName = ''
    }
    <#
        .Synopsis
            Save a data file
        .Description
            After the files were serialized, save the data file with this function
        .Parameter Path
            data file Path
    #>
    [bool]Save([string]$Path) { 
        try{
            [System.IO.FileStream]$fs = [System.IO.FileStream]::new($Path, ([System.IO.FileMode]::Create))
            [System.IO.BinaryWriter]$bw = [System.IO.BinaryWriter]::new($fs)
            
            [byte[]]$ScriptBytesBuffer = [byte[]]::new($this.ScriptSize)
            [byte[]]$DataBytesBuffer = [byte[]]::new($this.DataSize)
            $this.ScriptBytes.CopyTo($ScriptBytesBuffer,0)
            $this.DataBytes.CopyTo($DataBytesBuffer,0)
            
            $bw.Write($this.ScriptSize -as [UInt64]) # int 
            $bw.Write($ScriptBytesBuffer)
            $bw.Write($this.DataSize -as [UInt64]) # int 
            $bw.Write($DataBytesBuffer)
            $bw.Write($this.ScriptFilePath)
            $bw.Write($this.ScriptFileName)
            $bw.Write($this.DataFilePath)
            $bw.Write($this.DataFileName)
            $bw.Close()
            $Success = $True
        }catch{
            $Success = $False
            Write-Warning "$_"
        }  
        return $Success
    }

    <#
        .Synopsis
            Load a data file
        .Description
            Load a data file, copy bytes in this class member variables, bbytes are still compressed, extract files with Deserialize()
        .Parameter Path
            data file Path
    #>
    [bool]Load([string]$Path) {
        try{
            [System.IO.FileStream]$fs = [System.IO.FileStream]::new($Path, ([System.IO.FileMode]::Open))
            [System.IO.BinaryReader]$br = [System.IO.BinaryReader]::new($fs)
            [int]$num_script_bytes = $br.ReadUInt64()
            $this.ScriptBytes = [byte[]]::new($num_script_bytes)
            $this.ScriptSize = $num_script_bytes
            $this.ScriptBytes = $br.ReadBytes($num_script_bytes)
            [int]$num_data_bytes = $br.ReadUInt64()
            $this.DataBytes = [byte[]]::new($num_data_bytes)
            $this.DataSize = $num_data_bytes
            $this.DataBytes = $br.ReadBytes($num_data_bytes)
            $this.ScriptFilePath = $br.ReadString() 
            $this.ScriptFileName = $br.ReadString()
            $this.DataFilePath = $br.ReadString()
            $this.DataFileName = $br.ReadString()
            $br.Close()
            $Success = $True
        }catch{
            $Success = $False
            Write-Warning "$_"
        }  
        return $Success
    }
    <#
        .Synopsis
            Serialize 2 files in the current object
        .Description
            Compress the script file bytes and data file bytes, copy bytes in this class member variables
        .Parameter ScriptPath
            Script file Path
        .Parameter DataFilePath
            Data file Path
    #>
    [void]Serialize([string]$ScriptPath,[string]$DataFilePath) {
        
        Write-Debug "[Serialize] `"$ScriptPath`""
        Write-Debug "[Serialize] `"$DataFilePath`""
        [PsCustomObject]$ret = $this.FileToCompressedByteArray($ScriptPath)
        $this.ScriptBytes = [byte[]]::new($ret.size) 
        $this.ScriptSize = $ret.size
        $ret.data.CopyTo($this.ScriptBytes,0)
        $this.ScriptFilePath = $ScriptPath
        $this.ScriptFileName = (Get-Item "$ScriptPath").Name

        [PsCustomObject]$ret = $this.FileToCompressedByteArray($DataFilePath)
        $this.DataBytes = [byte[]]::new($ret.size) 
        $this.DataSize = $ret.size
        $ret.data.CopyTo($this.DataBytes,0)
        $this.DataFilePath = $DataFilePath
        $this.DataFileName = (Get-Item "$DataFilePath").Name
    }

    <#
        .Synopsis
            Deserialize the current data in this object in 2 files, written in $Path
        .Description
            Decompress the script file bytes and data file bytes, save the files in the given path
        .Parameter Path
            Directory where  files are extracted
    #>
    [void]Deserialize() {
        try{
            if([string]::IsNullOrEmpty($Path)){
                $Path = (Get-Location).Path
            }
            Write-Host "[Deserialize] `"$Path`"" -f Red
            if(-not(Test-Path $Path)){ $Null = mkdir $Path -Force -EA Ignore }
            [string]$ScriptString = $this.DecompressBytes($this.ScriptBytes)
            [string]$ScriptLocalFile = "{0}" -f $this.ScriptFilePath
            
            Set-Content -Path $ScriptLocalFile -Value $ScriptString -Encoding utf8 -Force

            [string]$DataString = $this.DecompressBytes($this.DataBytes)
            [string]$DataLocalFile = "{0}" -f $this.DataFilePath
            
            Set-Content -Path $DataLocalFile -Value $DataString -Encoding utf8 -Force
        }catch{
            Write-Error "$_"
        }  
    }
    [void]DeserializeTo([string]$Path) {
        try{
            if([string]::IsNullOrEmpty($Path)){
                $Path = (Get-Location).Path
            }
            Write-Host "[Deserialize] `"$Path`"" -f Red
            if(-not(Test-Path $Path)){ $Null = mkdir $Path -Force -EA Ignore }
            [string]$ScriptString = $this.DecompressBytes($this.ScriptBytes)
            [string]$ScriptLocalFile = "{0}\{1}" -f "$Path", $this.ScriptFileName
            
            Set-Content -Path $ScriptLocalFile -Value $ScriptString -Encoding utf8 -Force

            [string]$DataString = $this.DecompressBytes($this.DataBytes)
            [string]$DataLocalFile = "{0}\{1}" -f "$Path", $this.DataFileName
            
            Set-Content -Path $DataLocalFile -Value $DataString -Encoding utf8 -Force
        }catch{
            Write-Error "$_"
        }  
    }
    <#
        .Synopsis
            Get a String representation of the class
    #>
    [string]ToString() {
        $ret_str = @"
ScriptFile Size   = {0} bytes
ScriptBytes Count = {1} 
DataFile Size     = {2} bytes
DataBytes Count   = {3} 
ScriptFilePath    = {4} 
ScriptFileName    = {5} 
DataFilePath      = {6} 
DataFileName      = {7} 
"@ -f $this.ScriptSize , $this.ScriptBytes.Count, $this.DataSize , $this.DataBytes.Count, $this.ScriptFilePath, $this.ScriptFileName, $this.DataFilePath, $this.DataFileName
        return $ret_str
    }

    [void]Dump() {
        $s = $this.ToString()
        Write-Host "$s" -f Red
    }


    [PsCustomObject]FileToCompressedByteArray([string]$Path) {
        try{
            Write-Debug "[FileToCompressedByteArray] $Path"
            $FileData = Get-Content -Path $Path -Raw -Encoding 'UTF8'
            # Script block as String to Byte array
            [System.Text.Encoding] $Encoding = [System.Text.Encoding]::UTF8
            [Byte[]] $ScriptBlockEncoded = $Encoding.GetBytes($FileData)

            # Compress Byte array (gzip)
            [System.IO.MemoryStream] $MemoryStream = New-Object System.IO.MemoryStream
            $GzipStream = New-Object System.IO.Compression.GzipStream $MemoryStream, ([System.IO.Compression.CompressionMode]::Compress)
            $GzipStream.Write($ScriptBlockEncoded, 0, $ScriptBlockEncoded.Length)
            $GzipStream.Close()
            $MemoryStream.Close()
            $ScriptBlockCompressed = $MemoryStream.ToArray()
            $len = $ScriptBlockCompressed.Count
            
            $Ret = [PsCustomObject]@{
                data = $ScriptBlockCompressed
                size = $len
            }
            return $Ret
            
        }catch{
            [string]$Ret = $Null
            Write-Error "$_"
        }  
        return $Ret
    }
    [string]DecompressBytes([byte[]]$data){
        try{
            Write-Debug "[DecompressBytes] Size $($data.Count)" 
            # Decompress data
            $InputStream = New-Object System.IO.MemoryStream(, $data)
            $MemoryStream = New-Object System.IO.MemoryStream
            $GzipStream = New-Object System.IO.Compression.GzipStream $InputStream, ([System.IO.Compression.CompressionMode]::Decompress)
            $GzipStream.CopyTo($MemoryStream)
            $GzipStream.Close()
            $MemoryStream.Close()
            $InputStream.Close()
            [Byte[]] $ScriptBlockEncoded = $MemoryStream.ToArray()

            # Byte array to String
            [System.Text.Encoding] $Encoding = [System.Text.Encoding]::UTF8
            [string]$Ret = $Encoding.GetString($ScriptBlockEncoded)
            
        }catch{
            [string]$Ret = $Null
            Write-Error "$_"
        }  
        return $Ret
    }
}




function New-EncodedFile { 
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,
        [Parameter(Mandatory=$true)]
        [string]$DataFilePath
    ) 

    Try{
       $ec = [EncodedDataFile]::new()
        Write-Verbose "Create encoded file with `n - `"$ScriptPath`"`n - `"$DataFilePath`""
        $Null = $ec.Serialize("$ScriptPath","$DataFilePath")
        
        $SavedDataFile = "$ScriptPath" += '.encoded'
        $SaveSuccess = $ec.Save($SavedDataFile)
        Write-Verbose "Saved with $SavedDataFile => $SaveSuccess"
        
        return $SavedDataFile

    }catch{
        Write-Error $_ 
    }
}

function Restore-EncodedFiles { 
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$false)]
        [string]$DestinationPath,
        [Parameter(Mandatory=$false)]
        [switch]$OverwriteOriginalFiles
    ) 

    Try{
        $ec = [EncodedDataFile]::new()
        $LoadSuccess = $ec.Load($Path)
        Write-Verbose "Loaded $Path => $LoadSuccess"
        if($OverwriteOriginalFiles){
            $Null = $ec.Deserialize()
        }else{
            if([string]::IsNullOrEmpty($Path) -eq $True){
                $DestinationPath = (Get-Location).Path
            }
            $Null = $ec.DeserializeTo("$DestinationPath")
        }
    }catch{
        Write-Error $_ 
    }
}