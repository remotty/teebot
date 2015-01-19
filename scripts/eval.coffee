# Description:
# None
#
# Dependencies:
# None
#
# Configuration:
# None
#
# Commands:
# hubot (ev|eval) <lanugage> <code> - return evaluation result of <code> by <language> interpreter.
# hubot <language> <code> - alias of eval|ev
# hubot (ev|eval) sample <language> - evaluate sample code
# hubot (ev|eval) help - show usage of eval plugin
# hubot (ev|eval) show - show information of eval plugin
#
# Author:
# nacyot

querystring = require('querystring')
http = require('http')
fs = require('fs');
lodash = require('lodash')

Evaluator = (->
  languages = ['ruby', 'javascript', 'coffeescript', 'typescript', 'python',
    'csharp', 'fsharp', 'java', 'groovy', 'clojure', 'scala', 'haskell',
    'ocaml', 'racket', 'lisp', 'c', 'cpp', 'nasm', 'gas', 'bash', 'arm'
    'r', 'rust', 'erlang', 'elixir', 'go', 'julia', 'lua', 'php', 'perl']

  unescape = (code) ->
    return code.replace(/&amp;/g, "&").
      replace(/&lt;/g, "<").
      replace(/&gt;/g, ">")
      

  evaluate = (language, solution, callback) ->
    data = querystring.stringify(  
      language: language
      solution: unescape(solution)
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

  build_head = (msg, object, language) ->
    user = msg.message.user.name
    "@#{user} #{language} (#{object.wallTime}ms) :\n```\n"

  build_body = (object) ->
    if object.exitCode == 0
      object.stdout
    else
      object.stderr

  build_tail = () ->
    "\n```"

  build_msg = (msg, data, language) ->
    if data == undefined or language == undefined
      return "Something goes wrong."
    
    object = JSON.parse(data)
    return build_head(msg, object, language) +
      build_body(object) +
      build_tail()

  handle_eval = (msg) ->
    language = msg.match[1]
    code = msg.match[2]

    if (language not in languages)
      return undefined

    evaluate language, code, (data, language) ->
      msg.send build_msg(msg, data, language)
      
  handle_sample = (msg) ->
    language = msg.match[1]

    if (language not in languages)
      return undefined

    fs.readFile "./scripts/eval/sample/#{language}", "utf-8", (err, code) ->
      if (err)
        console.log(err)
        msg.send "Something goes wrong"
        return undefined

      evaluate language, code, (data, language) ->
        msg.send "#{language} code: \n```\n#{code}\n```\n" +
          build_msg(msg, data, language)

  help_message = """
    Usage:

    Standard - 

    > [bot] ev [language] [codea]
    > [bot] eval [language] [code]
    > hubot eval ruby puts 'Hello, world!'

    Use quote - 

    > [bot] eval [language]
    > \\```
    > [code]
    > ```
    (remove \\)

    or Shortcut

    > [bot] [language] [code]

    langs command show list of language which can eval

    > [bot] eval languages
    > [bot] eval langs
    > [bot] eval langs [filter]

    sample command show hello world code of target language

    > [bot] eval sample [language]
    > hubot eval sample ruby
    """

  return {
    languages: languages
    handle_eval: handle_eval
    handle_sample: handle_sample
    help_message: help_message
  }
)()

module.exports = (robot) ->
  robot.respond /(?:eval|ev) help/, (msg) ->
    msg.send Evaluator.help_message

  robot.respond /(?:eval|ev) info/, (msg) ->
    msg.send """
    This is part of remotty/teebot. Please check
    https://github.com/remotty/teebot/blob/master/scripts/eval.coffee file.
    """
  
  robot.respond /(?:eval|ev) (?:langs|languages)$/, (msg) ->
    msg.send "> " + Evaluator.languages.join(", ")

  robot.respond /(?:eval|ev) (?:langs|languages) (.*?)$/, (msg) ->
    re = new RegExp(msg.match[1], "i")
    filtered_languages = lodash.filter Evaluator.languages, (lang) ->
      re.test(lang)
      
    msg.send filtered_languages.join(", ")

  robot.respond /(?:eval|ev) sample (.*?)$/i, Evaluator.handle_sample
      
  robot.respond /(?:eval|ev) (.*?) ([\s\S]*)$/i, Evaluator.handle_eval
  robot.respond /(?:eval|ev) (.*?)\n```\n([\s\S]*)\n```/i, Evaluator.handle_eval

  robot.respond ///^(#{Evaluator.languages.join("|")}) ([\s\S]*)$///i,
    Evaluator.handle_eval
    
  robot.respond ///^(#{Evaluator.languages.join("|")})\n```\n([\s\S]*)\n```///i,
    Evaluator.handle_eval
