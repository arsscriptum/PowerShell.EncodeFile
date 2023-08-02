<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


[CmdletBinding(SupportsShouldProcess)]
Param (
    [parameter(Mandatory=$False, HelpMessage="This argument is for development purposes only. It help for testing.")]
    [switch]$TestMode
)

$ConverterScript = (Resolve-Path "$PsScriptRoot\Converter.ps1").Path
. "$ConverterScript"



[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

 function ConvertTo-BitmapImage {
    [CmdletBinding(SupportsShouldProcess)]
      param(
          [Parameter(Position = 0, Mandatory = $true)]
          [byte[]]$ByteArray,
          [Parameter(Position = 1, Mandatory = $True)]
          [ValidateSet("Bmp", "Emf", "Exif", "Gif", "Icon", "Jpeg", "MemoryBmp", "Png", "Tiff", "Wmf")]
          [string]$ImageType
      )

    [System.Drawing.Imaging.ImageFormat]$Format = [System.Drawing.Imaging.ImageFormat]::$ImageType

    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing
    [System.Drawing.Bitmap]$bmp = [System.Drawing.Bitmap]::FromStream((New-Object System.IO.MemoryStream (@(, $ByteArray))))
    $memory = New-Object System.IO.MemoryStream
    $null = $bmp.Save($memory, $Format)
    $memory.Position = 0
    $img = New-Object System.Windows.Media.Imaging.BitmapImage
    $img.BeginInit()
    $img.StreamSource = $memory
    $img.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $img.EndInit()
    $img.Freeze()

    $memory.Close()

    $img
  }


function Show-ImageTestDialog {
    [CmdletBinding(SupportsShouldProcess)]
    param()


    try{
        Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

        [xml]$xaml = @"

<Window
            xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
            xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
            xmlns:local="clr-namespace:WpfApp10"
            Title="Embedded Image DEMO Tool" Height="463.632" Width="476.995" ResizeMode="NoResize" Topmost="True" WindowStartupLocation="CenterScreen">

    <Grid>
        <Image Name='ImageVariable' HorizontalAlignment="Left" Height="419" VerticalAlignment="Top" Width="469" Margin="0,0,0,-58"/>
        <Label Name='Url' Content='by http://arsscriptum.github.io' HorizontalAlignment="Left" Margin="10,70,0,0" VerticalAlignment="Top" Foreground="Gray" Cursor='Hand' ToolTip='https://arsscriptum.github.io/blog/embedding-resources-in-script/'/>
        <Button Name='DoneDialog' Content="Done" HorizontalAlignment="Left" Margin="361,378,0,0" VerticalAlignment="Top" Height="23" Width="75" RenderTransformOrigin="0.161,14.528"/>
    </Grid>
</Window>

"@ 


        $Reader = (New-Object System.Xml.XmlNodeReader $xaml)  
        $Form = [Windows.Markup.XamlReader]::Load($reader)  
        $Script:SimulationOnly = $False
        #AutoFind all controls 
        $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")  | ForEach-Object {  
            $VarName = $_.Name
            Write-Host "[RShow-ResetPermissionsDialog] New Gui Variable => $VarName. Scope: Script"
            New-Variable  -Name $_.Name -Value $Form.FindName($_.Name) -Force -Scope Script 
        }

        $ProcessFiles = $False
        $ProcessDirectories = $True


        $oldErrorAcion = $ErrorActionPreference

        try{
            $ErrorActionPreference = 'Stop'
            $CurrentScriptName = $MyInvocation.MyCommand.Name
            $CurrentScript = "$PSScriptRoot\Test-ShowImageDialog.ps1"
            Write-Host "Loading `"$CurrentScript`""
            [byte[]]$ImageBytes = ConvertFrom-HeaderBlock $CurrentScript -Verbose

            if($ImageBytes -ne $Null){
                $ImageSourceData = ConvertTo-BitmapImage $ImageBytes "Jpeg"
                $ImageVariable.Source = $ImageSourceData 
            } 
            
        }catch{
            Write-Warning "$_"
        }

        $ErrorActionPreference = $oldErrorAcion

        $Url.Add_MouseLeftButtonUp({ &"start" "https://arsscriptum.github.io/blog/embedding-resources-in-script/"})
        $Url.Add_MouseEnter({$Url.Foreground = 'DarkGray'})
        $Url.Add_MouseLeave({$Url.Foreground = 'LightGray'})

     
        $DoneDialog.Add_Click({
            [void]$Form.Close()
        })

        [void]$Form.ShowDialog() 

    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }

}

Show-ImageTestDialog  -Verbose
