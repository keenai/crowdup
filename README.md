# crowdup

**crowdup** is a project for anyone who wants to easily update their app translations files from Crowdin that helps update translations via a simple command line interface.

This project is early in development and a work in progress. Please file issues!

## Demo

[Configure](#use-with-crowdin-API) **crowdup**, then run `crowdup update` and watch the magic happen!

![demo](https://i.imgur.com/2xrKdrY.gif)

## About

**crowdup** matches translation files purely based on filename. For instance, `../archive/en/en-US.json` will be matched with `../i18n/translated/en-US.json` and so forth. This might not work best for everyone; feel free to send a pull request to satisfy your scenario.

Features:
* Gives users the ability to overwrite existing web app translations with those from Crowdin
* Users can build then download via the Crowdin API directly, or point **crowdup** at downloaded translations
* Users have the option to look over files to update and abort without modifying anything if something looks wrong
* **crowdup** stores user configurations, so updating translations in the future is super fast
* Check status of translations in Crowdin

Coming soon:
* Detect translation matches based on subfolders where translation filenames are identical
* Ability to map translation files from archive to specific translation file locations
* Ability to ignore files
* Detect if files need to be updated or not
* Better error detection and logging

## Setup
### Dependencies

**crowdup** requires [NodeJS](http://nodejs.org/). Find and install the latest versions of NodeJS; if you use Mac OS X, consider installing [homebrew](http://brew.sh/) to easily install what you need with the following command:  


```
$ brew install node
```

### Install

Be sure to install all [dependencies](#Dependencies) before installing **crowdup**.

```
$ sudo npm install -g crowdup
```

### Uninstall

```
$ sudo npm uninstall -g crowdup
```

## Usage

See **crowdup** help for a full list of commands.

```
$ crowdup --help
```

### Use with Crowdin API

Run `crowdup config` and add your app's translation directory, [Crowdin API key](https://crowdin.com/page/api/authentication), and [Crowdin project identifier](https://crowdin.com/page/api/authentication). For example:

```
$ crowdup config
crowdup: full path to app translations:  /Users/daniel/Projects/webapp/app/i18n
crowdup: crowdin api key found in account at crowdin.com:  37cb230570eb0bd1bc00860ff42c1ba3
crowdup: crowdin project id found in account at crowdin.com:  my_project
saved crowdup configuration to /Users/daniel/.crowdup
```

Now you can update translations on demand with:
```
$ crowdup update
```


### Use with downloaded Crowdin files

Don't want to use the Crowdin API? No problem. Point **crowdup** at your Crowdin translation download (either the .ZIP or directory) and at your app translations directory:

```
$ crowdup update -c ~/Downloads/crowdin-translations.zip -a ~/Projects/webapp/app/i18n/
```

### Check status of translations

Easily check the status of your translations with:

```
$ crowdup status
```
