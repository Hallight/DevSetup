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
1. install `node version manager (nvm)` by following [these instructions](https://github.com/nvm-sh/nvm)
2. `nvm install --lts`

## Unreal Engine (w/ C++)
### Epic Games Launcher
[download here](https://store.epicgames.com/en-US/download)

### Visual Studio (free)
[download here](https://visualstudio.microsoft.com/downloads/)

include "game development w/ c++" plugin during installation

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


## Java


## Terraform

