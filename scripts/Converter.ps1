


<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>



######################################################################################################################
#
# TOOLS : BELOW, YOU WILL FIND MISC TOOLS RELATED TO THE PSAUTOUPDATE SCRIPT. WHEN IN THE GUI YOU ARE CALLING 
#         FUNCTION, IT WILL BE ASSOCIATED TO A FUNCTION HERE.
#
# FUNCTIONS:  
#             - ConvertTo-HeaderBlock
#             - ConvertFrom-HeaderBlock
#             - Convert-ToSmallerArray
#
######################################################################################################################



################################################################################################
# PATHS VARIABLES and DEFAULTS VALUES
################################################################################################



$Global:StartTag = "=== BEGIN EMBEDDED FILE HEADER ==="
$Global:EndTag  = "=== END EMBEDDED FILE HEADER ==="
$Global:HeaderStart = "<# $Global:StartTag `n"
$Global:HeaderEnd = "`n$Global:EndTag #>"   

Function Convert-Base64ToBytes([string]$base64) {
    [string]$padded = ''
    if (($base64.Length % 4) -eq 0) {
        $padded = $base64.Clone()
    }else {
        $padded = $base64 + "====".Substring($base64.Length % 4)
    }
     
    $base64 = $padded.Replace("_", "/").Replace("-", "+")
    return [System.Convert]::FromBase64String($base64)
}

Function Convert-Base64ToString([string]$base64) {
    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64))
}

Function Convert-StringToBase64([string]$plain) {
    return Convert-BytesToBase64([Text.Encoding]::UTF8.GetBytes($plain))
}


Function Convert-BytesToBase64([byte[]]$ByteArray) {
    return [Convert]::ToBase64String($ByteArray)
}


Function Compress-ByteArray([byte[]]$ByteArray, [bool]$IsBinary) {
    # Compress Byte array (gzip)Encoding 'UTF8'

    [System.IO.MemoryStream]$CompressedMemoryStream = new-object System.IO.MemoryStream(,$ByteArray)
    [System.IO.Compression.GzipStream]$GzipStream = [System.IO.Compression.GzipStream]::new($CompressedMemoryStream, ([System.IO.Compression.CompressionMode]::Compress))
    #$GzipStream.Write($BinaryMemoryStream.GetBuffer(), 0, $BinaryMemoryStream.GetBuffer().Count)
    $GzipStream.Write($ByteArray,0,$ByteArray.Count)
    $GzipStream.Close()
   
    $ScriptBlockCompressed = $CompressedMemoryStream.ToArray()
    return $ScriptBlockCompressed
}

Function Expand-CompressedBytes([byte[]]$CompressedBytes) {
    $InputStream = New-Object System.IO.MemoryStream(, $CompressedBytes)
    $MemoryStream = New-Object System.IO.MemoryStream
    $GzipStream = New-Object System.IO.Compression.GzipStream $InputStream, ([System.IO.Compression.CompressionMode]::Decompress)
    $GzipStream.CopyTo($MemoryStream)

    [Byte[]]$DecompressedByteArray = $MemoryStream.ToArray()

    $GzipStream.Close()
    $MemoryStream.Close()
    $InputStream.Close()
    $DecompressedByteArray
}



function Get-ContentBytes{ 
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [parameter(Mandatory=$true,Position=0)]
        [string]$Path,
        [parameter(Mandatory=$false,Position=1)]
        [Int64]$Count=0
    )
    if($PSVersionTable.PSEdition -eq 'Core'){
        if($Count -ne 0){
            return ((Get-Content -Path "$Path" -AsByteStream -TotalCount $Count) -As [byte[]])
        }else{
            return ((Get-Content -Path "$Path" -AsByteStream) -As [byte[]])
        }
    }else{
        if($Count -ne 0){
            return ((Get-Content -Path "$Path" -Encoding Byte -TotalCount $Count) -As [byte[]])
        }else{
            return ((Get-Content -Path "$Path" -Encoding Byte) -As [byte[]])
        }
        
    }

}


