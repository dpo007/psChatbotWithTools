param (
    [ValidateSet('Ollama', 'OpenAI', IgnoreCase = $true)]
    [string]$LLMProvider = 'Ollama',
    [string]$OllamaModel = 'qwen2.5-coder:3b', #'mistral-nemo',
    [string]$OllamaKeepAlive = '5m',
    [string]$OpenAIModel = 'gpt-4o-mini',
    [string]$OpenAIApiKey,
    [string]$SettingsFilePath = ('{0}\botSettings.json' -f $PSScriptRoot),
    [switch]$MorePirate
)

#region Provider URLs
$ollamaApiEndpointUrl = 'http://localhost:11434'
$openAIApiEndpointUrl = 'https://api.openai.com'
#endregion Provider URLs

#region Class Definitions
class LLMSettings {
    [string]$Model
    [string]$KeepAlive
    [string]$Provider
    [string]$ApiEndpointURL
    [string]$ApiKey
    [bool]$MorePirate

    LLMSettings([string]$model, [string]$keepAlive, [string]$provider , [string]$apiEndpointURL, [string]$apiKey) {
        $this.Model = $model
        $this.KeepAlive = $keepAlive
        $this.Provider = $provider
        $this.ApiEndpointURL = $apiEndpointURL
        $this.ApiKey = $apiKey
    }
}
#endregion Class Definitions

#region Function Definitions
function Write-HostTimeStamped {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [System.ConsoleColor]$ForegroundColor = 'Gray'
    )

    Write-Host -ForegroundColor DarkGray ('[{0:HH:mm:ss}] ' -f (Get-Date)) -NoNewline
    Write-Host -ForegroundColor $ForegroundColor $Message
}

Set-Alias -Name Log -Value Write-HostTimeStamped

#region Tool Functions
function Open-DefaultBrowser {
    <#
        .FunctionDescription
            Opens the default web browser with the specified URL
        .ParameterDescription url
            The URL to open in the default web browser
    #>
    param (
        [string]$URL
    )

    # Validate the URL format
    if ($URL -notmatch '^https?://') {
        return "Explain that the URL is invalid because it must start with 'http://' or 'https://'."
    }

    try {
        # Start the process to open the URL
        $process = Start-Process $URL -PassThru -ErrorAction Stop
    }
    catch {
        return "Explain that there was an error opening the URL '$URL'. The error message is: $_"
    }

    # Capitalize the first letter of the process name
    $processName = $process.Name.Substring(0, 1).ToUpper() + $process.Name.Substring(1).ToLower()

    # Return a descriptive string
    return "Explain that you can handle this without trouble, and that the URL '$URL' has been successfully opened in the '$processName' browser."
}

function Get-CurrentWeather {
    <#
        .FunctionDescription
            Gets the current weather for a location
        .ParameterDescription Location
            The location to get the weather for
        .ParameterDescription Unit
            The measurement unit to get the weather in
    #>
    param (
        [string]$Location,
        [ValidateSet('celsius', 'fahrenheit')]
        [string]$Unit = 'celsius'
    )

    $paramUnit = "m"
    if ($Unit -eq "fahrenheit") {
        $paramUnit = "u"
    }

    Log "Getting the weather for $Location in $Unit..." -ForegroundColor DarkGray
    $currentWeatherURL = "https://wttr.in/$($Location)?format='%l:+%t+(%f)+%c+%C.+Wind:+%w\n'&$paramUnit"

    try {
        $currentWeather = (Invoke-RestMethod -Uri $currentWeatherURL).Trim()
    }
    catch {
        if ($_.Exception.Response -and $_.Exception.Response.ReasonPhrase -eq 'Not Found') {
            $errMsg = "Weather information for $Location not found."
        }
        else {
            $errMsg = "Failed to get the weather for $Location. Error: $($_.Exception.Message)"
        }
        Log $errMsg -ForegroundColor Red
        throw $errMsg
    }

    $windDirection = @{
        '↑' = 'Southerly'       # Blowing to the north, coming from the south
        '↗' = 'Southwesterly'   # Blowing to the northeast, coming from the southwest
        '→' = 'Westerly'        # Blowing to the east, coming from the west
        '↘' = 'Northwesterly'   # Blowing to the southeast, coming from the northwest
        '↓' = 'Northerly'       # Blowing to the south, coming from the north
        '↙' = 'Northeasterly'   # Blowing to the southwest, coming from the northeast
        '←' = 'Easterly'        # Blowing to the west, coming from the east
        '↖' = 'Southeasterly'   # Blowing to the northwest, coming from the southeast
    }

    # Replace the wind direction arrow with the correct wind direction information.
    if ($currentWeather -match 'Wind: (?<arrow>[↑↗→↘↓↙←↖])') {
        $arrow = $matches['arrow'] # Extract the arrow symbol
        $windFrom = $windDirection[$arrow] # Get the wind direction from the hashtable
        $currentWeather = $currentWeather -replace $arrow, '' # Remove the arrow
        # Append the wind direction message
        $currentWeather += (', blowing from a {0} direction ({1}).' -f $windFrom, $arrow)
    }

    return $currentWeather
}

