#!/usr/bin/env coffee

pkg = require '../package.json'
program = require 'commander'
colors = require 'colors'
async = require 'async'
dir = require 'node-dir'
_ = require 'lodash'
fs = require 'fs-extra'
prompt = require 'prompt'
Config = require '../lib/config'
request = require 'request'
progress = require 'request-progress'
ProgressBar = require 'progress'
AdmZip = require 'adm-zip'

program.version(pkg.version)

program
  .option('-k, --key <key>', 'crowdin api key', Config.get('crowdin_api_key'))
  .option('-p, --projectid <projectid>', 'crowdin project id', Config.get('crowdin_project_identifier'))
  .option('-c, --crowdin <crowdin>', 'full path to crowdin translations download')
  .option('-a, --app <app>', 'full path to app translation files', Config.get('appPath'))

program
  .command('config')
  .description("Update configuration file at #{Config.file}")
  .action ->
    prompt.message = "crowdup".yellow
    prompt.delimiter = ": ".green
    prompt.properties =
      path:
        description: 'full path to app translations'
        message: 'example: /Users/daniel/Projects/webapp/app/i18n/'
        default: program.app
        pattern: /^\/\w+/
        required: true
      crowdin_api_key:
        description: 'crowdin api key found in account at crowdin.com'
        message: 'example: 16bb185580fb0bd4bc10760de84c9da5'
        default: program.key
        required: false
      crowdin_project_identifier:
        description: 'crowdin project id found in account at crowdin.com'
        message: 'example: my_project'
        default: program.projectid
        required: false

    saveConfig = (result) ->
      # remove trailing forward slash for app path
      result.path = result.path.replace(/\/$/, "")

      # set data
      Config.set 'appPath', result?.path or program.app-path
      Config.set 'crowdin_api_key', result?.crowdin_api_key or program.key
      Config.set 'crowdin_project_identifier', result?.crowdin_project_identifier or program.projectid

      # save to config file
      Config.save (error) ->
        console.log error.message if error?
        console.log "saved crowdup configuration to #{Config.file}"

    prompt.start()
    prompt.get ['path', 'crowdin_api_key', 'crowdin_project_identifier'], (error, result) ->
      saveConfig result unless error?

program.command('update')
  .description('Let\'s update those translation files!')
  .action () ->

    # Perform action in series with async
    async.waterfall [
      (callback) ->

        if program.crowdin
          callback null, program.crowdin
        else
          # Download latest translations
          console.log '==> '.cyan.bold + 'downloading latest translations...'
          url = 'https://api.crowdin.com/api/project/' + program.projectid +
            '/download/all.zip?key=' + program.key
          archive = '/tmp/translations.zip'

          bar = new ProgressBar('downloading [:bar] :percent :etas',
            complete: '='
            incomplete: ' '
            width: 46
            total: 1)

          progress(request(url),
            throttle: 200
            delay: 100).on('progress', (state) ->
            bar.total = state.total
            bar.tick state.received
          ).on('error', (err) ->
            throw err if err
          ).pipe(fs.createWriteStream(archive)).on('error', (err) ->
            throw err if err
          ).on 'close', (err) ->
            throw err if err
            console.log archive + ' has successfully been downloaded.'
            callback null, archive

      (archive, callback) ->
        # extract archive
        if fs.lstatSync(archive).isFile()
          console.log '==> '.cyan.bold + 'extracting translations zip archive...'
          extractTo = '/tmp/translations'
          zip = new AdmZip(archive)
          zip.extractAllTo extractTo, true
          console.log 'translations zip file successfully extracted'
          callback null, extractTo
        else
          callback null, archive
      (archive, callback) ->
        console.log '==> '.cyan.bold + 'looking for translation file matches...'
        # Get all files from crowdin directory
        dir.files archive, (err, crowdinFilePaths) ->
          throw err if err

          # Get all files from webapp translations directory
          dir.files program.app, (err, webAppFilePaths) ->
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
              # if webAppFilePath.split('/').pop().indexOf('.DS_Store') is -1
                # push object to intersection array
                intersection.push
                  fileName: webAppFilePath.split('/').pop()
                  crowdinPath: crowdinFilePath
                  webAppPath: webAppFilePath

        # remove ignored files from array
        ignored = [
          '.DS_Store'
        ]
        _.remove(intersection, (file) ->
          ignored.indexOf(file.fileName) > -1
        )

        # callback intersection of file names
        callback null, intersection
      (fileIntersection, callback) ->

        # If no intersecting files let's bail!
        if fileIntersection.length is 0
          callback(null, 0)
        else
          # prompt user to take action
          console.log fileIntersection.length + " files matched and are to ready to be updated."
          _.forEach fileIntersection, (file) ->
            console.log "Update:  ".yellow, file.fileName
            console.log "App:     ", file.webAppPath
            console.log "Crowdin: ", file.crowdinPath

          prompt.message = "crowdup".yellow
          prompt.delimiter = ": ".green
          prompt.properties =
            yesno:
              default: 'no'
              message: 'Update translation files?'
              required: true
              warning: "Must respond yes or no"
              validator: /y[es]*|n[o]?/

          # Start the prompt
          prompt.start()

          # get the simple yes or no property
          prompt.get ['yesno'], (err, result) ->
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
