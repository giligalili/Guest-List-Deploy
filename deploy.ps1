# deploy.ps1 - PowerShell deployment script for Guest List API on EKS
# Compatible with Windows PowerShell 5.1+ and PowerShell Core 6+

param(
    [Parameter(Position=0)]
    [ValidateSet("deploy", "destroy", "status")]
    [string]$Action = "deploy",
    
    [string]$StudentName = "",
    [string]$ClusterName = "",
    [string]$AwsRegion = "us-west-2",
    [string]$Environment = "dev"
)

# Colors for output (works in PowerShell ISE and Console)
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

# Check if required tools are installed
function Test-Prerequisites {
    Write-ColorOutput "Checking prerequisites..." -Type Info
    
    $missingTools = @()
    
    # Check AWS CLI
    try {
        $null = aws --version 2>$null
        if ($LASTEXITCODE -ne 0) { throw }
    } catch {
        $missingTools += "AWS CLI"
    }
    
    # Check Terraform
    try {
        $null = terraform version 2>$null
        if ($LASTEXITCODE -ne 0) { throw }
    } catch {
        $missingTools += "Terraform"
    }
    
    # Check kubectl
    try {
        $null = kubectl version --client=true 2>$null
        if ($LASTEXITCODE -ne 0) { throw }
    } catch {
        $missingTools += "kubectl"
    }
    
    if ($missingTools.Count -gt 0) {
        Write-ColorOutput "Missing tools: $($missingTools -join ', ')" -Type Error
        Write-ColorOutput "Please install missing tools and run again." -Type Error
        Write-ColorOutput "See README.md for installation instructions." -Type Info
        exit 1
    }
    
    # Check AWS credentials
    try {
        $null = aws sts get-caller-identity 2>$null
        if ($LASTEXITCODE -ne 0) { throw }
    } catch {
        Write-ColorOutput "AWS credentials not configured." -Type Error
        Write-ColorOutput "Run 'aws configure' first." -Type Error
        exit 1
    }
    
    Write-ColorOutput "All prerequisites met!" -Type Success
}

# Function to setup environment variables
function Initialize-Environment {
    Write-ColorOutput "Setting up environment variables..." -Type Info
    
    # Get student name if not provided
    if ([string]::IsNullOrWhiteSpace($script:StudentName)) {
        $script:StudentName = Read-Host "Enter your name (for resource tagging)"
        if ([string]::IsNullOrWhiteSpace($script:StudentName)) {
            Write-ColorOutput "Student name is required!" -Type Error
            exit 1
        }
    }
    
    # Set default cluster name
    if ([string]::IsNullOrWhiteSpace($script:ClusterName)) {
        $script:ClusterName = "guestlist-$($script:StudentName.ToLower() -replace '[^a-z0-9-]', '-')"
    }
    
    # Create terraform.tfvars.local file
    $tfvarsContent = @"
# Auto-generated environment configuration for Windows
aws_region = "$script:AwsRegion"
cluster_name = "$script:ClusterName"
environment = "$script:Environment"
student_name = "$script:StudentName"

# Cost-optimized defaults
node_instance_type = "t3.small"
node_desired_capacity = 2
node_max_capacity = 3
node_min_capacity = 1

app_image = "giligalili/guestlistapi:ver03"
app_replicas = 2
"@
    
    $tfvarsContent | Out-File -FilePath "terraform.tfvars.local" -Encoding UTF8
    
    Write-ColorOutput "Environment configured:" -Type Success
    Write-ColorOutput "  Student Name: $script:StudentName" -Type Info
    Write-ColorOutput "  Cluster Name: $script:ClusterName" -Type Info
    Write-ColorOutput "  AWS Region: $script:AwsRegion" -Type Info
    Write-ColorOutput "  Environment: $script:Environment" -Type Info
}