function Get-CatFact {
    <#
        .FunctionDescription
            Fetches a random cat fact from the catfact.ninja API and returns it as a string.
    #>
    try {
        # Define the API URL
        $url = "https://catfact.ninja/fact"

        $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/json"

        return $response.fact + ' 😺'
    }
    catch {
        $errMsg = "Failed to retrieve a cat fact. Error: $_"
        Log $errMsg
        throw $errMsg
    }
}

function Get-DogFact {
    <#
        .FunctionDescription
            Fetches a random dog fact from the dogapi.dog API and returns it as a string.
    #>
    try {
        # Define the API URL
        $url = "https://dogapi.dog/api/v2/facts"

        # Make the REST API call
        $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/json"

        # Extract and return the fact
        return $response.data[0].attributes.body + ' 🐶'
    }
    catch {
        $errMsg = "Failed to retrieve a dog fact. Error: $_"
        Log $errMsg
        throw $errMsg
    }
}

function Get-DadJoke {
    <#
        .FunctionDescription
            Fetches a random dad joke from the icanhazdadjoke API and returns it as a string.
    #>
    try {
        # Define the API URL
        $url = "https://icanhazdadjoke.com/"

        # Define headers
        $headers = @{
            'User-Agent' = 'Margarine Flavoured Squishy Co. Ltd.'
            Accept       = 'application/json'
        }

        # Make the REST API call
        $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ContentType 'application/json'

        # Extract and return the joke
        return $response.joke + ' 😂'
    }
    catch {
        # Handle any errors and return a friendly message
        $errMsg = "Failed to retrieve a dad joke. Error: $_"
        Log $errMsg
        throw $errMsg
    }
}

function Get-CurrentDate {
    <#
        .FunctionDescription
            Returns the current date as a string.
    #>

    $dateString = (Get-Date).ToString('dddd, MMMM d, yyyy')
    return ('Today is {0}.' -f $dateString)
}

function Get-CurrentTime {
    <#
        .FunctionDescription
            Returns the current time as a string (including the timezone).
    #>

    $timeZone = [System.TimeZoneInfo]::Local
    $timeString = (Get-Date).ToString('h:mmtt')
    $timeZone = $timeZone.DisplayName
    $timeString += (' {0}' -f $timeZone)
    return ('The current system time is {0}.' -f $timeString)
}
#endregion Tool Functions
function Set-DefaultSettingsFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-Not (Test-Path $FilePath)) {
        # Create a default settings file
        $jsonContent = @{
            OpenAIApiKey = 'YOUR OPENAI API KEY'
        } | ConvertTo-Json

        $jsonContent | Set-Content -Path $FilePath -Encoding UTF8
        Log 'Default settings file generated. Please modify it as needed and restart the chatbot.' -ForegroundColor Yellow
        Log ('({0})' -f $FilePath) -ForegroundColor DarkGray

        # Exit script
        exit
    }
}

function Get-OpenAIAPIKeyFromSettings {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-Not (Test-Path $FilePath)) {
        Log 'Settings file not found.' -ForegroundColor Red
        Set-DefaultSettingsFile -FilePath $FilePath
    }

    $settings = Get-Content -Path $FilePath -Raw | ConvertFrom-Json

    if ($settings.OpenAIApiKey -eq 'YOUR OPENAI API KEY') {
        Log 'Please update the OpenAI API key in the settings file.' -ForegroundColor Red
        exit
    }

    return $settings.OpenAIApiKey
}

