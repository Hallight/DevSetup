# DevSetup

## git
### gitbash
[downloads page](https://git-scm.com/download/win)
```
cd ~
mkdir workspace
```

### bash profile
1. execute the following
```
cd ~/workspace
touch .bashrc
```
2. add the following to the file to be executed every time you start gitbash:
```
cd ~/workspace
eval "$(ssh-agent -s)"
```
3. restart gitbash

### ssh
1. generate an ssh key with [these instructions](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
2. tell github about new ssh key with [these instructions](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
3. add the following to the end of your .bashrc
```
ssh-add ~/.ssh/<PRIVATE_KEY_FILE>
```

### gpg
1. download a binary from [gnupg downloads](https://www.gnupg.org/download/)
2. create gpg key with [these instructions](https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key)
3. tell github about new gpg key with [these instructions](https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key#telling-git-about-your-gpg-key-1)
4. configure git with the following
```
git config --global --edit
```
```
[user]
  name = Matthew Hall
  email = mah13090@gmail.com
  signingkey = <GPG_KEY_ID>
[gpg]
  program = C:\\Program Files\\Git\\usr\\bin\\gpg.exe
[commit]
  gpgsign = true
[tag]
  gpgsign = true
```

### github desktop client
[download here](https://desktop.github.com/)

### github CLI
[download here](https://cli.github.com/)

## JavaScript
### visual studio code
[downloads page](https://code.visualstudio.com/download)

### node
1. install `node version manager (nvm)` by following [these instructions](https://github.com/coreybutler/nvm-windows/releases)
2. `nvm install lts`
3. `nvm use lts`

## Unreal Engine (w/ C++)
### Epic Games Launcher
[download here](https://store.epicgames.com/en-US/download)

### Visual Studio (free)
[download here](https://visualstudio.microsoft.com/downloads/)

include the following workloads:
- .NET desktop development
- Desktop development with C++
- Game development w/ C++

Will need Visual Studio 2018 for UE <5.0, otherwise can use 2022

### Jetbrains Rider (paid)
[download here](https://www.jetbrains.com/rider/download)

### Download required .NET, C++ libraries
1. Open your chosen IDE
2. Use the IDE to open the chosen C++ enabled UE project folder
3. Install any packages and libraries you are prompted for the project

## AWS
### Config (Root)
in `~/.aws/config`
```
[default]
region = us-west-2
output = json
```
in `~/.aws/credentials`
```
[default]
aws_access_key_id     = xxxx
aws_secret_access_key = xxxx

[your-app-profile]
aws_access_key_id     = xxxx
aws_secret_access_key = xxxx
```

### CLI
[instructions here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

`msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi`

### CDK
`npm i -g aws-cdk`

inside cdk folder `cdk init app --language typscript`

### Config (SSO)
in `~/.aws/config`
```
[default]
sso_session = my-sso
sso_account_id = 381492108521
sso_role_name = Admin Team
region = us-east-1
output = json

[sso-session my-sso]
sso_region = us-east-1
sso_start_url = https://d-9a6770bd00.awsapps.com/start/
sso_registration_scopes = sso:account:access
```

## Python
### Install Python
- Install pyenv. Check [Github](https://github.com/pyenv-win/pyenv-win) for instructions
- `Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process`
- `Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1"`
- Confirm installation `pyenv --version`
- Check available versions `pyenv install -l | findstr 3.11`
- Install `pyenv install 3.11.9`
- Set global python version `pyenv global 3.11.9`

Direct download from [python downloads](https://www.python.org/downloads/)
### Setup vitual environment
- `pip install virtualenv`
- cd into your project dir
- `virtualenv rr-data-pipelines`
- `.\rr-data-pipelines\Scripts\activate`
- to exit venv `deactivate`

### Add index URLs
- open `~/AppData/Roaming/pip/pip.ini`
- add extra-index-url = YOUR_URL

## AI
### Continue
- add to VSCode via extensions
- `.continue/config.json`
``` json
{
  "models": [
    {
      "title": "ollama",
      "model": "AUTODETECT",
      "provider": "ollama"
    },
    {
      "title": "Gemini 2.5 Flash-Lite Preview",
      "model": "gemini-2.5-flash-lite-preview-06-17",
      "provider": "gemini",
      "apiKey": "GOOGLE_API_KEY"
    },
    {
      "title": "Gemini 2.5 Flash",
      "model": "gemini-2.5-flash",
      "provider": "gemini",
      "apiKey": "GOOGLE_API_KEY"
    },
    {
      "title": "Gemini 2.0 Flash",
      "model": "gemini-2.0-flash",
      "provider": "gemini",
      "apiKey": "GOOGLE_API_KEY"
    }
  ],
  "tabAutocompleteModel": {
      "title": "ollama",
      "model": "AUTODETECT",
      "provider": "ollama"
  }
}
```

### Local Model
- Download [ollama](https://ollama.com/download)
- Pick a model [ollama search](https://ollama.com/search)
- Download the model `ollama pull deepseek-coder:6.7b`
- (Optional) stop ollama on startup
  - Press Win + R → type: shell:startup
  - See if there's a shortcut to ollama.exe in there → delete it.
- Start ollama `Start-Job -ScriptBlock { ollama serve }`
- End `Stop-Job -Name Job1`
- list active models `ollama ps`


### Aider
- Assuming Python installation and virtual env setup has occurred. navigate to specific venv and activate
- `python -m pip install aider-chat`
- setup your .env for Aider in your project repo
```
OPENAI_API_KEY=your-openai-key-here
OPENAI_API_BASE=https://ai-service.com # optional

AIDER_ANALYTICS=false # optional
AIDER_YES_ALWAYS=true #useful for automations and agentic actions
AIDER_MAP_TOKENS=4096 # Increase or decrease depending on repo/model
AIDER_LINT_CMD=npm run lint:me -- # Whatever your codebase lint command is
AIDER_TEST_CMD=cd src/app && npm run validate # Whatever your codebase test command is
AIDER_AUTO_LINT=true # Useful for automatically fixing problems after applying edits
AIDER_AUTO_TEST=true # Useful to validate edits automatically
AIDER_WATCH_FILES=true # Aider automatically takes actions on code comments including the word, Ai! or Ai?
AIDER_DARK_MODE=true
AIDER_EDITOR="code --wait" # Helpful for more reliable code edits
AIDER_AUTO_COMMITS=false # We should review it's outputs before committing (or make sure you have a good pre-commit hook)
AIDER_EDITOR_EDIT_FORMAT=diff # udiff is also good, default is whole file
AIDER_EDIT_FORMAT=diff # udiff is also good, default is whole file
AIDER_ARCHITECT=true #  Architect mode enhances the coding ability by reasoning before working to improve the code prompt
AIDER_STREAM=false # For models that do not support streaming
AIDER_MODEL=o3-mini # Current best of the best
AIDER_EDITOR_MODEL=o3-mini # Current best editor model
AIDER_WEAK_MODEL=gpt-4o # Weak model for MR commits
```

## Useful PowerShell Commands
- Current available commands `Get-Module -ListAvailable`
- Start background job `Start-Job -ScriptBlock { ollama serve }`
- stop background job `Stop-Job -Name Job1`
- determine location of PowerShell Profile file `echo $PROFILE`
- find command location `get-command python`
