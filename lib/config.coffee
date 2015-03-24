nconf = require 'nconf'
fs = require 'fs-extra'
path = require 'path'
_ = require 'lodash'

class Config
  @file: """
  #{process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE}/.crowdup
  """

  @fileDefault: "../config.json"

  try
    stats = fs.statSync @file

    if stats.isFile()
      nconf.file @file

  catch error
    try
      fs.copySync((path.resolve __dirname, @fileDefault), @file)
      stats = fs.statSync @file

      if stats.isFile()
        nconf.file @file

    catch error
      nconf.file path.resolve __dirname, @fileDefault
      console.log "using default config file, run \"crowdup config\" to create one"

  @check: ->
    true if nconf.get 'appPath'

  @get: (name) ->
    nconf.get name

  @set: (name, value) ->
    nconf.set name, value

  @save: (callback) ->
    nconf.save (error) ->
      callback? error

  constructor: ->

module.exports = Config
