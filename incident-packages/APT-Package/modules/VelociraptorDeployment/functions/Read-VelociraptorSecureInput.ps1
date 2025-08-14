function Read-VelociraptorSecureInput {
    <#
    .SYNOPSIS
        Securely prompts user for sensitive input like passwords.

    .DESCRIPTION
        Provides secure input handling for passwords and other sensitive data.
        Returns SecureString objects and handles secure memory management.

    .PARAMETER Prompt
        The prompt message to display to the user.

    .PARAMETER ConfirmPrompt
        Optional confirmation prompt for password verification.

    .PARAMETER MinLength
        Minimum required length for the input.

    .PARAMETER MaxLength
        Maximum allowed length for the input.

    .PARAMETER AllowEmpty
        Allow empty input (returns empty SecureString).

    .PARAMETER ConvertToPlainText
        Convert SecureString to plain text (use with caution).

    .EXAMPLE
        $password = Read-VelociraptorSecureInput -Prompt "Enter password"

    .EXAMPLE
        $password = Read-VelociraptorSecureInput -Prompt "Enter password" -ConfirmPrompt "Confirm password" -MinLength 8

    .OUTPUTS
        System.Security.SecureString or System.String (if ConvertToPlainText is used)

    .NOTES
        This function replaces the legacy AskSecret function with enhanced capabilities.
        Use ConvertToPlainText sparingly and clear variables immediately after use.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [Parameter()]
        [string]$ConfirmPrompt,

        [Parameter()]
        [ValidateRange(0, 1000)]
        [int]$MinLength = 0,

        [Parameter()]
        [ValidateRange(1, 1000)]
        [int]$MaxLength = 256,

        [Parameter()]
        [switch]$AllowEmpty,

        [Parameter()]
        [switch]$ConvertToPlainText
    )

    try {
        $maxAttempts = 3
        $attempt = 0

        do {
            $attempt++
            $validInput = $true
            $secureInput = $null
            $confirmInput = $null

            # Get primary input
            try {
                Write-Information "$Prompt`: " -InformationAction Continue -NoNewline
                $secureInput = Read-Host -AsSecureString
            }
            catch {
                Write-VelociraptorLog "Error reading secure input: $($_.Exception.Message)" -Level Error
                throw
            }

            # Check if empty and handle accordingly
            if ($secureInput.Length -eq 0) {
                if (-not $AllowEmpty) {
                    Write-VelociraptorLog "Input cannot be empty. Please try again." -Level Warning
                    $validInput = $false
                    continue
                } else {
                    # Return empty SecureString
                    Write-VelociraptorLog "Empty input accepted" -Level Debug
                    if ($ConvertToPlainText) {
                        return ""
                    } else {
                        return $secureInput
                    }
                }
            }

            # Validate length (need to convert temporarily to check)
            $tempPlainText = ""
            $ptr = [System.IntPtr]::Zero
            try {
                $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureInput)
                $tempPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)

                if ($tempPlainText.Length -lt $MinLength) {
                    Write-VelociraptorLog "Input too short. Minimum length is $MinLength characters." -Level Warning
                    $validInput = $false
                    continue
                }

                if ($tempPlainText.Length -gt $MaxLength) {
                    Write-VelociraptorLog "Input too long. Maximum length is $MaxLength characters." -Level Warning
                    $validInput = $false
                    continue
                }
            }
            finally {
                # Always clear the pointer from memory
                if ($ptr -ne [System.IntPtr]::Zero) {
                    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
                }
                # Clear the temporary plain text
                if ($tempPlainText) {
                    $tempPlainText = $null
                }
            }

            # Get confirmation if requested
            if ($ConfirmPrompt -and $validInput) {
                try {
                    Write-Information "$ConfirmPrompt`: " -InformationAction Continue -NoNewline
                    $confirmInput = Read-Host -AsSecureString
                }
                catch {
                    Write-VelociraptorLog "Error reading confirmation input: $($_.Exception.Message)" -Level Error
                    throw
                }

                # Compare SecureStrings
                $inputsMatch = $false
                $ptr1 = [System.IntPtr]::Zero
                $ptr2 = [System.IntPtr]::Zero

                try {
                    $ptr1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureInput)
                    $ptr2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirmInput)

                    $plainText1 = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr1)
                    $plainText2 = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr2)

                    $inputsMatch = $plainText1 -ceq $plainText2
                }
                finally {
                    # Always clear pointers from memory
                    if ($ptr1 -ne [System.IntPtr]::Zero) {
                        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr1)
                    }
                    if ($ptr2 -ne [System.IntPtr]::Zero) {
                        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr2)
                    }
                }

                if (-not $inputsMatch) {
                    Write-VelociraptorLog "Inputs do not match. Please try again." -Level Warning
                    $validInput = $false
                    continue
                }
            }

            # If we get here, input is valid
            if ($validInput) {
                Write-VelociraptorLog "Secure input accepted" -Level Debug

                if ($ConvertToPlainText) {
                    # Convert to plain text (use with caution)
                    $ptr = [System.IntPtr]::Zero
                    try {
                        $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureInput)
                        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
                    }
                    finally {
                        if ($ptr -ne [System.IntPtr]::Zero) {
                            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
                        }
                    }
                } else {
                    return $secureInput
                }
            }

        } while ($attempt -lt $maxAttempts -and -not $validInput)

        # Max attempts reached
        if (-not $validInput) {
            throw "Maximum input attempts ($maxAttempts) exceeded. Invalid input provided."
        }

        return $secureInput
    }
    catch {
        $errorMessage = "Failed to read secure input: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMessage -Level Error
        throw $errorMessage
    }
}