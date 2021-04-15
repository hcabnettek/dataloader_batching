using namespace System.Collections.Generic
param ($inputdirectory, $dataloaderpath)

. .\funcs\common_funcs.ps1
. .\funcs\csv.ps1

$dataloader = "$dataloaderpath\bin\process.bat"
$dlconfig = "$inputdirectory\dataloaderconfig"
$dlLogFolder = "$inputdirectory\Logs\" 
$dataToImport = "$inputdirectory\data"
set-location "$dataloaderpath\bin\"

$conf = "$dlconfig\process-conf.xml"
Remove-Item "$dlLogFolder*.*"
Remove-Item $conf
$jobs = [List[string]]::new()

[xml]$xmlDoc = New-Object system.Xml.XmlDocument
$xmlDoc.LoadXml("<!DOCTYPE beans PUBLIC `"-//SPRING//DTD BEAN//EN`" `"http://www.springframework.org/dtd/spring-beans.dtd`"><beans></beans>")

<# $maxRows = 995
Get-ChildItem -Path $dataToImport -Filter *.csv | 

  ForEach-Object {
    $InputFilename = Get-Content $_.FullName
    Write-Host "Length is " + $InputFilename.Length
    if($InputFilename.Length -ge $maxRows) {
      splitCSV $_.FullName $dataToImport $_.BaseName
      Rename-Item -Path $_.FullName -NewName ($_.FullName+".this_file_was_split")
    }
  } #>

Get-ChildItem -Path $dataToImport -Name -Filter *.csv | 

ForEach-Object {

  $jobs.Add($_)
  
  $bean = $xmlDoc.CreateNode('element', 'bean', '')
  $bean.SetAttribute('id', $_)
  $bean.SetAttribute('class', 'com.salesforce.dataloader.process.ProcessRunner')
  $bean.SetAttribute('scope', 'singleton')

  $description = $xmlDoc.CreateNode('element','description','')
  $description.InnerText = $_
  $prop1 = $xmlDoc.CreateNode('element','property','')
  $prop1.SetAttribute('name', 'name')
  $prop1.SetAttribute('value', $_)

  $prop2 = $xmlDoc.CreateNode('element','property','')
  $prop2.SetAttribute('name', 'configOverrideMap')
  $map = $xmlDoc.CreateNode('element','map','')

  $entry1 = $xmlDoc.CreateNode('element','entry','')
  $entry1.SetAttribute('key', 'sfdc.entity')
  $entry1.SetAttribute('value', 'Attachment')

  $entry2 = $xmlDoc.CreateNode('element','entry','')
  $entry2.SetAttribute('key', 'process.operation')
  $entry2.SetAttribute('value', 'insert')

  $entry3 = $xmlDoc.CreateNode('element','entry','')
  $entry3.SetAttribute('key', 'process.mappingFile')
  $entry3.SetAttribute('value', "$inputdirectory\maps\map_attachment.sdl")

  $entry4 = $xmlDoc.CreateNode('element','entry','')
  $entry4.SetAttribute('key', 'process.outputError')
  New-Item -itemType File -Path "$inputdirectory\Logs" -Name ("error_$_")
  $entry4.SetAttribute('value', "$inputdirectory\Logs\error_$_")

  $entry5 = $xmlDoc.CreateNode('element','entry','')
  $entry5.SetAttribute('key', 'process.outputSuccess')
  New-Item -itemType File -Path "$inputdirectory\Logs" -Name ("success_$_")
  $entry5.SetAttribute('value', "$inputdirectory\Logs\success_$_")

  $entry6 = $xmlDoc.CreateNode('element','entry','')
  $entry6.SetAttribute('key', 'dataAccess.name')
  $entry6.SetAttribute('value', "$inputdirectory\Data\$_")

  $entry7 = $xmlDoc.CreateNode('element','entry','')
  $entry7.SetAttribute('key', 'dataAccess.type')
  $entry7.SetAttribute('value', 'csvRead')

  $map.AppendChild($entry1)
  $map.AppendChild($entry2)
  $map.AppendChild($entry3)
  $map.AppendChild($entry4)
  $map.AppendChild($entry5)
  $map.AppendChild($entry6)
  $map.AppendChild($entry7)

  $prop2.AppendChild($map)

  $bean.AppendChild($description)
  $bean.AppendChild($prop1)
  $bean.AppendChild($prop2)

  $xmlDoc.LastChild.AppendChild($bean)
  
  $xmlDoc.save($conf)

}

$jobs.ForEach({
  param ($x)
  Write-Host "Processing file $x"
  & $dataloader $dlconfig $x 
  CheckErrorFile ("{0}error_$x" -f $dlLogFolder) 
})
