function New-GUI {
    param(
        $xaml
    )
    try {
        $TypeDefinition = Get-Content $PSScriptRoot\TypeDefinition.cs -Raw
    
        Add-Type -TypeDefinition $TypeDefinition -ReferencedAssemblies @("System.Management.Automation", "Microsoft.CSharp", "System.Web.Extensions")

        [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    }
    catch {}
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml)) 

    $Form = [Windows.Markup.XamlReader]::Load($reader)

    return $Form     
}

function Set-GUIWebBrowserContent {
    param (
        $Html,
        $Form
    )

    $WebBrowser = $Form.FindName("WebBrowser")

    if ($Runspace) {
        $WebBrowser.ObjectForScripting = [PowerShellHelper]::new($Runspace)
    }
    else {
        $WebBrowser.ObjectForScripting = [PowerShellHelper]::new()
    }

    $WebBrowser.NavigateToString($Html)
}

function Start-MyGUI {
    $html = Get-Content $PSScriptRoot\GUI.html -Raw
    $module = Get-Content $PSScriptRoot\APIFunctions.psm1 -Raw
    $html = $html.replace("{0}",$module)
    $xaml = Get-Content $PSScriptRoot\Window.xaml -Raw
    $form = New-GUI -xaml $xaml
    Set-GUIWebBrowserContent -html $html -form $form

    $Form.ShowDialog() | out-null
}