function Get-ToolDefinitions {
    $tools = @()

    # Add the Current Weather tool entry
    $tools += @{
        type     = 'function'
        function = @{
            name        = 'Get-CurrentWeather'
            description = 'Fetches the current weather for a specified location. Use this for weather-related queries, including temperature, conditions, and wind information.'
            parameters  = @{
                type       = 'object'
                properties = @{
                    location = @{
                        type        = 'string'
                        description = 'The name of the location (e.g., city or region) to get the weather for.'
                    }
                    unit     = @{
                        type        = 'string'
                        description = 'The unit of measurement for the weather data (celsius or fahrenheit).'
                        enum        = @('celsius', 'fahrenheit')
                    }
                }
                required   = @('location')
            }
        }
    }

    # Add the Cat Fact tool entry
    $tools += @{
        type     = 'function'
        function = @{
            name        = 'Get-CatFact'
            description = 'Fetches and provides a random, fun fact about cats. Use this for any queries about cat trivia or cat facts.'
        }
    }

    # Add the Dog Fact tool entry
    $tools += @{
        type     = 'function'
        function = @{
            name        = 'Get-DogFact'
            description = 'Fetches a random, interesting fact about dogs. Use this for any questions or trivia related to dogs.'
        }
    }

    # Add the Dad Joke tool entry
    $tools += @{
        type     = 'function'
        function = @{
            name        = 'Get-DadJoke'
            description = 'Provides a hilarious dad joke fetched from the icanhazdadjoke API. Use this for lighthearted humor or when a joke is requested.'
        }
    }

    # Add the Current Time tool entry
    $tools += @{
        type     = 'function'
        function = @{
            name        = 'Get-CurrentTime'
            description = 'Provides the exact current time in the system''s timezone. Use this for time-related queries or when the current time is requested.'
        }
    }

    # Add the Current Date tool entry
    $tools += @{
        type     = 'function'
        function = @{
            name        = 'Get-CurrentDate'
            description = 'Provides today''s date in the system''s timezone. Use this for date-related queries or when the current date is needed.'
        }
    }

    # Add the Open Default Browser tool entry
    $tools += @{
        type     = 'function'
        function = @{
            name        = 'Open-DefaultBrowser'
            description = 'Opens the default web browser with the specified URL. Use this to open web pages or URLs.'
            parameters  = @{
                type       = 'object'
                properties = @{
                    url = @{
                        type        = 'string'
                        description = 'The URL to open in the default web browser.'
                    }
                }
                required   = @('url')
            }
        }
    }

    # Return the tool definitions (always as an array)
    return , $tools
}