<#
    .Synopsis
        get the type of encoding for the target file. 
    .Description
        get the type of encoding for the target file. 
    .Parameter Path
        the target file
    .Notes 
        Returns one of those:
        - binary : binary file
        - ascii: Uses the encoding for the ASCII (7-bit) character set.
        - bigendianunicode: Encodes in UTF-16 format using the big-endian byte order.
        - bigendianutf32: Encodes in UTF-32 format using the big-endian byte order.
        - unicode: Encodes in UTF-16 format using the little-endian byte order.
        - utf8: Encodes in UTF-8 format.
        - utf32: Encodes in UTF-32 format.
#>
function Get-FileEncoding{ 

    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [parameter(Mandatory=$true,Position=0)]
        [string]$Path
    )

    # This should be ASCII encoded 
    $encoding = "ASCII"

    # Get the first 1024 bytes from the file
    $byteArray = Get-ContentBytes -Path $Path -Count 1024

    if( ("{0:X}{1:X}{2:X}" -f $byteArray) -eq "EFBBBF" ){
        # Test for UTF-8 BOM
        $encoding = "utf8"
    }elseif( ("{0:X}{1:X}" -f $byteArray) -eq "FFFE" ){
        # Test for the UTF-16
        $encoding = "unicode"
    }elseif( ("{0:X}{1:X}" -f $byteArray) -eq "FEFF" ){
        # Test for the UTF-16 Big Endian
        $encoding = "bigendianunicode"
    }elseif( ("{0:X}{1:X}{2:X}{3:X}" -f $byteArray) -eq "FFFE0000" ){
        # Test for the UTF-32
        $encoding = "utf32"
    }elseif( ("{0:X}{1:X}{2:X}{3:X}" -f $byteArray) -eq "0000FEFF" ){
        # Test for the UTF-32 Big Endian
        $encoding = "bigendianutf32"
    }

    # So now we're done with Text encodings that commonly have '0's
    # in their byte steams.  ASCII may have the NUL or '0' code in
    # their streams but that's rare apparently.

    # Both GNU Grep and Diff use variations of this heuristic

    if( $byteArray -contains 0 ){
        $encoding = "binary"
    }

    return $encoding
}


function Convert-ToSmallerArray {
<#
    .Synopsis
        Convert an array in a group of smaller arrays
    .Description
        Convert an array in a group of smaller arrays, with the user specifying number of parts and parts size
    .Parameter BigArray
        The array to convert
    .Parameter NumParts
        number of parts
    .Parameter RequestedSize
        Requested Size
#>
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory=$true,Position=0)]
            [Array]$BigArray,
            [Parameter(Mandatory=$false)]
            [int]$NumParts = 0,
            [Parameter(Mandatory=$false)]
            [int]$RequestedSize=0
        )

    if ($NumParts -lt 1) { $NumParts = 1 }
    if ($RequestedSize -lt 1) { $RequestedSize = 1 }

    if ($NumParts -gt 1) {
        $PartSize = [Math]::Ceiling($BigArray.count / $NumParts)
        Write-Verbose "ToSmallerArray => NumParts is $NumParts"
    }
    if ($RequestedSize -gt 1) {
        $PartSize = $RequestedSize
        $NumParts = [Math]::Ceiling($BigArray.count / $RequestedSize)
        Write-Verbose "ToSmallerArray => RequestedSize is $RequestedSize"
        Write-Verbose "ToSmallerArray => NumParts is $NumParts"
    }

    $ReturnedArray = @()
    for ($i=1; $i -le $NumParts; $i++) {
        $start = (($i-1)*$PartSize)
        $end = (($i)*$PartSize) - 1
        if ($end -ge $BigArray.count) {$end = $BigArray.count}
        $ReturnedArray+=,@($BigArray[$start..$end])
    }
    return ,$ReturnedArray
}



