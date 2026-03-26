$libPath = "c:\Users\Obède NIZIGIYIMANA\PFE\frontend\lib"
Get-ChildItem -Path $libPath -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $newContent = $content -replace '\$API_URL', '$apiUrl'
    Set-Content $_.FullName $newContent
    Write-Host "Fixed: $($_.Name)"
}
