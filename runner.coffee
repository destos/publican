utils = require './utils.coffee'

casper = require('casper').create
    verbose: true
    logLevel: 'debug'
    # pageSettings:
    #      # loadImages:  false       # The WebPage instance used by Casper will
    #      # loadPlugins: false         # use these settings
    #      userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.94 Safari/537.4'

fs = require 'fs'
moment = require 'moment'

# print out all the messages in the headless browser context
casper.on('remote.message', (msg) ->
    this.echo('remote message caught: ' + msg)
)

# print out all the messages in the headless browser context
casper.on("page.error", (msg, trace) ->
    this.echo("Page Error: " + msg, "ERROR")
)

# utilities
save_cookies = (conf) ->
    cookies = JSON.stringify(phantom.cookies)
    fs.write("cookies/#{conf.name}.json", cookies, 644)

restore_cookies = (conf) ->
    try
        cookie_file = fs.read("cookies/#{conf.name}.json")
        phantom.cookies = JSON.parse()
    catch e

screenshot = (conf, sel) ->
    @waitForSelector(sel, (->
        timestamp = moment().unix()
        filename = "screenshots/#{conf.name}/#{sel}-#{timestamp}.jpg"
        @captureSelector filename, sel, format: 'jpg'
        @echo "Saved screenshot of #{@getCurrentUrl()} to #{filename}"
    ), (->
        @die("Timeout reached when saving screenshot")
        @exit()
    ), 12000)

# proceedures
login_check = (conf) ->
    restore_cookies(conf)
    casper.start conf.check_payment.url, ->
        # wait for redirects
        if @getCurrentUrl() is not conf.check_payment.url
            login(conf)
        else
            @sendMessageToParent({type: 'log', msg: 'already logged in'})
            @sendMessageToParent({type: 'done'})

login = (conf) ->
    casper.start conf.login.url, ->
        @sendMessageToParent({type: 'log', msg: 'logging into portal'})
        js_bs = typeof conf.login.handle_submit is 'function'
        # submit form if not js bull shit
        @fillSelectors(conf.login.sel, conf.login.inputs, not js_bs)
        if js_bs
            conf.login.handle_submit.call @

    casper.then ->
        # temp screenshot
        screenshot.call(@, conf, '#contentBox')
        # check if we actually logged in
        if typeof conf.login.test is 'function'
            @echo conf.login.test.call @, 'INFO'
        else if typeof conf.login.test is 'string'
            if @exists(conf.login.test)
                @sendMessageToParent({type: 'log', msg: 'logged in succesfully'})
                @sendMessageToParent({type: 'done'})
            else
                @sendMessageToParent({type: 'log', msg: 'unable to login'})
                @sendMessageToParent({type: 'failed'})
        save_cookies(conf)
        # this.evaluateOrDie ->
        #     return /logged in/.match(document.title)
        # , 'not authenticated')

# login(service_config)
if not config = casper.cli.get('portal')
    throw new Error 'no config file passed'

login_check(utils.portal_config(config))

casper.run()