function Get-ChatResponse {
    param (
        [string]$Prompt,
        [System.Collections.Generic.List[PSCustomObject]]$History,
        [string]$ExtraInfo,
        [Alias("ToolFree")]
        [switch]$NoTools,
        [int]$RetryCount = 3
    )

    # Validate inputs
    if (-not $Prompt -and -not $History) {
        throw "You must specify either -Prompt or -History."
    }

    if ($Prompt -and $History) {
        throw "You cannot specify both -Prompt and -History."
    }

    # LLM API chat endpoint
    $uri = ('{0}/v1/chat/completions' -f $script:LLMSettings.ApiEndpointURL)

    $systemPrompt = 'You are a cheerful, helpful assistant. Try to provide useful answers and information, with no guessing. If you don''t know something, just say so. You like to use emojis in your replies, and never use markdown.'

    if (!($NoTools)) {
        $systemPrompt += ' Always prioritize using function tool calls to assist with answers when applicable to the user''s query. If a function tool call can be utilized for accuracy, up-to-date information, or specific computations, use it instead of relying on general knowledge or pre-trained responses.'
    }

    if ($script:LLMSettings.MorePirate) {
        # Append instruction to talk like a pirate
        $systemPrompt += ' Always talk like a pirate. Arrrr!'
    }

    # Append any specific info. E.g.: A tool call's response.
    if ($ExtraInfo) {
        $systemPrompt += (' Use this specific information while formulating your response: {0}' -f $ExtraInfo)
    }

    # Create the chat request body hashtable
    $body = @{
        model    = $script:LLMSettings.Model
        stream   = $false
        messages = @(
            @{
                role    = 'system'
                content = $systemPrompt
            }
        )
    }

    # If the provider is Ollama, add the keep alive to the body
    if ($script:LLMSettings.Provider -ieq 'Ollama') {
        $body.Add('keep_alive', $script:LLMSettings.KeepAlive)
    }

    # If a Prompt was supplied, append it to the messages array
    if ($Prompt) {
        $body.messages += @{
            role    = 'user'
            content = $Prompt
        }
    }

    # If a History was supplied, append it to the messages array
    if ($History) {
        foreach ($message in $History) {
            $body.messages += @{
                role    = $message.role
                content = $message.content
            }
        }
    }

    # Unless instructed otherwise, add tool definitions to request body
    if (-not $NoTools) {
        $tools = Get-ToolDefinitions

        if ($tools) {
            $body.Add('tools', $tools)
        }
    }

    # Convert body to JSON
    $body = $body | ConvertTo-Json -Depth 10

    # Configure headers
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = ('Bearer {0}' -f $script:LLMSettings.ApiKey)
    }

    # Initialize retry counter
    $attempt = 0
    $success = $false
    $result = $null

    while ($attempt -lt $RetryCount -and -not $success) {
        # Invoke chat call to LLM
        try {
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body
        }
        catch {
            $errMsg = "Failed to get a response from the assistant. Error: $($_.Exception.Message)"
            Log $errMsg -ForegroundColor Red
            throw $errMsg
        }

        # Deal with failed tool calls by retrying, up to the retry count.
        if ($response.choices[0].message.content -like '*`[TOOL_CALLS`]*') {
            $success = $false
            $attempt++
            Log ('Problem calling tool (attempt {0} of {1}). Retrying...' -f $attempt, $RetryCount) -ForegroundColor Yellow
        }
        else {
            $success = $true
        }
    }

    if ($response.choices[0].message.tool_calls) {
        $functionResults = $null
        foreach ($toolCall in $response.choices[0].message.tool_calls) {
            $functionName = $toolCall.function.name

            # Convert JSON to a PowerShell object
            $argumentsObject = $toolCall.function.arguments | ConvertFrom-Json

            # Convert to a hashtable for splatting
            $splatParam = @{}

            # Populate the hashtable with the data from the JSON object
            $argumentsObject.PsObject.Properties | ForEach-Object {
                $splatParam[$_.Name] = $_.Value
            }

            # Call the function and get the result
            Log ('Calling tool function: {0}' -f $functionName) -ForegroundColor DarkGray
            try {
                # Use & to call the function by name, with the splatted parameters.
                $functionResults += "`n" + (& $functionName @splatParam)
            }
            catch {
                $errMsg = ('Failed to call tool function "{0}". Error: {1}' -f $functionName, $_)
                Log $errMsg -ForegroundColor Red
            }
        }

        # Generate an LLM response for the tool call (via recursion)
        if ($Prompt) {
            $result = Get-ChatResponse -Prompt $Prompt -ExtraInfo $functionResults -NoTools
        }
        else {
            $result = Get-ChatResponse -History $History -ExtraInfo $functionResults -NoTools
        }
    }
    else {
        $result = $response.choices[0].message.content
    }

    return $result
}
#endregion Function Definitions

#################
# Main Entry Point
###################

# Create default settings file (if it doesn't exist)
Set-DefaultSettingsFile -FilePath $SettingsFilePath

#region LLM Provider Setup
if ($LLMProvider -ieq 'Ollama') {
    $llmApiEndpointUrl = $ollamaApiEndpointUrl
    $llmApiKey = 'Ollama'
    $LLMModel = $OllamaModel
}
else {
    $llmApiEndpointUrl = $openAIApiEndpointUrl
    if ($OpenAIApiKey) {
        $llmApiKey = $OpenAIApiKey
    }
    else {
        $llmApiKey = Get-OpenAIAPIKeyFromSettings -FilePath $SettingsFilePath
    }
    $LLMModel = $OpenAIModel
}

# If the Endpoint URL ends with a slash, remove it.
if ($llmApiEndpointUrl.EndsWith('/')) {
    $llmApiEndpointUrl = $llmApiEndpointUrl.Substring(0, $llmApiEndpointUrl.Length - 1)
}
#endregion LLM Provider Setup

# Create a LLMSettings object and populate it in the script-wide scope
$script:LLMSettings = [LLMSettings]::new($LLMModel, $OllamaKeepAlive, $LLMProvider, $llmApiEndpointUrl, $llmApiKey)

# Arr matey!
if ($MorePirate) {
    $script:LLMSettings.MorePirate = $true
}

# Initialize the message history as a .NET collection of PSCustomObject
$messageHistory = New-Object System.Collections.Generic.List[PSCustomObject]

