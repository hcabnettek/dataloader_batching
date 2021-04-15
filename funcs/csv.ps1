
function splitCSV([string]$src, [string]$outFolder, [string]$pre) {

  Write-Host "Attempting splitting $src"
  # Read parent CSV
  $InputFilename = Get-Content $src
  $OutputFilenamePattern = ($pre + "_slice_")
  $LineLimit = 995

  # Initialize
  $line = 0
  $i = 0
  $file = 0
  $start = 0

  # Loop all text lines
  while ($line -le $InputFilename.Length) {
    Write-Host "while splitting $src"
    # Generate child CSVs
    if ($i -eq $LineLimit -Or $line -eq $InputFilename.Length) {
      $file++
      $Filename = "$OutputFilenamePattern$file.csv"
      $InputFilename[$start..($line-1)] | Out-File $outFolder\$Filename -Force
      $start = $line;
      $i = 0
      Write-Host "if splitting $src"
      Write-Host "$Filename"
    }

  # Increment counters
    $i++;
    $line++
  }
}