# Function to deploy infrastructure
function Deploy-Infrastructure {
    Write-ColorOutput "Initializing Terraform..." -Type Info
    terraform init
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "Terraform init failed!" -Type Error
        exit 1
    }
    
    Write-ColorOutput "Planning deployment..." -Type Info
    terraform plan -var-file="terraform.tfvars.local"
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "Terraform plan failed!" -Type Error
        exit 1
    }
    
    Write-ColorOutput "This will create AWS resources that incur costs (~`$150/month)." -Type Warning
    $confirmation = Read-Host "Continue with deployment? (y/N)"
    if ($confirmation -notmatch '^[Yy]$') {
        Write-ColorOutput "Deployment cancelled." -Type Info
        exit 0
    }
    
    Write-ColorOutput "Applying Terraform configuration..." -Type Info
    Write-ColorOutput "This will take 15-20 minutes for EKS cluster creation..." -Type Info
    
    terraform apply -var-file="terraform.tfvars.local" -auto-approve
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "Terraform apply failed!" -Type Error
        exit 1
    }
    
    Write-ColorOutput "Infrastructure deployed successfully!" -Type Success
}

# Function to configure kubectl
function Set-KubectlConfig {
    Write-ColorOutput "Configuring kubectl..." -Type Info
    
    # Get kubectl config command from terraform output
    try {
        $kubectlCmd = terraform output -raw kubectl_config 2>$null
        if ($LASTEXITCODE -ne 0) {
            $kubectlCmd = "aws eks update-kubeconfig --region $script:AwsRegion --name $script:ClusterName"
        }
    } catch {
        $kubectlCmd = "aws eks update-kubeconfig --region $script:AwsRegion --name $script:ClusterName"
    }
    
    Write-ColorOutput "Running: $kubectlCmd" -Type Info
    Invoke-Expression $kubectlCmd
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "kubectl configured successfully!" -Type Success
    } else {
        Write-ColorOutput "kubectl configuration failed!" -Type Error
        exit 1
    }
}

# Function to verify deployment
function Test-Deployment {
    Write-ColorOutput "Verifying deployment..." -Type Info
    
    # Wait for nodes to be ready
    Write-ColorOutput "Waiting for nodes to be ready..." -Type Info
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    # Wait for pods to be running
    Write-ColorOutput "Waiting for application pods to be running..." -Type Info
    kubectl wait --for=condition=Ready pods -l app=guestlist-api -n "guestlist-$script:Environment" --timeout=300s
    
    # Get cluster info
    Write-ColorOutput "Cluster Nodes:" -Type Info
    kubectl get nodes
    
    Write-ColorOutput "Application Pods:" -Type Info
    kubectl get pods -n "guestlist-$script:Environment"
    
    # Get service info
    Write-ColorOutput "Getting Load Balancer information..." -Type Info
    kubectl get service guestlist-service -n "guestlist-$script:Environment"
    
    # Get Load Balancer URL
    try {
        $lbHost = terraform output -raw load_balancer_ip 2>$null
        if ($LASTEXITCODE -eq 0 -and ![string]::IsNullOrWhiteSpace($lbHost) -and $lbHost -ne "pending") {
            Write-ColorOutput "Load Balancer URL: http://$lbHost" -Type Success
            Write-ColorOutput "Testing API endpoint..." -Type Info
            
            # Wait for load balancer to be ready
            Start-Sleep -Seconds 30
            
            try {
                $response = Invoke-WebRequest -Uri "http://$lbHost/guests" -UseBasicParsing -TimeoutSec 10
                if ($response.StatusCode -eq 200) {
                    Write-ColorOutput "API is responding successfully!" -Type Success
                    Write-ColorOutput "Test your API with: Invoke-WebRequest http://$lbHost/guests" -Type Info
                } else {
                    Write-ColorOutput "API returned status code: $($response.StatusCode)" -Type Warning
                }
            } catch {
                Write-ColorOutput "API endpoint not yet ready. Wait a few minutes and try:" -Type Warning
                Write-ColorOutput "Invoke-WebRequest http://$lbHost/guests" -Type Info
            }
        } else {
            Write-ColorOutput "Load Balancer is still provisioning. Check AWS Console or run:" -Type Warning
            Write-ColorOutput "kubectl get service guestlist-service -n guestlist-$script:Environment" -Type Info
        }
    } catch {
        Write-ColorOutput "Could not get Load Balancer information from Terraform output" -Type Warning
    }
}