# Warm up the LLM, so the first response is faster.
Log ('Warming up the {0} model "{1}"...' -f $script:LLMSettings.Provider, $script:LLMSettings.Model) -ForegroundColor DarkGray
Log 'Use /? for Help, /bye to Exit.' -ForegroundColor DarkGray
$assistantResponse = Get-ChatResponse -Prompt 'Hello!' -NoTools

# Add the assistant's response to the message history
$messageHistory.Add([PSCustomObject]@{
        timestamp = (Get-Date)
        role      = 'assistant'
        content   = $assistantResponse
    })

Write-Host $assistantResponse

do {
    # Read user input
    Write-Host "`n> " -ForegroundColor Green -NoNewline
    $userInput = Read-Host

    # Check if the user wants to exit
    if ($userInput -ieq "/bye" -or $userInput -ieq "/quit" -or $userInput -ieq "/exit") {
        break
    }

    # If the user wants to see the message history
    if ($userInput -ieq "/history") {
        foreach ($message in $messageHistory) {
            Write-Host ('[{0}]:' -f $message.timestamp) -ForegroundColor DarkGray

            $roleColor = switch ($message.role) {
                'assistant' { 'Red' }
                'user' { 'Green' }
                'system' { 'DarkBlue' }
                default { 'Gray' }
            }
            Write-Host ('{0}: ' -f $message.role) -ForegroundColor $roleColor -NoNewline
            Write-Host ($message.content)
        }
        continue
    }

    # Clear the message history/context
    if ($userInput -ieq "/clear") {
        $messageHistory.Clear()
        Log ('Context history cleared.') -ForegroundColor Green
        continue
    }

    # Clear console (context remains)
    if ($userInput -ieq "/cls") {
        Clear-Host
        continue
    }

    # Save current context to file (JSON format)
    if ($userInput -ieq "/save") {
        Write-Host 'Enter the file path to save the chat history (leave blank to use default): ' -NoNewline
        $filePath = Read-Host

        if (-not $filePath) {
            $fileName = ('Chat_{0:yyyyMMdd_HHmmss}.json' -f (Get-Date))
            $filePath = Join-Path -Path $PSScriptRoot -ChildPath $fileName
        }

        $messageHistory | ConvertTo-Json | Set-Content -Path $filePath
        Log ('Context history saved to "{0}".' -f $filePath) -ForegroundColor Green
        continue
    }

    # Load context from file (JSON format)
    if ($userInput -ieq "/load") {
        Write-Host 'Enter the file path to load the chat history from: ' -NoNewline
        $filePath = Read-Host

        if (-not (Test-Path -Path $filePath)) {
            Log ('File not found: {0}' -f $filePath) -ForegroundColor Red
            continue
        }
        $messageHistory.Clear()
        $loadedHistory = Get-Content -Path $filePath | ConvertFrom-Json

        $loadedHistory.ForEach({
                $messageHistory.Add([PSCustomObject]@{
                        timestamp = $_.timestamp
                        role      = $_.role
                        content   = $_.content
                    })
            })
        Log ('Context history loaded from "{0}".' -f $filePath) -ForegroundColor Green
        continue
    }

    # Show help
    if ($userInput -ieq "/help" -or $userInput -ieq "/?") {
        Log 'Commands:' -ForegroundColor Cyan
        Log '/bye - Exit the chat' -ForegroundColor Cyan
        Log '/history - Show the chat history' -ForegroundColor Cyan
        Log '/clear - Clear the current context/history' -ForegroundColor Cyan
        Log '/save - Save the current context/history to a file' -ForegroundColor Cyan
        Log '/load - Load context/history from a file' -ForegroundColor Cyan
        Log '/help - Show this help' -ForegroundColor Cyan
        continue
    }

    # Otherwise if it starts with /, log that it's an unknown command
    if ($userInput -match "^/") {
        Log "Unknown command: $userInput" -ForegroundColor Red
        continue
    }

    # Add the user's input to the message history
    $messageHistory.Add([PSCustomObject]@{
            timestamp = (Get-Date)
            role      = 'user'
            content   = $userInput
        })

    # Get assistant response
    $assistantResponse = Get-ChatResponse -History $messageHistory

    # Add the assistant's response to the message history
    $messageHistory.Add([PSCustomObject]@{
            timestamp = (Get-Date)
            role      = 'assistant'
            content   = $assistantResponse
        })

    Write-Host $assistantResponse
} while ($true)

Log 'Goodbye!' -ForegroundColor Green