# update-app.ps1 - Build and deploy updated Guest List API with HTML interface

param(
    [switch]$SkipPush = $false
)

# Colors for output
function Write-ColorOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Type = "Info"
    )
    
    $colors = @{
        "Info" = "Cyan"
        "Success" = "Green" 
        "Warning" = "Yellow"
        "Error" = "Red"
    }
    
    $prefix = @{
        "Info" = "[INFO]"
        "Success" = "[SUCCESS]"
        "Warning" = "[WARNING]" 
        "Error" = "[ERROR]"
    }
    
    Write-Host "$($prefix[$Type]) $Message" -ForegroundColor $colors[$Type]
}

Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "🔄 Updating Guest List API with HTML Interface" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

# Check prerequisites
Write-ColorOutput "Checking prerequisites..." -Type Info

# Check Docker
try {
    docker --version | Out-Null
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Write-ColorOutput "Docker is not installed!" -Type Error
    exit 1
}

# Check kubectl
try {
    kubectl version --client | Out-Null
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Write-ColorOutput "kubectl is not installed!" -Type Error
    exit 1
}

# Check kubectl configuration
try {
    kubectl get nodes | Out-Null
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Write-ColorOutput "kubectl not configured. Run:" -Type Error
    Write-Host "aws eks update-kubeconfig --region us-west-2 --name guestlist-sivan"
    exit 1
}

Write-ColorOutput "Prerequisites check passed!" -Type Success

# Get current configuration
$studentName = "student"
if (Test-Path "terraform.tfvars.local") {
    $content = Get-Content "terraform.tfvars.local" | Where-Object { $_ -match 'student_name.*=.*"([^"]*)"' }
    if ($content) {
        $studentName = $matches[1]
    }
}

$imageVersion = "v$(Get-Date -Format 'yyyyMMddHHmmss')"
$imageName = "giligalili/guestlistapi:$imageVersion"

Write-ColorOutput "Configuration:" -Type Info
Write-ColorOutput "  Student: $studentName" -Type Info
Write-ColorOutput "  New Image: $imageName" -Type Info
Write-Host ""

# Check required files
if (!(Test-Path "guestlist-server-fixed.py")) {
    Write-ColorOutput "Error: guestlist-server-fixed.py not found!" -Type Error
    Write-ColorOutput "Make sure you have the updated Python file" -Type Error
    exit 1
}

if (!(Test-Path "index.html")) {
    Write-ColorOutput "Error: index.html not found!" -Type Error
    Write-ColorOutput "Make sure you have the HTML frontend file" -Type Error
    exit 1
}

if (!(Test-Path "Dockerfile-fixed")) {
    Write-ColorOutput "Error: Dockerfile-fixed not found!" -Type Error
    Write-ColorOutput "Make sure you have the updated Dockerfile" -Type Error
    exit 1
}

# Build the new Docker image
Write-ColorOutput "Building updated Docker image with HTML interface..." -Type Info
docker build -f Dockerfile-fixed -t $imageName .

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "Docker build failed!" -Type Error
    exit 1
}

Write-ColorOutput "Docker image built successfully!" -Type Success

# Ask if user wants to push to registry
if (-not $SkipPush) {
    $pushChoice = Read-Host "Push image to Docker Hub? (y/N)"
    if ($pushChoice -match '^[Yy]$') {
        Write-ColorOutput "Pushing image to Docker Hub..." -Type Info
        docker push $imageName
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Image pushed successfully!" -Type Success
            
            # Update Terraform configuration
            Write-ColorOutput "Updating Terraform configuration..." -Type Info
            if (Test-Path "terraform.tfvars.local") {
                $content = Get-Content "terraform.tfvars.local"
                $updatedContent = $content -replace 'app_image = "giligalili/guestlistapi:.*"', "app_image = `"$imageName`""
                $updatedContent | Set-Content "terraform.tfvars.local"
                
                # Apply Terraform changes
                Write-ColorOutput "Applying Terraform changes to update deployment..." -Type Info
                terraform apply -var-file="terraform.tfvars.local" -auto-approve
                
                if ($LASTEXITCODE -eq 0) {
                    Write-ColorOutput "Deployment updated successfully!" -Type Success
                } else {
                    Write-ColorOutput "Terraform apply failed!" -Type Error
                    exit 1
                }
            } else {
                Write-ColorOutput "terraform.tfvars.local not found!" -Type Warning
            }
        } else {
            Write-ColorOutput "Docker push failed!" -Type Error
            exit 1
        }
    } else {
        Write-ColorOutput "Skipping Docker Hub push." -Type Warning
        Write-ColorOutput "To update manually:" -Type Info
        Write-ColorOutput "1. Push image: docker push $imageName" -Type Info
        Write-ColorOutput "2. Update terraform.tfvars.local with: app_image = `"$imageName`"" -Type Info
        Write-ColorOutput "3. Run: terraform apply -var-file=`"terraform.tfvars.local`"" -Type Info
        exit 0
    }
}

# Wait for rollout
Write-ColorOutput "Waiting for deployment rollout..." -Type Info
kubectl rollout status deployment/guestlist-deployment -n guestlist-dev --timeout=300s

# Get the load balancer URL
Write-ColorOutput "Getting Load Balancer URL..." -Type Info
$lbHost = kubectl get service guestlist-service -n guestlist-dev -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

if (![string]::IsNullOrEmpty($lbHost)) {
    Write-Host ""
    Write-ColorOutput "🎉 Update completed successfully!" -Type Success
    Write-Host ""
    Write-ColorOutput "Your updated Guest List API is now available at:" -Type Success
    Write-ColorOutput "🌐 Web Interface: http://$lbHost`:9999/" -Type Success
    Write-ColorOutput "🔗 API Endpoint: http://$lbHost`:9999/guests" -Type Success
    Write-Host ""
    Write-ColorOutput "New features:" -Type Info
    Write-ColorOutput "  ✅ Beautiful HTML interface" -Type Info
    Write-ColorOutput "  ✅ Guest registration form" -Type Info
    Write-ColorOutput "  ✅ Real-time statistics" -Type Info
    Write-ColorOutput "  ✅ Fixed delete functionality" -Type Info
    Write-ColorOutput "  ✅ Fixed API endpoints" -Type Info
    Write-ColorOutput "  ✅ Responsive design" -Type Info
} else {
    Write-ColorOutput "Could not get Load Balancer URL. Check service status:" -Type Warning
    Write-ColorOutput "kubectl get service guestlist-service -n guestlist-dev" -Type Info
}

Write-Host ""
Write-ColorOutput "Test the new interface in your browser!" -Type Info