function ConvertFrom-HeaderBlock {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "File or folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Leaf) ){
                throw "The Path argument must be a file. Directory paths are not allowed."
            }
            return $true 
        })]
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Path
        
    )

    Write-Verbose "[ConvertFrom-HeaderBlock] `"$Path`" Type $Type"
    [string]$FileStringData = Get-Content -Path "$Path" -Encoding utf8
    $index = $FileStringData.IndexOf($Global:StartTag)
    $endindex = $FileStringData.IndexOf($Global:EndTag)
    $index += 34

    [char[]] $CArray = $FileStringData.ToCharArray() 
    $iMax = $CArray.Count

    Write-Verbose "index $index "
    Write-Verbose "endindex $endindex "
    Write-Verbose "iMax $iMax "

    For($i = $index ; $i -lt $endindex ; $i++){
        if(($CArray[$i] -ne ' ') -and ($CArray[$i])){
            [char]$c = $CArray[$i]
            $CompleteString += $c
        }
    }

    $CompleteStringLen = $CompleteString.Length
    Write-Verbose "[ConvertFrom-HeaderBlock]  CompleteString Length $CompleteStringLen"
    [byte[]]$ScriptBlockCompressed = Convert-Base64ToBytes($CompleteString)
    [Byte[]]$ScriptBlockEncoded = Expand-CompressedBytes -CompressedBytes $ScriptBlockCompressed
   
    $HeaderSize = 1 + 8 + 8

    [System.IO.MemoryStream]$MemoryStream = [System.IO.MemoryStream]::new($ScriptBlockEncoded)   
    [System.IO.BinaryReader]$BinaryReader = [System.IO.BinaryReader]::new($MemoryStream)
    [bool]$IsBinary = $BinaryReader.ReadBoolean()
    [UInt64]$DataBufferSize = $BinaryReader.ReadUInt64()
    [Byte[]]$PlaceHolder = $BinaryReader.ReadBytes(8)
    [Byte[]]$RawByteArray = $BinaryReader.ReadBytes($DataBufferSize)

    Write-Verbose "[ConvertFrom-HeaderBlock]  ScriptBlock Compressed Size $($ScriptBlockCompressed.Count)"
    Write-Verbose "[ConvertFrom-HeaderBlock]  ScriptBlock Expanded   Size $($ScriptBlockEncoded.Count)"
    Write-Verbose "[ConvertFrom-HeaderBlock]  IsBinary               $IsBinary"
    Write-Verbose "[ConvertFrom-HeaderBlock]  DataBufferSize         $DataBufferSize"

    if($IsBinary -eq $False){
        # Byte array to String
        [System.Text.Encoding] $Encoding = [System.Text.Encoding]::UTF8
        [string]$s = $Encoding.GetString($RawByteArray)
        return $s
    }

    return $RawByteArray 
}



function ConvertTo-HeaderBlock {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "File or folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Leaf) ){
                throw "The Path argument must be a file. Directory paths are not allowed."
            }
            return $true 
        })]
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Path,
        [Parameter(Mandatory=$false)]
        [uint32]$SizeSections = 65
        
    )
    $HeaderSize = 1 + 8 + 8
    [bool]$IsBinary = ((Get-FileEncoding -Path $Path ) -eq 'binary')
    [Byte[]]$ScriptBlockEncoded = Get-ContentBytes -Path $Path
    $ScriptBlockEncodedSize = $ScriptBlockEncoded.Count
    $BufferSize = $ScriptBlockEncodedSize + $HeaderSize
    [Byte[]]$Buffer = [Byte[]]::new($BufferSize)

    Write-Verbose "[ConvertTo-HeaderBlock] `"$Path`" Binary $IsBinary"

    [System.IO.MemoryStream]$MemoryStream = [System.IO.MemoryStream]::new($Buffer,$True)   
    [System.IO.BinaryWriter]$BinaryWriter = [System.IO.BinaryWriter]::new($MemoryStream)
 
   
    $BinaryWriter.Write($IsBinary -as [bool]) # 1
    $BinaryWriter.Write($ScriptBlockEncodedSize -as [UInt64]) # 8
    [byte[]]$PlaceHolder = [byte[]]::new(8)
    $BinaryWriter.Write($PlaceHolder)
    $BinaryWriter.Write($ScriptBlockEncoded)
    $BinaryWriter.Close()
    
    [Byte[]]$DataWithHeader = $MemoryStream.ToArray()

    [Byte[]]$ScriptBlockCompressed = Compress-ByteArray -ByteArray $DataWithHeader -IsBinary $IsBinary
    [string]$ScriptBase64 = Convert-BytesToBase64($ScriptBlockCompressed)

    Write-Verbose "[ConvertTo-HeaderBlock]  ScriptBlock Compressed Size $($ScriptBlockCompressed.Count)"
    Write-Verbose "[ConvertTo-HeaderBlock]  ScriptBlock Expanded   Size $($ScriptBlockEncoded.Count)"
    Write-Verbose "[ConvertTo-HeaderBlock]  ScriptBlock Base 64    Size $($ScriptBase64.Length)"
    
    [char[]] $CArray = $ScriptBase64.ToCharArray() 
    $Parts = Convert-ToSmallerArray -BigArray $CArray -RequestedSize $SizeSections
    Write-Verbose "[ConvertTo-HeaderBlock]  Convert-ToSmallerArray RequestedSize $SizeSections"
    [string]$HeaderData =  $Global:HeaderStart
    $Parts | % { $HeaderData += "$_`n" }
    $HeaderData += $Global:HeaderEnd

    return $HeaderData
}



