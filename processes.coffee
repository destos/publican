config = require 'config'
moment = require 'moment'
nightmare = require('nightmarejs')

utils = require './utils.coffee'
get_portal_config = (portal_name) ->
    require "./portals/#{portal_name}.coffee"

# add processes to the passed in queue
exports.add_processes = (jobs) ->

    # jobs that relate to bill payment/management portals
    exports.portal_jobs = portal_jobs =
        payment_check : (portal_name) ->
            portal = utils.portal_config(portal_name)
            jobs.create('check_payment',
                # TODO: add the month/date to the title
                title: "Check payments on #{portal.full_name}"
                portal: portal_name
            ).priority('low')
            .attempts(config.check_payment_attempts)
            .on('complete', (id) ->
                console.log("Succesfully checked #{portal.full_name} for future payments.")
            ).on('failed', (id) ->
                console.log("Job failed")
            ).on('progress', (progress) ->
                process.stdout.write('\r  job #' + job.id + ' ' + progress + '% complete')
            )
    # how to process the different jobs

    jobs.process 'check_payment', (job, done) ->
        portal_name = job.data.portal
        # portal = get_portal_config(portal_name)
        # Do casper call
        try
            casper = nightmare.nightmare
                test: false
                args: [
                    'runner.coffee'
                    ['portal', portal_name]
                ]
        catch e
            done e

        timeout = setTimeout ->
            done('timeout triggered')
            debugger
            casper.close()
        , config.casper_timeout

        # watch for messages from casper
        casper.notifyCasperMessage = (msg) ->
            switch (msg.type)
                when 'log'
                    job.log(msg.msg)
                when 'done'
                    # store retrieved data (payment amount, date, etc.)
                    # job.log(portal_name)
                    # set another future check payment date
                    # TODO: update to a couple days after due date
                    month = moment.duration(1, 'months').valueOf()
                    portal_jobs.payment_check(portal_name).delay(month).save()
                    clearTimeout(timeout)
                    done()
                when 'failed'
                    done('didnt work out yo')

    # jobs.process 'make_payment', (job, done) ->
    #   # run casper call to make a payment with stored value

    return @
