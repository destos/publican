lazy = require 'lazy.js'
async = require 'async'
kue = require 'kue'

config = require 'config'

kue.app.listen(3000)
# console.dir config
# load configs
jobs = kue.createQueue()

processes = require('./processes.coffee').add_processes(jobs)

# get delayed and active jobs
async.parallel([(cb) ->
    kue.Job.rangeByType 'check_payment', 'active', 0, 0, 0, cb
, (cb) ->
    kue.Job.rangeByType 'check_payment', 'delayed', 0, 0, 0, cb
], (err, jobs) ->
    throw err if err
    current_jobs = lazy(jobs).flatten()
    debugger
    # check for scheduled payment date lookup tasks
    # loop through all active portals
    lazy(config.active_portals).each (portal_name) ->
        try
            existing_job = current_jobs.find (job) ->
                return job.data.portal is portal_name
            if existing_job
                existing_job.log('Prevented the start of another payment check while this job was waiting')
                throw "A job is already running for #{portal_name}"
            else
                console.log "starting new job for #{portal_name}"
                processes.portal_jobs.payment_check(portal_name).save()
        catch e
            console.info(e)
)
