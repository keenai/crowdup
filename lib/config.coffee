nconf = require 'nconf'
fs = require 'fs-extra'
path = require 'path'
_ = require 'lodash'

class Config
  @file: """
  #{process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE}/.crowdup
  """
  nconf.file @file

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
