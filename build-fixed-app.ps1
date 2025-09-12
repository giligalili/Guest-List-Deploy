# build-fixed-app.ps1 - Build the Guest List API with HTML frontend

Write-Host "🚀 Building Guest List API with HTML Frontend" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# Check if required files exist
$requiredFiles = @("guestlist-server-fixed.py", "index.html", "requirements-fixed.txt", "Dockerfile-fixed")
$missingFiles = @()

foreach ($file in $requiredFiles) {
    if (!(Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ Error: Missing required files:" -ForegroundColor Red
    $missingFiles | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    exit 1
}

# Build the Docker image
$imageTag = "ver04-html-fixed"
$imageName = "giligalili/guestlistapi:$imageTag"

Write-Host "🐳 Building Docker image: $imageName" -ForegroundColor Blue
docker build -f Dockerfile-fixed -t $imageName .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Docker image built successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎯 Next steps:" -ForegroundColor Yellow
    Write-Host "1. Push the image:" -ForegroundColor White
    Write-Host "   docker push $imageName" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Update your terraform.tfvars.local:" -ForegroundColor White
    Write-Host "   app_image = `"$imageName`"" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Apply the changes:" -ForegroundColor White
    Write-Host "   terraform apply -var-file=`"terraform.tfvars.local`"" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. Wait for rollout:" -ForegroundColor White
    Write-Host "   kubectl rollout status deployment/guestlist-deployment -n guestlist-dev" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Your app will then be available with the HTML interface!" -ForegroundColor Green
} else {
    Write-Host "❌ Docker build failed!" -ForegroundColor Red
    exit 1
}
