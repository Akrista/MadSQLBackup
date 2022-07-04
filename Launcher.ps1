<#
.NOTES
    Autor: Jorge Thomas @akrista
    Linktree: https://linktr.ee/akrista
    Version 0.0.1
#>

#Add in the frameworks so that we can create the WPF GUI
Add-Type -AssemblyName presentationframework, presentationcore


#Create empty hashtable into which we will place the GUI objects
$wpf = @{ }


#Grab the content of the Visual Studio xaml file as a string
$inputXML = Get-Content -Path ".\MainWindow.xaml"

Clear-Host
$inputXML

Clear-Host
$firstItem = $inputXML | select-object -first 1
$firstItem.gettype().Fullname


#clean up xml there is syntax which Visual Studio 2015 creates which PoSH can't understand
$inputXMLClean = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace 'x:Class=".*?"', '' -replace 'd:DesignHeight="\d*?"', '' -replace 'd:DesignWidth="\d*?"', ''

Clear-Host
$inputXMLClean


#change string variable into xml
[xml]$xaml = $inputXMLClean

Clear-Host
$xaml.GetType().Fullname


#read xml data into xaml node reader object
$reader = New-Object System.Xml.XmlNodeReader $xaml

#create System.Windows.Window object
$tempform = [Windows.Markup.XamlReader]::Load($reader)

$tempform.ShowDialog()