fs = require 'fs'

mongoose = require 'mongoose'
session = require 'express-session'
ConnectMongo = require 'connect-mongo'

MongoStore = ConnectMongo session

module.exports = (System) ->
  me = null
  sessionMiddleware = null
  mongoStore = null
  mongeese = {}

  getMongoose = (dbName = 'public') ->
    return mongeese[dbName] if mongeese[dbName]
    {ip, ports} = System.getService 'mongo'
    dbUrl = "mongodb://#{ip}:#{ports['27017/tcp']}/#{dbName}"
    console.log 'init DB', dbUrl
    conn = mongoose.createConnection dbUrl

    schemas = {}
    mongooseProxy =
      model: (name, schema) ->
        if schema?
          return schemas[name] if schemas[name]
          schemas[name] = conn.model name, schema
          return schemas[name]
        conn.model name
      Schema: mongoose.Schema
      conn: conn

    mongeese[dbName] = mongooseProxy

  mongo = System.getService 'mongo'

  init: (next) ->
    thisMongoose = getMongoose 'kerplunk'
    mongoStore = new MongoStore
      mongooseConnection: thisMongoose.conn
    sessionMiddleware = session
      resave: false
      saveUninitialized: true
      secret: 'foo'
      store: mongoStore
    next()

  noRestart: true
  getMongoose: getMongoose
  mongoose: -> mongoose
  store: -> mongoStore
  getSessionMiddleware: -> sessionMiddleware
