# crowdup

For anyone who wants to easily update their app translations files from crowdin,
**crowdup** is a project that helps update your translation via a simple command line interface.

This project is early in dev and a WIP. Please file issues!

## Demo

[Configure](#use-with-crowdin-api!) then run `crowdup update` and watch the magic happen!

![demo](https://i.imgur.com/2xrKdrY.gif)

## About

**crowdup** matches translation files purely based on filename.  For instance, `../archive/en/en-US.json` will be matched with `../i18n/translated/en-US.json` and so forth. This might not work best for everyone; feel free to send a pull request to satisfy your scenario.

Features:
* Gives user ability to overwrite existing webapp translations with those from crowdin.
* Users can download via the corwdin api directly, or point **crowdup** at downloaded translations.
* User has option to look over files to be updated and bail if something looks wrong without modifying anything.
* Configuration is stored so updating translations in the future is super fast.

Coming soon:
* Detect translation matches based on sub folders where translation filenames are identical
* Ability to map translations files from archive to specific translation file locations
* Ability to ignore files
* Detect if files need to be updated or not.
* Better error detection and logging

## Setup
### Dependencies

[NodeJS](http://nodejs.org/) is required to run **crowdup**. Find the installers and install the latest versions; if using Mac OSX consider installing [homebrew](http://brew.sh/) and easily install what you need with the following:  


```
$ brew install node
```

### Install

Be sure all [dependencies](#Dependencies) are installed before installing **crowdup**.

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

### Use with crowdin api

Run `crowdup config` and add you app's translation directory, [crowdin api key](https://crowdin.com/page/api/authentication), and [crowdin project identifier](https://crowdin.com/page/api/authentication).  For an example:

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


### Use with downloaded crowdin files

Don't want to use the crowdin api? No problem. Point crowdup at your crowdin translation download (either zip or directory) and at your app translations directory:

```
crowdup update -c ~/Downloads/crowdin-translations.zip -a ~/Projects/webapp/app/i18n/
```
