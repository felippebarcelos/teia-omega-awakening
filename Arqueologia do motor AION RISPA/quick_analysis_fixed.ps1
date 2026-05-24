# === robust parse de OrigBytes / CompressedBytes ===
$origBytes = $null
$compBytes = $null
foreach ($candName in @('OrigBytes','OriginalBytes','orig_bytes','origBytes')) {
  if ($null -eq $origBytes -and $raw.PSObject.Properties.Name -contains $candName) {
    $origBytes = ToDouble $raw."$candName"
  }
}
foreach ($candName in @('CompressedBytes','Compressed','compBytes','compressed_bytes')) {
  if ($null -eq $compBytes -and $raw.PSObject.Properties.Name -contains $candName) {
    $compBytes = ToDouble $raw."$candName"
  }
}
if ($origBytes -eq $null) { $origBytes = ExtractNumeric $raw }
if ($compBytes -eq $null) { $compBytes = ExtractNumeric $raw.CompressedBytes }
if ($origBytes -is [bool]) { $origBytes = $origBytes ? 1.0 : 0.0 }
if ($compBytes -is [bool]) { $compBytes = $compBytes ? 1.0 : 0.0 }

# === robust parse de OrigBytes / CompressedBytes ===
$origBytes = $null
$compBytes = $null
foreach ($candName in @('OrigBytes','OriginalBytes','orig_bytes','origBytes')) {
  if ($null -eq $origBytes -and $raw.PSObject.Properties.Name -contains $candName) {
    $origBytes = ToDouble $raw."$candName"
  }
}
foreach ($candName in @('CompressedBytes','Compressed','compBytes','compressed_bytes')) {
  if ($null -eq $compBytes -and $raw.PSObject.Properties.Name -contains $candName) {
    $compBytes = ToDouble $raw."$candName"
  }
}
if ($origBytes -eq $null) { $origBytes = ExtractNumeric $raw }
if ($compBytes -eq $null) { $compBytes = ExtractNumeric $raw.CompressedBytes }
if ($origBytes -is [bool]) { $origBytes = $origBytes ? 1.0 : 0.0 }
if ($compBytes -is [bool]) { $compBytes = $compBytes ? 1.0 : 0.0 }
