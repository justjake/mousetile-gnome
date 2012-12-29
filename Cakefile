# Oh shit, a build system has appeared
# Yes, it is silly that we're using Node to compile for yet another command-line JS env.
# No, I shouldn't port Coffeescript to GJS. That would be silly.

{spawn, exec} = require 'child_process'

run = (args, cb) ->
    proc = spawn('coffee', args)
    proc.stderr.on 'data', (buffer) -> console.log(buffer.toString())
    proc.on        'exit', (status) ->
        process.exit(1) if status != 0
        cb() if typeof cb is 'function'

task 'build', 'compile the Mousetile library and sample app', build = ->
    args = ['--compile', '--bare']
    # build libs to output dir
    run args.concat('-o', 'Mousetile/', 'src/')
    # build app in-place
    run args.concat('app.coffee')

task 'run', 'run the sample app', ->
    proc = spawn('gjs', ['app.js'])
