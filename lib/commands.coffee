#!/usr/bin/env coffee

pkg = require '../package.json'
program = require 'commander'
colors = require 'colors'
async = require 'async'
dir = require 'node-dir'
_ = require 'lodash'
fs = require 'fs-extra'
prompt = require 'prompt'

program.version(pkg.version)

program.command('update [crowdin translations path] [webapp translations path]')
  .description('Let\'s update those translation files!')
  .action (crowdinPath, webAppPath) ->

    # Perform action in series with async
    async.waterfall [
      (callback) ->
        # Get all files from crowdin directory
        dir.files crowdinPath, (err, crowdinFilePaths) ->
          throw err if err

          # Get all files from webapp translations directory
          dir.files webAppPath, (err, webAppFilePaths) ->
            throw err if err

            # Callback files for each directory
            callback(null, crowdinFilePaths, webAppFilePaths)
      (crowdinFilePaths, webAppFilePaths, callback) ->
        # find intersection fo files between the two directories
        intersection = []

        # push file names to arrays
        _.forEach crowdinFilePaths, (crowdinFilePath) ->
          _.forEach webAppFilePaths, (webAppFilePath) ->
            # if the file names are the same
            if crowdinFilePath.split('/').pop() is webAppFilePath.split('/').pop()
              # push object to intersection array
              intersection.push
                fileName: webAppFilePath.split('/').pop()
                crowdinPath: crowdinFilePath
                webAppPath: webAppFilePath

        # callback intersection of file names
        callback null, intersection
      (fileIntersection, callback) ->
        # prompt user to take action
        console.log fileIntersection.length + " files matched and are to ready to be updated."
        _.forEach fileIntersection, (file) ->
          console.log "Update: ".yellow, file.fileName
          console.log "Crowdin:", file.webAppPath
          console.log "WebApp: ", file.crowdinPath

        prompt.message = "mediatidy".yellow
        prompt.delimiter = ": ".green
        prompt.properties =
          yesno:
            default: 'no'
            message: 'Update above translation files?'
            required: true
            warning: "Must respond yes or no"
            validator: /y[es]*|n[o]?/

        # Start the prompt
        prompt.start()

        # get the simple yes or no property
        prompt.get ['yesno'], (err, result) =>
          if result.yesno.match(/yes/i)
            _.forEach fileIntersection, (file) ->
              fs.copy file.crowdinPath, file.webAppPath, (err) ->
                throw err if err
                console.log "UPDATED:".green, file.webAppPath
            callback null, 1
          else
            callback null, 0
    ], (err, results) ->
      throw err if err
      if results is 0
        console.log "No translation files were updated..."

program.parse(process.argv)

program.help() if program.args.length is 0
