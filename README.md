A barebones app for MacOS that handles downloading en masse from TNM Downloader.

## Install

### In terminal (easiest)

1. Open terminal
2. Paste the following:
```sh
curl -fsSL https://raw.githubusercontent.com/owenferg/oGet/main/install.sh | sh
```

### As a package
1. Visit the [releases page](https://github.com/owenferg/oGet/releases) and click the latest version's `.dmg` file to download
2. Open `oGet.dmg` and drag `oGet.app` into the applications folder
3. Open the app
4. **You will get blocked by MacOS from opening the app**. To override, open System Settings, visit Privacy and Security, scroll to the bottom to find the warning and click "Open anyway". This will open the app

## How to use
1. Visit [TNM Downloader](https://apps.nationalmap.gov/downloader/) and search for the products you would like to download
2. On the Products page, click the document icon to download a `.txt` file containing URLs to all product downloads you have selected (See below screenshot)

<img width="1244" height="1426" alt="image" src="https://github.com/user-attachments/assets/e52286e1-ac2c-4aa9-ac8d-0111d7c838e5" />

3. Drag `data.txt` into oGet to immediately start your bulk download
4. Once complete, click the folder icon to find your downloaded items
