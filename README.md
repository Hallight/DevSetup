# DevSetup

## git
### gitbash
[downloads page](https://git-scm.com/download/win)
```
cd ~
mkdir workspace
```

### bash profile
```
cd ~/workspace
touch .bashrc
```
edit the file with:
```
cd ~/workspace
eval "$(ssh-agent -s)"
```
restart gitbash

### ssh


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

## JavaScript
### visual studio code

## Java


## Terraform


## C++