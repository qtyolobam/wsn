# GeminiAI.ps1
$env:GeminiKey = "AIzaSyAjh7leDmMI4jdKuJzr85A_CX_OS7gSqyY"
# Function to invoke Gemini API
function Invoke-GeminiAI {
    param(
        [Parameter(Mandatory)]
        [string]$UserInput,
        [Parameter(Mandatory)]
        [string]$Instructions
    )
    
    # Check if API key exists - fixed assignment logic
    $API_KEY = $env:GeminiKey
    if (-not $API_KEY) {
        Write-Host "Please set your API key first:"
        $key = Read-Host "Enter API Key"
        $env:GeminiKey = $key
        $API_KEY = $key
    }

    # Set headers for REST request
    $Headers = @{
        'Content-Type' = 'application/json'
    }

    # Create request body
    $Body = @{
        contents = @(
            @{
                role = 'model'
                parts = @( @{
                    text = $Instructions
                })
            },
            @{
                role = 'user'
                parts = @( @{
                    text = $UserInput
                })
            }
        )
    } | ConvertTo-Json -Depth 6

    # Set correct API endpoint URL
    $Url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$API_KEY"

    try {
        # Make API request
        $response = Invoke-RestMethod -Uri $Url -Method Post -Headers $Headers -Body $Body
        
        # Return the model's response
        return $response.candidates[0].content.parts[0].text
    }
    catch {
        Write-Host "Error details:"
        Write-Host $_
        Write-Host "Response status code:"
        Write-Host $response.StatusCode
        throw
    }
}

# Main script logic
try {
    # Prompt user for input
    Write-Host "powershell >"
    $userPrompt = Read-Host

    # Default instructions for the model
    $instructions = @'
Please respond thoughtfully and thoroughly to the user's prompt. Maintain a professional tone and provide detailed explanations when needed.
'@

    # Call Gemini API and display response
    Write-Host "Processing request..."
    $response = Invoke-GeminiAI -Instructions $instructions -UserInput $userPrompt
    
    # Display response if successful
    if ($response) {
        Write-Host "`nResponse:"
        Write-Host "-------------------"
        Write-Host $response
        Write-Host "-------------------"
        
        # Keep terminal open after displaying response
        Write-Host "Press Enter to exit..."
        Read-Host | Out-Null
    }
}
catch {
    Write-Error "An error occurred: $_"
    
    # Keep terminal open even if there's an error
    Write-Host "Press Enter to exit..."
    Read-Host | Out-Null
}