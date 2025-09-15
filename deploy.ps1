# Guest List Deployment Script - PowerShell
# Fixed version with corrected kubectl version check

param(
    [string]$Environment = "dev",
    [string]$UserName = "",
    [switch]$Destroy = $false,
    [switch]$Plan = $false
)

Write-Host "Guest List Deployment Script" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

# Check terraform directory
if (-not (Test-Path "terraform")) {
    Write-Error "terraform directory not found. Run from project root."
    exit 1
}

# Validate environment
if ($Environment -notin @("dev", "staging", "prod")) {
    Write-Error "Invalid environment. Use: dev, staging, or prod"
    exit 1
}

# Set file paths
$envFile = "environments\$Environment\terraform.tfvars"
$envFileLocal = "environments\$Environment\terraform.tfvars.local"

if (-not (Test-Path $envFile)) {
    Write-Error "Environment file not found: $envFile"
    exit 1
}

Write-Host "Using environment: $Environment" -ForegroundColor Cyan

# Handle UserName parameter
if ($UserName -ne "") {
    Write-Host "Using username: $UserName" -ForegroundColor Cyan
    
    $clusterName = "guestlist-$UserName-$Environment"
    
    Write-Host "Creating user-specific configuration..." -ForegroundColor Yellow
    
    # Read base configuration
    $content = Get-Content $envFile
    $updatedContent = @()
    
    foreach ($line in $content) {
        if ($line -match '^cluster_name\s*=') {
            $updatedContent += "cluster_name         = `"$clusterName`""
        }
        elseif ($line -match '^student_name\s*=') {
            $updatedContent += "student_name        = `"$UserName`""
        }
        elseif ($line -match 'Owner\s*=') {
            $updatedContent += "    Owner       = `"$UserName`""
        }
        else {
            $updatedContent += $line
        }
    }
    
    # Write to local file
    $updatedContent | Out-File -FilePath $envFileLocal -Encoding UTF8
    Write-Host "Created configuration file: $envFileLocal" -ForegroundColor Green
    
    $tfVarsFile = $envFileLocal
}
else {
    if (Test-Path $envFileLocal) {
        Write-Host "Using existing local file: $envFileLocal" -ForegroundColor Yellow
        $tfVarsFile = $envFileLocal
    }
    else {
        Write-Host "Using base environment file: $envFile" -ForegroundColor Blue
        $tfVarsFile = $envFile
    }
}

# Display configuration
Write-Host ""
Write-Host "Configuration Summary:" -ForegroundColor Cyan
if ($UserName -ne "") {
    Write-Host ("  Student Name: " + $UserName) -ForegroundColor White
    Write-Host ("  Cluster Name: " + $clusterName) -ForegroundColor White
}
Write-Host ("  Environment: " + $Environment) -ForegroundColor White
Write-Host ("  Config File: " + $tfVarsFile) -ForegroundColor White

# Check prerequisites
Write-Host ""
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check terraform
try {
    $null = terraform --version
    Write-Host ("  terraform installed") -ForegroundColor Green
}
catch {
    Write-Error "terraform is not installed or not in PATH"
    exit 1
}

# Check AWS CLI
try {
    $null = aws --version
    Write-Host ("  aws installed") -ForegroundColor Green
}
catch {
    Write-Error "aws is not installed or not in PATH"
    exit 1
}

# Check kubectl (fixed version check)
try {
    $null = kubectl version --client=true
    Write-Host ("  kubectl installed") -ForegroundColor Green
}
catch {
    try {
        # Fallback for older kubectl versions
        $null = kubectl version --client
        Write-Host ("  kubectl installed") -ForegroundColor Green
    }
    catch {
        Write-Error "kubectl is not installed or not in PATH"
        exit 1
    }
}

# Check AWS credentials
try {
    $null = aws sts get-caller-identity
    Write-Host "  AWS credentials configured" -ForegroundColor Green
}
catch {
    Write-Error "AWS credentials not configured. Run 'aws configure'"
    exit 1
}

# Change to terraform directory
Push-Location terraform

try {
    # Initialize Terraform
    Write-Host ""
    Write-Host "Initializing Terraform..." -ForegroundColor Yellow
    terraform init
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform initialization failed"
    }
    
    # Handle destroy operation
    if ($Destroy) {
        Write-Host ""
        Write-Host "DESTROYING infrastructure..." -ForegroundColor Red
        Write-Host "WARNING: This will delete ALL resources!" -ForegroundColor Red
        if ($UserName -ne "") {
            Write-Host ("Destroying resources for user: " + $UserName) -ForegroundColor Red
        }
        
        $confirmation = Read-Host "Type 'yes' to confirm destruction"
        if ($confirmation -eq "yes") {
            terraform destroy -var-file="../$tfVarsFile" -auto-approve
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Infrastructure destroyed successfully!" -ForegroundColor Green
                if ($UserName -ne "") {
                    Write-Host ("Resources for user " + $UserName + " have been cleaned up.") -ForegroundColor Green
                }
            }
            else {
                Write-Error "Destruction failed!"
            }
        }
        else {
            Write-Host "Destruction cancelled." -ForegroundColor Yellow
        }
        return
    }
    
    # Plan deployment
    Write-Host ""
    Write-Host "Planning deployment..." -ForegroundColor Yellow
    terraform plan -var-file="../$tfVarsFile"
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform plan failed"
    }
    
    # If only planning, exit here
    if ($Plan) {
        Write-Host ""
        Write-Host "Plan completed successfully!" -ForegroundColor Green
        if ($UserName -ne "") {
            Write-Host ("Resources planned for user: " + $UserName) -ForegroundColor Green
        }
        return
    }
    
    # Apply deployment
    Write-Host ""
    Write-Host "Applying deployment..." -ForegroundColor Yellow
    Write-Host "This may take 15-20 minutes for EKS cluster creation..." -ForegroundColor Gray
    if ($UserName -ne "") {
        Write-Host ("Deploying infrastructure for user: " + $UserName) -ForegroundColor Cyan
    }
    
    terraform apply -var-file="../$tfVarsFile" -auto-approve
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply failed"
    }
    
    Write-Host ""
    Write-Host "Deployment completed successfully!" -ForegroundColor Green
    
    # Configure kubectl
    Write-Host ""
    Write-Host "Configuring kubectl..." -ForegroundColor Yellow
    try {
        $kubectlCommand = terraform output -raw kubectl_config
        if ($kubectlCommand) {
            Invoke-Expression $kubectlCommand
            Write-Host "kubectl configured successfully!" -ForegroundColor Green
            
            # Test cluster connection
            Write-Host ""
            Write-Host "Testing cluster connection..." -ForegroundColor Yellow
            kubectl get nodes
            
            try {
                $namespace = terraform output -raw namespace
                kubectl get pods -n $namespace
            }
            catch {
                Write-Warning "Could not get pod status. Check manually with: kubectl get pods --all-namespaces"
            }
        }
    }
    catch {
        Write-Warning "kubectl configuration may have failed. Run the command manually from terraform output."
    }
    
    # Display results
    Write-Host ""
    Write-Host "Deployment Summary:" -ForegroundColor Green
    $studentDisplay = if ($UserName) { $UserName } else { "Not specified" }
    Write-Host ("  Student: " + $studentDisplay) -ForegroundColor White
    Write-Host ("  Environment: " + $Environment) -ForegroundColor White
    
    try {
        $clusterOutput = terraform output -raw cluster_name
        $appUrl = terraform output -raw application_url
        Write-Host ("  Cluster: " + $clusterOutput) -ForegroundColor White
        Write-Host ("  Application URL: " + $appUrl) -ForegroundColor White
        
        try {
            $costInfo = terraform output -json estimated_monthly_cost | ConvertFrom-Json
            Write-Host ("  Estimated Monthly Cost: " + $costInfo.total_estimate) -ForegroundColor White
        }
        catch {
            Write-Host "  Cost information: Check terraform output" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "  For detailed information, run: terraform output" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Test the API at the application URL shown above" -ForegroundColor White
    Write-Host "  2. Monitor costs in AWS Console" -ForegroundColor White
    Write-Host "  3. Scale if needed: kubectl scale deployment guestlist-deployment --replicas=3" -ForegroundColor White
    if ($UserName -ne "") {
        Write-Host ("  4. Clean up when done: .\deploy.ps1 -UserName " + $UserName + " -Environment " + $Environment + " -Destroy") -ForegroundColor White
    }
    else {
        Write-Host ("  4. Clean up when done: .\deploy.ps1 -Environment " + $Environment + " -Destroy") -ForegroundColor White
    }
}
catch {
    Write-Error "Deployment failed: $_"
    exit 1
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "Script completed!" -ForegroundColor Green
