# quick-fix.ps1 - Update service port to fix connectivity issue

Write-Host "🔧 Fixing Load Balancer port configuration..." -ForegroundColor Cyan
Write-Host "Issue: Service port was 80, should be 9999 to match original design" -ForegroundColor Yellow
Write-Host ""

# Check if kubectl is configured
try {
    kubectl get nodes | Out-Null
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Write-Host "❌ kubectl not configured. Run:" -ForegroundColor Red
    Write-Host "aws eks update-kubeconfig --region us-west-2 --name guestlist-sivan" -ForegroundColor White
    exit 1
}

Write-Host "📋 Current service configuration:" -ForegroundColor Cyan
kubectl get service guestlist-service -n guestlist-dev -o wide

Write-Host ""
Write-Host "🔧 Applying Terraform changes to fix port..." -ForegroundColor Cyan
terraform apply -var-file="terraform.tfvars.local" -auto-approve

Write-Host ""
Write-Host "⏳ Waiting for load balancer to update (this may take 2-3 minutes)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "📋 Updated service configuration:" -ForegroundColor Cyan
kubectl get service guestlist-service -n guestlist-dev -o wide

Write-Host ""
Write-Host "🌐 Getting load balancer URL..." -ForegroundColor Cyan
$LB_HOST = kubectl get service guestlist-service -n guestlist-dev -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

if (![string]::IsNullOrEmpty($LB_HOST)) {
    Write-Host "✅ Load Balancer URL: http://$LB_HOST:9999" -ForegroundColor Green
    Write-Host ""
    Write-Host "🧪 Testing API endpoints:" -ForegroundColor Cyan
    
    Write-Host "Testing root endpoint..." -ForegroundColor White
    try {
        $response = Invoke-WebRequest -Uri "http://$LB_HOST:9999/" -UseBasicParsing -TimeoutSec 10
        Write-Host "✅ Root endpoint responded: $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Root endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "Testing /guests endpoint..." -ForegroundColor White
    try {
        $response = Invoke-WebRequest -Uri "http://$LB_HOST:9999/guests" -UseBasicParsing -TimeoutSec 10
        Write-Host "✅ Guests endpoint responded: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "Response: $($response.Content)" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Guests endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "🎉 Try these commands to test your API:" -ForegroundColor Green
    Write-Host "Invoke-WebRequest http://$LB_HOST:9999/" -ForegroundColor White
    Write-Host "Invoke-WebRequest http://$LB_HOST:9999/guests" -ForegroundColor White
} else {
    Write-Host "❌ Could not get load balancer hostname. Check AWS Console." -ForegroundColor Red
}
