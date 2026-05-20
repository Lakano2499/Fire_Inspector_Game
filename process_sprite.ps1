Add-Type -AssemblyName System.Drawing
$srcPath = "assets\LOADINGTRUCK-sheet.png"
if (-Not (Test-Path $srcPath)) {
    Write-Host "Source file not found!"
    exit 1
}
$src = [System.Drawing.Image]::FromFile($srcPath)

# Frame size is 250x250. We want to cut out the bottom 50px for the text.
$frameW = 250
$frameH = 200
$newW = 8 * $frameW
$dst = New-Object System.Drawing.Bitmap($newW, $frameH)
$g = [System.Drawing.Graphics]::FromImage($dst)

# Make background transparent
$g.Clear([System.Drawing.Color]::Transparent)

# Matrix for 50% opacity
$cm = New-Object System.Drawing.Imaging.ColorMatrix
$cm.Matrix33 = 0.5
$ia = New-Object System.Drawing.Imaging.ImageAttributes
$ia.SetColorMatrix($cm)

for ($i = 0; $i -lt 4; $i++) {
    $nextI = ($i + 1) % 4
    
    $srcRect1 = New-Object System.Drawing.Rectangle($i * $frameW, 0, $frameW, $frameH)
    $srcRect2 = New-Object System.Drawing.Rectangle($nextI * $frameW, 0, $frameW, $frameH)
    
    # 1. Draw original frame
    $dstX1 = ($i * 2) * $frameW
    $dstRect1 = New-Object System.Drawing.Rectangle($dstX1, 0, $frameW, $frameH)
    $g.DrawImage($src, $dstRect1, $srcRect1.X, $srcRect1.Y, $srcRect1.Width, $srcRect1.Height, [System.Drawing.GraphicsUnit]::Pixel)
    
    # 2. Draw blended frame
    $dstX2 = ($i * 2 + 1) * $frameW
    $dstRect2 = New-Object System.Drawing.Rectangle($dstX2, 0, $frameW, $frameH)
    # First draw base frame (current frame) at 100%
    $g.DrawImage($src, $dstRect2, $srcRect1.X, $srcRect1.Y, $srcRect1.Width, $srcRect1.Height, [System.Drawing.GraphicsUnit]::Pixel)
    # Then draw next frame over it at 50%
    $g.DrawImage($src, $dstRect2, $srcRect2.X, $srcRect2.Y, $srcRect2.Width, $srcRect2.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)
}

$dstPath = "assets\LOADINGTRUCK-sheet_smooth.png"
$dst.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$dst.Dispose()
$src.Dispose()
Write-Host "Successfully generated 8-frame sprite sheet without text."
