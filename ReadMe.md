# ChatWithTools.ps1 🛠️🤖

Welcome to **ChatWithTools.ps1**, a PowerShell script designed to integrate with **Ollama** and **OpenAI** large language models (LLMs) to demonstrating function call tool usage and chat context management. *No modules are used*, and all calls are via REST endpoints. This script provides flexibility in selecting the LLM provider and configuring its settings for various use cases. It was created as an exercise in learning.

## Key Features 🌟

### 🔧 Multi-Provider Support
- Supports **Ollama** and **OpenAI** as LLM providers.
- Configurable models (Defaults to `mistral-nemo` for Ollama and `gpt-4o-mini` for OpenAI).
- Automatically fetches OpenAI API keys from a settings file if not provided directly.

### 🎮 Context-Aware Conversations
- Maintains chat history to enable logical, multi-step interactions.
- Allows easy management of context with commands like `/clear` and `/history`.

### 🛠️ Built-In Tools
- Includes functions to retrieve:
  - **Current Weather** for a location.
  - **Open Browser** to a provided website.
  - **Random Cat Facts** 🐱.
  - **Random Dog Facts** 🐶.
  - **Dad Jokes** 😂.
  - **Current System Date and Time**.

### 🎭 Customization
- Fully configurable LLM settings such as models, API endpoints, and keep-alive durations.

## Prerequisites 🔑

To use the script, ensure the following:
1. **PowerShell 5.1+** is installed on your system.
2. Access to **Ollama** or **OpenAI** endpoints:
   - Ollama: `http://localhost:11434`.
   - OpenAI: `https://api.openai.com`.
3. For OpenAI, ensure your API key is set in the `botSettings.json` file or passed as a parameter.

## Getting Started 🚀

### 📋 Parameters

| Parameter            | Description                                                                                  | Default Value        |
|----------------------|----------------------------------------------------------------------------------------------|----------------------|
| `-LLMProvider`       | Choose between `Ollama` and `OpenAI`.                                                       | `Ollama`             |
| `-OllamaModel`       | Model to use for Ollama.                                                                     | `mistral-nemo`       |
| `-OllamaKeepAlive`   | Keep-alive duration for the Ollama model.                                                    | `5m`                 |
| `-OpenAIModel`       | Model to use for OpenAI.                                                                     | `gpt-4o-mini`        |
| `-OpenAIApiKey`      | OpenAI API key. If not provided, fetched from `botSettings.json`.                            | N/A                  |
| `-SettingsFilePath`  | Path to the settings file for storing API keys and configurations.                           | `botSettings.json`   |

### 💻 Example Usage

1. Run the script with default settings:
   ```powershell
   .\ChatWithTools.ps1
   ```

2. Specify a different LLM provider and model:
   ```powershell
   .\ChatWithTools.ps1 -LLMProvider Ollama -OllamaModel mistral-xyz
   ```

## Commands 🗂️

| Command   | Description                          |
|-----------|--------------------------------------|
| `/history`| Displays chat history.               |
| `/clear`  | Clears the current context.          |
| `/save`   | Saves chat history to a file.        |
| `/load`   | Loads chat history from a file.      |
| `/help`   | Shows available commands.            |
| `/bye`    | Exits the script.                    |

## Tool Functions 🛠️

1. **Get-CurrentWeather**: Fetches the current weather for a location.
2. **Get-CatFact**: Provides a random fact about cats.
3. **Get-DogFact**: Provides a random fact about dogs.
4. **Get-DadJoke**: Fetches a random dad joke.
5. **Get-CurrentDate**: Returns today’s date.
6. **Get-CurrentTime**: Returns the current time.
7. **Open-DefaultBrowser** : Opens the system's default browser to the provided website.

## Why Use This Script? 💡

This script demonstrates:
- Integrating LLM APIs into PowerShell.
- Leveraging tools and context for smarter interactions.
- Extending functionality with fun and useful features.

## Contributing 📢

Contributions are welcome! Feel free to fork this repository, make improvements, and submit a pull request.

---

✨ Happy scripting! 🚀
