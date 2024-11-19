# Set error action preference to stop on any error
$ErrorActionPreference = "Stop"

$outputFile = "/home/amitdemo/output.txt"

function Create-AndUploadFile {
    Write-Output "Creating and uploading file..."
    
    try {
        # Connect using managed identity
        Connect-AzAccount -Identity

        # Get the storage account and context
        $storageAccount = Get-AzStorageAccount -ResourceGroupName "CoE" -Name "amitdemovm"
        $context = $storageAccount.Context

        # Create output file
        $currentDate = Get-Date
        Set-Content -Path $outputFile -Value "Date and Time:`n$currentDate"

        # Generate the blob path for current date
        $year = $currentDate.Year
        $month = $currentDate.Month.ToString("00")
        $day = $currentDate.Day.ToString("00")
        $blobPath = "$year/$month/$day/output.txt"

        # Upload the file with force flag
        Set-AzStorageBlobContent -File $outputFile -Container "amitdemovm" -Blob $blobPath -Context $context -Force
        Write-Output "File uploaded successfully to: $blobPath"

        # Create an empty folder marker
        $tempFile = New-TemporaryFile
        Set-AzStorageBlobContent -File $tempFile.FullName -Container "amitdemovm" -Blob "folder02/.folder" -Context $context -Force
        Remove-Item $tempFile
        Write-Output "Folder marker created successfully"
    }
    catch {
        Write-Error "Error in Create-AndUploadFile: $_"
        throw
    }
}

function Test-PreviousDateAccess {
    Write-Output "Testing previous date file access..."
    
    try {
        # Connect using managed identity
        Connect-AzAccount -Identity

        # Get the storage account and context
        $storageAccount = Get-AzStorageAccount -ResourceGroupName "CoE" -Name "amitdemovm"
        $context = $storageAccount.Context

        # Test parameters
        $maxRetries = 5
        $retryCount = 0
        $previousDate = (Get-Date).AddDays(-1)
        $year = $previousDate.Year
        $month = $previousDate.Month.ToString("00")
        $day = $previousDate.Day.ToString("00")
        $blobPath = "$year/$month/$day/output.txt"

        Write-Output "Attempting to access blob: $blobPath"
        $success = $false

        while ($retryCount -lt $maxRetries) {
            try {
                $blob = Get-AzStorageBlob -Container "amitdemovm" -Blob $blobPath -Context $context -ErrorAction Stop
                Write-Output "Successfully accessed blob"
                $success = $true
                break
            }
            catch {
                $retryCount++
                Write-Output "Attempt $retryCount of $maxRetries failed: $_"
                
                # Create and upload new file
                Create-AndUploadFile
                Write-Output "Created and Uploaded new file"
                
                if ($retryCount -eq $maxRetries) {
                    Write-Output "Failed to access blob after $maxRetries attempts"
                }
                else {
                    Start-Sleep -Seconds 5
                }
            }
        }

        return $success
    }
    catch {
        Write-Error "Error in Test-PreviousDateAccess: $_"
        throw
    }
}

function Main {
    Write-Output "=== Starting Script ==="
    
    try {
        Write-Output "Testing previous date access..."
        $testResult = Test-PreviousDateAccess
        
        if (-not $testResult) {
            Write-Output "Previous date access test failed after maximum retries"
            exit 1
        }
        
        Write-Output "Previous date access test passed"
        Write-Output "=== Script completed ==="
    }
    catch {
        Write-Error "Error in main execution: $_"
        exit 1
    }
}

# Execute the main function
Main