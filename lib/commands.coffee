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
prettyjson = require 'prettyjson'

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
    prompt.get ['path', 'strings', 'crowdin_api_key', 'crowdin_project_identifier'], (error, result) ->
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
          console.log '==> '.cyan.bold + 'downloading latest translations...'

          # Attempt to build latest translations
          url = 'https://api.crowdin.com/api/project/' + program.projectid +
            '/export?key=' + program.key
          console.log 'building translations archive on crowdin...'
          request url, (error, response, body) ->
            if body.match(/error/ig)
              throw new Error 'Requested project does not exist or API key is not valid. Check your
                crowdup configuration.'.red
            else if body.match(/skipped/ig)
              console.log 'Translation build was skipped. Either no new translations to build or
                the build request is within the crowdin 30 minute limit. Check the translations or
                wait ~30 minutes.'.yellow
            else if body.match(/built/ig)
              console.log 'crowdin translation build was successful.'

            # Download latest translations
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
              # push object to intersection array
              intersection.push
                fileName: webAppFilePath.split('/').pop()
                crowdinPath: crowdinFilePath
                webAppPath: webAppFilePath

        # remove ignored files from array
        # ignored = [
        #   '.DS_Store'
        # ]
        # _.remove(intersection, (file) ->
        #   ignored.indexOf(file.fileName) > -1
        # )
        #
        # console.log intersection

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
              # Loop over fileIntersection asynchronously
              updateTranslations = (iteration) ->
                # copy overwriting current translations
                fs.copy fileIntersection[iteration].crowdinPath, fileIntersection[iteration].webAppPath, (err) ->
                  throw err if err
                  # ensure translated files have mode of 755
                  fs.chmod fileIntersection[iteration].webAppPath, '755', (err) ->
                    throw err if err
                    console.log "UPDATED:".green, fileIntersection[iteration].webAppPath
                    # callback on last loop
                    if fileIntersection.length is iteration + 1
                      callback null, 1
                    else
                      updateTranslations(iteration + 1)
              updateTranslations(0)
            else
              callback null, 0
    ], (err, results) ->
      throw err if err

      # remove translation files from tmp dir
      fs.remove '/tmp/translations*', (err) ->
        throw err if err

      # if no files were changed log to user
      if results is 0
        console.log "No translation files were updated..."

program.command('status')
  .description('Get translation status from crowdin')
  .action () ->
    console.log '==> '.cyan.bold + 'checking translations status...'
    # Attempt to get translation status
    url = 'https://api.crowdin.com/api/project/' + program.projectid +
      '/status?key=' + program.key + '&json'
    request url, (error, response, body) ->
      if body.match(/error/ig)
        throw new Error 'Requested project does not exist or API key is not valid. Check your
          crowdup configuration.'.red
      else
        body = JSON.parse(body)
        console.log 'Status Overview:'
        _.forEach body, (translation) ->
          console.log translation.name.yellow
          if translation.approved_progress is 100
            console.log "approved progress:   #{translation.approved_progress}% completed".green
          else
            console.log "approved progress:   #{translation.approved_progress}% completed".red

          if translation.translated_progress is 100
            console.log "translated progress: #{translation.translated_progress}% completed".green
          else
            console.log "translated progress: #{translation.translated_progress}% completed".red

        prompt.message = "crowdup".yellow
        prompt.delimiter = ": ".green
        prompt.properties =
          yesno:
            default: 'no'
            message: 'See all status details?'
            required: true
            warning: "Must respond yes or no"
            validator: /y[es]*|n[o]?/

        # Start the prompt
        prompt.start()

        # get the simple yes or no property
        prompt.get ['yesno'], (err, result) ->
          if result.yesno.match(/yes/i)

            # make json response pretty =)
            options = noColor: false
            _.forEach body, (translation) ->
              console.log '\n' + prettyjson.render(translation, options)

program.parse(process.argv)

program.help() if program.args.length is 0
