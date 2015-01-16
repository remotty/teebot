querystring = require('querystring')
http = require('http')

module.exports = (robot) ->
  evaluate = (language, solution, callback) ->
    data = querystring.stringify(  
      language: language
      solution: solution
      key: process.env.REPL_KEY
    )

    options =
      host: process.env.REPL_HOST
      port: process.env.REPL_PORT
      path: '/run'
      method: 'POST'
      headers: 
        'Content-Type': 'application/x-www-form-urlencoded'
        'Content-Length': data.length

    req = http.request options, (res) -> 
      res.setEncoding('utf8')
      res.on 'data', (chunk) ->
        callback(chunk, language)

    req.write(data)
    req.end()

  build_head = (object, language) ->
    "#{language} (#{object.wallTime}ms) :\n```\n"

  build_body = (object) ->
    if object.exitCode == 0
      object.stdout
    else
      object.stderr

  build_tail = () ->
    "\n```"

  build_msg = (data, language) ->
    object = JSON.parse(data)
    return build_head(object, language) +
      build_body(object) +
      build_tail()

  handle_eval = (msg, language) ->
    evaluate msg.match[1], msg.match[2], (data, language) ->
      msg.send build_msg(data, language)
    
  robot.hear /eval (.*?) ([\s\S]*)$/i, handle_eval
  robot.hear /eval (.*?)\n```\n([\s\S]*)\n```/i, handle_eval

