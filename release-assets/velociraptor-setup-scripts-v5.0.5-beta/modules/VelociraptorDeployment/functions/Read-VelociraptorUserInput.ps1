function Read-VelociraptorUserInput {
    <#
    .SYNOPSIS
        Prompts user for input with validation and default values.

    .DESCRIPTION
        Provides interactive user input with validation, default values, and
        multiple choice options. Designed for Velociraptor deployment scripts.

    .PARAMETER Prompt
        The prompt message to display to the user.

    .PARAMETER DefaultValue
        Default value if user presses Enter without input.

    .PARAMETER ValidValues
        Array of valid values to accept. Case-insensitive.

    .PARAMETER AllowEmpty
        Allow empty input (overrides mandatory validation).

    .PARAMETER AsSecureString
        Return input as SecureString (for passwords).

    .PARAMETER MaxLength
        Maximum length of input string.

    .PARAMETER ValidationScript
        Custom validation script block.

    .EXAMPLE
        Read-VelociraptorUserInput -Prompt "Continue deployment?" -DefaultValue "Y" -ValidValues @("Y", "N")

    .EXAMPLE
        Read-VelociraptorUserInput -Prompt "Enter server name" -ValidationScript { $_ -match "^[a-zA-Z0-9-]+$" }

    .OUTPUTS
        System.String or System.Security.SecureString

    .NOTES
        This function replaces the legacy Ask function with enhanced capabilities.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,
        
        [Parameter()]
        [string]$DefaultValue,
        
        [Parameter()]
        [string[]]$ValidValues,
        
        [Parameter()]
        [switch]$AllowEmpty,
        
        [Parameter()]
        [switch]$AsSecureString,
        
        [Parameter()]
        [ValidateRange(1, 1000)]
        [int]$MaxLength,
        
        [Parameter()]
        [scriptblock]$ValidationScript
    )
    
    try {
        $maxAttempts = 3
        $attempt = 0
        
        do {
            $attempt++
            $validInput = $true
            $userInput = ""
            
            # Build prompt string
            $promptString = $Prompt
            if ($DefaultValue) {
                $promptString += " [$DefaultValue]"
            }
            if ($ValidValues) {
                $validValuesString = $ValidValues -join "/"
                $promptString += " ($validValuesString)"
            }
            $promptString += ": "
            
            # Get user input
            try {
                if ($AsSecureString) {
                    if ($DefaultValue) {
                        Write-Warning "Default values cannot be used with secure input for security reasons. Please enter the value manually."
                        $secureInput = Read-Host -Prompt $promptString -AsSecureString
                    } else {
                        $secureInput = Read-Host -Prompt $promptString -AsSecureString
                    }
                    return $secureInput
                } else {
                    $userInput = Read-Host -Prompt $promptString
                }
            }
            catch {
                Write-VelociraptorLog "Error reading user input: $($_.Exception.Message)" -Level Error
                throw
            }
            
            # Handle empty input
            if ([string]::IsNullOrWhiteSpace($userInput)) {
                if ($DefaultValue) {
                    $userInput = $DefaultValue
                    Write-VelociraptorLog "Using default value: $DefaultValue" -Level Debug
                } elseif (-not $AllowEmpty) {
                    Write-VelociraptorLog "Input cannot be empty. Please try again." -Level Warning
                    $validInput = $false
                    continue
                }
            }
            
            # Validate against valid values
            if ($ValidValues -and $ValidValues.Count -gt 0) {
                $matchFound = $false
                foreach ($validValue in $ValidValues) {
                    if ($userInput -ieq $validValue) {
                        $matchFound = $true
                        $userInput = $validValue  # Use the case from ValidValues
                        break
                    }
                }
                
                if (-not $matchFound) {
                    Write-VelociraptorLog "Invalid input. Valid values are: $($ValidValues -join ', ')" -Level Warning
                    $validInput = $false
                    continue
                }
            }
            
            # Validate length
            if ($MaxLength -and $userInput.Length -gt $MaxLength) {
                Write-VelociraptorLog "Input too long. Maximum length is $MaxLength characters." -Level Warning
                $validInput = $false
                continue
            }
            
            # Custom validation
            if ($ValidationScript) {
                try {
                    $validationResult = & $ValidationScript $userInput
                    if (-not $validationResult) {
                        Write-VelociraptorLog "Input validation failed. Please try again." -Level Warning
                        $validInput = $false
                        continue
                    }
                }
                catch {
                    Write-VelociraptorLog "Validation error: $($_.Exception.Message)" -Level Warning
                    $validInput = $false
                    continue
                }
            }
            
            # If we get here, input is valid
            if ($validInput) {
                Write-VelociraptorLog "User input accepted: $userInput" -Level Debug
                return $userInput
            }
            
        } while ($attempt -lt $maxAttempts -and -not $validInput)
        
        # Max attempts reached
        if (-not $validInput) {
            throw "Maximum input attempts ($maxAttempts) exceeded. Invalid input provided."
        }
        
        return $userInput
    }
    catch {
        $errorMessage = "Failed to read user input: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMessage -Level Error
        throw $errorMessage
    }
}