function Split-HeaderBlockData {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Data,
        [Parameter(Mandatory=$false)]
        [uint32]$SizeSections = 80
        
    )
    [String]$NewDataString = $Data.Clone()
    $l = $Global:HeaderStart.Length + 1
    $s = 0
    $oldSubStr = $NewDataString.Substring($s, $l)
    $newSubStr = $oldSubStr.Replace("`n","")
    $NewDataString = $NewDataString.Replace($oldSubStr, $newSubStr)

    $s = $NewDataString.Length - $Global:HeaderEnd.Length + 1
    $l = $Global:EndTag.Length + 1
    $oldSubStr = $NewDataString.Substring($s, $l)
    $newSubStr = $oldSubStr.Replace("`n","")
    $NewDataString = $NewDataString.Replace($oldSubStr, $newSubStr)
    [string]$TmpTagStart = $Global:StartTag.Replace("`n","")
    [string]$TmpTagEnd = $Global:EndTag.Replace("`n","")
    [String]$NewDataString = $NewDataString.Replace("$TmpTagStart","$TmpTagStart`n`n").Replace("$TmpTagEnd","`n$TmpTagEnd")             


    $Max = [math]::Max($($Global:StartTag.Length),$($Global:EndTag.Length))
    $Max += 10
    if($SizeSections -lt $Max){$SizeSections = $Max}

    $s = $Global:HeaderStart.Length + 1
    [string]$TmpTagStart = $Global:HeaderStart.Replace("`n","")
    [string]$TmpTagEnd = $Global:HeaderEnd.Replace("`n","")
    $l = $NewDataString.Length - ($Global:HeaderStart.Length + 1) - ($Global:HeaderEnd.Length)
    $MiddleString = $NewDataString.Replace("`n","").Replace("$TmpTagStart","").Replace("$TmpTagEnd","")   
    
    $char_array = $MiddleString.ToCharArray()
    $FinalValue = ''
    $count = 0
    ForEach($c in $char_array){
        if($count -lt $SizeSections){
            $count++
            $FinalValue += $c
        }else{
            $count = 0
            $FinalValue += "`n"
            $FinalValue += $c
        }
    }

    $FinalValue = "{0}`n{1}`n{2}" -f $Global:HeaderStart, $FinalValue, $Global:HeaderEnd
    $FinalValue
}