# Function to show cost information
function Show-CostInfo {
    Write-ColorOutput "=== COST INFORMATION ===" -Type Warning
    Write-ColorOutput "Estimated monthly costs for this deployment:" -Type Info
    Write-ColorOutput "  - EKS Cluster: ~`$72.00" -Type Info
    Write-ColorOutput "  - EC2 Nodes (2x t3.small): ~`$30.40" -Type Info
    Write-ColorOutput "  - NAT Gateway: ~`$32.40" -Type Info
    Write-ColorOutput "  - Load Balancer: ~`$16.20" -Type Info
    Write-ColorOutput "  - Total: ~`$151.00/month" -Type Info
    Write-ColorOutput "" -Type Warning
    Write-ColorOutput "REMEMBER: Run './deploy.ps1 destroy' when done to avoid charges!" -Type Warning
    Write-ColorOutput "Monitor costs: https://console.aws.amazon.com/billing/" -Type Warning
}

# Function to destroy infrastructure
function Remove-Infrastructure {
    Write-ColorOutput "This will destroy all resources and stop billing." -Type Warning
    $confirmation = Read-Host "Are you sure? (y/N)"
    if ($confirmation -match '^[Yy]$') {
        Write-ColorOutput "Destroying infrastructure..." -Type Info
        terraform destroy -var-file="terraform.tfvars.local" -auto-approve
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Resources destroyed successfully!" -Type Success
        } else {
            Write-ColorOutput "Destroy operation failed!" -Type Error
            exit 1
        }
    } else {
        Write-ColorOutput "Destroy operation cancelled." -Type Info
    }
}

# Function to show status
function Show-Status {
    Write-ColorOutput "Current Deployment Status:" -Type Info
    
    try {
        kubectl get nodes
        kubectl get pods -n "guestlist-$script:Environment"
        kubectl get service guestlist-service -n "guestlist-$script:Environment"
    } catch {
        Write-ColorOutput "Could not get status. Is kubectl configured?" -Type Error
        Write-ColorOutput "Run: aws eks update-kubeconfig --region $script:AwsRegion --name $script:ClusterName" -Type Info
    }
}

# Main execution
function Main {
    Write-Host "==================================================" -ForegroundColor Magenta
    Write-Host "🎉 Guest List API - EKS Deployment Script (Windows)" -ForegroundColor Magenta  
    Write-Host "==================================================" -ForegroundColor Magenta
    
    # Set script variables from parameters
    $script:StudentName = $StudentName
    $script:ClusterName = $ClusterName
    $script:AwsRegion = $AwsRegion
    $script:Environment = $Environment
    
    switch ($Action) {
        "deploy" {
            Test-Prerequisites
            Initialize-Environment
            Deploy-Infrastructure
            Set-KubectlConfig
            Test-Deployment
            Show-CostInfo
            
            Write-ColorOutput "🎉 Deployment completed successfully!" -Type Success
            Write-ColorOutput "" -Type Info
            Write-ColorOutput "Next steps:" -Type Info
            Write-ColorOutput "1. Test API: Invoke-WebRequest http://`$(terraform output -raw load_balancer_ip)/guests" -Type Info
            Write-ColorOutput "2. Monitor AWS costs" -Type Info
            Write-ColorOutput "3. When done: ./deploy.ps1 destroy" -Type Info
        }
        "destroy" {
            if (Test-Path "terraform.tfvars.local") {
                $content = Get-Content "terraform.tfvars.local" | Where-Object { $_ -match "environment" }
                if ($content) {
                    $script:Environment = ($content -split '"')[1]
                }
            }
            Remove-Infrastructure
        }
        "status" {
            if (Test-Path "terraform.tfvars.local") {
                $content = Get-Content "terraform.tfvars.local" | Where-Object { $_ -match "environment" }
                if ($content) {
                    $script:Environment = ($content -split '"')[1]
                }
            }
            Show-Status
        }
    }
}

# Execute main function
try {
    Main
} catch {
    Write-ColorOutput "Script execution failed: $($_.Exception.Message)" -Type Error
    Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" -Type Error
    exit 1
}
