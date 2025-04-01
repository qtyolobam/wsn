$env:GeminiKey = "AIzaSyAjh7leDmMI4jdKuJzr85A_CX_OS7gSqyY"
$env:GeminiFallbackKeys = "AIzaSyAjh7leDmMI4jdKuJzr85A_CX_OS7gSqyY,AIzaSyDEjenKea_aBUuZARANwhtM2KqYuCbLdfs"

function Invoke-GeminiAI {
    param(
        [Parameter(Mandatory)]
        [string]$UserInput
    )

    $API_KEY = $env:GeminiKey
    $FallbackKeys = $env:GeminiFallbackKeys -split ","
    $AllKeys = @($API_KEY) + $FallbackKeys

    if (-not $API_KEY) {
        Write-Host "Please set your primary API key first:"
        $key = Read-Host "Enter API Key"
        $env:GeminiKey = $key
        $API_KEY = $key
        $AllKeys = @($API_KEY) + $FallbackKeys
    }

    $Headers = @{ 'Content-Type' = 'application/json' }

    $Instructions = @'
SYSTEM INSTRUCTIONS:
-Your goal is to provide ONLY code
-The code must be extremely compact and efficient (without losing out on functionality)
-Provide code strictly in python
-You may use these libraries: numpy, pandas, sklearn, nltk, requests, bs4, urllib and any default libraries
-Codes should contain NO comments
-Do NOT include any additional text, besides important steps (only if necessary for setup)
'@

    $Body = @{
        contents = @(
            @{ role = 'model'; parts = @( @{ text = $Instructions }) },
            @{ role = 'user'; parts = @( @{ text = $UserInput }) }
        )
    } | ConvertTo-Json -Depth 6

    foreach ($Key in $AllKeys) {
        $Url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$Key"

        try {
            $response = Invoke-WebRequest -Uri $Url -Method Post -Headers $Headers -Body $Body -ContentType 'application/json' -UseBasicParsing

            # Check HTTP Status Code
            if ($response.StatusCode -ge 400) {
                Write-Warning "HTTP Error $($response.StatusCode) for key $($Key)"
                # Try to get more details from the content, even if it's an error
                if ($response.Content) {
                    $errorContent = $response.Content | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($errorContent) {
                         Write-Warning "Error details: $($errorContent | Out-String)"
                    } else {
                         Write-Warning "Raw error content: $($response.Content)"
                    }
                }
                continue # Try the next key
            }
           
            $responseContent = $response.Content | ConvertFrom-Json
            return $responseContent.candidates[0].content.parts[0].text

        }
        catch {
            Write-Host "Error with key $($Key): $($_.Exception.Message)"
        }
    }

    Write-Error "All API keys failed. Please check your keys or quota."
    throw "All API keys failed"
}

try {
    Write-Host "powershell >"
    $userPrompt = Read-Host
    Write-Host "Processing request..."
    $response = Invoke-GeminiAI -UserInput $userPrompt

    if ($response) {
        Write-Host "`nResponse:"
        Write-Host "-------------------"
       # Sanitize output to prevent misinterpretation
        $response = $response -replace "[<>]", ""  # Remove < and >
        Write-Host $response
        Write-Host "-------------------"
        Write-Host "Press Enter to exit..."
        [void](Read-Host)
    }
}
catch {
    Write-Error "An error occurred: $_"
    Write-Host "Press Enter to exit..."
    [void](Read-Host)
}
