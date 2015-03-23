# crowdup

For anyone who wants to easily update their webapp translations files from crowdin,
**crowdup** is a project that helps update your translation via a simple command line interface.

This project is early in dev and a WIP. Please file issues!

## About

Point **crowdup** at your freshly downloaded crowdin translations and your webapp translation directory:

Example:

```
crowdup update ~/Download/crowdin-translations/ ~/Projects/webapp/app/i18n/
```

Then watch the magic happen!

![demo](https://i.imgur.com/waz8Tqw.gif)

* Matches translations based on filename.
* Gives user ability to overwrite existing webapp translations with those from crowdin downloaded translations.
* User has option to look over files to be updated and bail if something looks wrong without modifying anything.

Coming soon:
* Require paths in command line tool
* Detect if files need to be updated or not.
* Open crowdin zip and match files from archive.
* Pull translations from crowdin directly.

## Crowdin

At this point you must download your latest translations from crowdin and unpack the archive. **crowdup** needs to be pointed at this directory to function properly.

## Setup
### Dependencies

[NodeJS](http://nodejs.org/) is required to run **crowdup**. Find the installers and install the latest versions; if using Mac OSX consider installing [homebrew](http://brew.sh/) and easily install what you need with the following:  


```
$ brew install node
```

### Install

Be sure all [dependencies](#Dependencies) are install before installing **crowdup**.

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
