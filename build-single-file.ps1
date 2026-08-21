param(
  [string]$Source = 'index-final.html',
  [string]$Output = 'final/index-final.html'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourcePath = Join-Path $root $Source
$outputPath = Join-Path $root $Output
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Read-Utf8([string]$path) {
  return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Get-DataUri([string]$relativePath, [switch]$OptimizePhoto) {
  $decoded = [Uri]::UnescapeDataString($relativePath.Replace('/', [IO.Path]::DirectorySeparatorChar))
  $absolute = Join-Path $root $decoded
  if (-not (Test-Path -LiteralPath $absolute)) { throw "Arquivo não encontrado: $relativePath" }

  $extension = [IO.Path]::GetExtension($absolute).ToLowerInvariant()
  if ($OptimizePhoto -and @('.png', '.jpg', '.jpeg') -contains $extension) {
    $image = [Drawing.Image]::FromFile($absolute)
    try {
      $maxSide = 1280
      $scale = [Math]::Min(1.0, $maxSide / [double][Math]::Max($image.Width, $image.Height))
      $width = [Math]::Max(1, [int][Math]::Round($image.Width * $scale))
      $height = [Math]::Max(1, [int][Math]::Round($image.Height * $scale))
      $bitmap = New-Object Drawing.Bitmap($width, $height, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
      try {
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        try {
          $graphics.Clear([Drawing.Color]::FromArgb(24, 26, 28))
          $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
          $graphics.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
          $graphics.DrawImage($image, 0, 0, $width, $height)
        } finally { $graphics.Dispose() }
        $stream = New-Object IO.MemoryStream
        try {
          $codec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
          $parameters = New-Object Drawing.Imaging.EncoderParameters(1)
          $parameters.Param[0] = New-Object Drawing.Imaging.EncoderParameter([Drawing.Imaging.Encoder]::Quality, [long]82)
          $bitmap.Save($stream, $codec, $parameters)
          return 'data:image/jpeg;base64,' + [Convert]::ToBase64String($stream.ToArray())
        } finally { $stream.Dispose() }
      } finally { $bitmap.Dispose() }
    } finally { $image.Dispose() }
  }

  $mime = switch ($extension) {
    '.png' { 'image/png' }
    '.jpg' { 'image/jpeg' }
    '.jpeg' { 'image/jpeg' }
    default { 'application/octet-stream' }
  }
  return "data:$mime;base64," + [Convert]::ToBase64String([IO.File]::ReadAllBytes($absolute))
}

$html = Read-Utf8 $sourcePath
$html = $html.Replace('content="width=device-width, initial-scale=1.0"', 'content="width=device-width, initial-scale=1.0, viewport-fit=cover"')
$cssFiles = @('styles-corte-contorno.css', 'styles-lona.css', 'brand.css')
$css = ($cssFiles | ForEach-Object { Read-Utf8 (Join-Path $root $_) }) -join "`n"

# Use fontes nativas equivalentes para que o catálogo não dependa da internet.
$css += "`n:root{--display:'Arial Narrow','Avenir Next Condensed',sans-serif;--body:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;--mono:'SFMono-Regular',Consolas,monospace}`n"
$css += @'
html,body{width:100%;max-width:100%;overflow-x:hidden}
img{max-width:100%;height:auto}
.modal{position:fixed;z-index:9999;opacity:0;visibility:hidden;pointer-events:none;transition:opacity .2s ease,visibility .2s ease}
.modal.open{opacity:1;visibility:visible;pointer-events:auto}
.fallback-card{min-width:0;border-right:1px solid var(--line);border-bottom:1px solid var(--line);background:var(--panel);color:#fff;overflow:hidden}
.fallback-card img{display:block;width:100%;height:auto;aspect-ratio:auto;object-fit:contain;background:#202326}
.fallback-card .card-info{display:block}
@media(max-width:720px){
  .hero,.catalog-shell,.process,footer,.detail-panel,.detail-content{max-width:100%}
  .hero{min-height:auto}
  .hero-machine{height:auto;min-height:0;overflow:visible}
  .hero-machine img{height:auto;object-fit:contain}
  .card-image{aspect-ratio:auto;height:auto}
  .card-image img{height:auto;object-fit:contain}
  .detail-panel{height:100%;height:100svh;height:100dvh;transform:none;opacity:0;visibility:hidden;transition:opacity .2s ease,visibility .2s ease}
  .modal.open .detail-panel{opacity:1;visibility:visible}
  .detail-visual{position:relative;height:auto;min-height:0}
  .detail-visual img{display:block;width:100%;height:auto;max-height:none;object-fit:contain}
  .color-ruler{position:absolute}
}
'@
$html = [regex]::Replace($html, '(?is)\s*<link[^>]+(?:fonts\.googleapis|fonts\.gstatic|cdnjs\.cloudflare)[^>]*>', '')
$html = [regex]::Replace($html, '(?is)\s*<link rel="preconnect"[^>]*>', '')
foreach ($file in $cssFiles) {
  $escaped = [regex]::Escape($file)
  $html = [regex]::Replace($html, ('(?is)\s*<link rel="stylesheet" href="' + $escaped + '">'), '')
}
$html = $html.Replace('</head>', "  <style>`n$css`n  </style>`n</head>")

$logoUri = Get-DataUri 'logo-acnatural-web.png'
$machineUri = Get-DataUri 'maquina.jpeg'
$html = $html.Replace('src="logo-acnatural-web.png"', ('src="' + $logoUri + '"'))
$html = $html.Replace('src="maquina.jpeg"', ('src="' + $machineUri + '"'))

$script = Read-Utf8 (Join-Path $root 'app-corte-contorno.js')
$imageMatches = [regex]::Matches($script, "image:'([^']+)'")
$imagePaths = $imageMatches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$imageUris = @{}
foreach ($imagePath in $imagePaths) {
  $uri = Get-DataUri $imagePath -OptimizePhoto
  $imageUris[$imagePath] = $uri
  $script = $script.Replace("image:'$imagePath'", "image:'$uri'")
}

# Conteúdo real de fallback: o catálogo continua visível e legível sem JavaScript.
$fallbackCards = New-Object Text.StringBuilder
$materialMatches = [regex]::Matches((Read-Utf8 (Join-Path $root 'app-corte-contorno.js')), "\{name:'([^']+)'[^}]*?label:'([^']+)'[^}]*?image:'([^']+)'")
foreach ($material in $materialMatches) {
  $name = [Net.WebUtility]::HtmlEncode($material.Groups[1].Value)
  $label = [Net.WebUtility]::HtmlEncode($material.Groups[2].Value)
  $imagePath = $material.Groups[3].Value
  $uri = $imageUris[$imagePath]
  [void]$fallbackCards.Append(('<article class="fallback-card"><img src="{0}" alt="{1}"><div class="card-info"><small>{2}</small><h3>{1}</h3></div></article>' -f $uri, $name, $label))
}
$fallback = '<noscript>' + $fallbackCards.ToString() + '</noscript>'
$html = $html.Replace('<div class="material-grid" id="materialGrid"></div>', '<div class="material-grid" id="materialGrid">' + $fallback + '</div>')

$html = $html.Replace('<i class="fa-regular fa-envelope" aria-hidden="true"></i>', '<i aria-hidden="true">✉</i>')
$html = $html.Replace('<i class="fa-brands fa-whatsapp" aria-hidden="true"></i>', '<i aria-hidden="true">●</i>')
$html = $html.Replace('<script src="app-corte-contorno.js"></script>', "<script>`n$script`n</script>")

$outputDirectory = Split-Path -Parent $outputPath
[IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
[IO.File]::WriteAllText($outputPath, $html, $utf8)

$sizeMb = [Math]::Round((Get-Item -LiteralPath $outputPath).Length / 1MB, 2)
Write-Output "Criado: $outputPath ($sizeMb MB)"
