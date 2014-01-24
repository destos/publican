module.exports =
    name: 'cityoftulsa'
    full_name: 'City of Tulsa Utilities'
    login:
        url: 'https://secure2.cityoftulsa.org/account/Login.aspx'
        sel: '#aspnetForm'
        inputs:
            '#ctl00_MainContent_txtAccountNo': ''
            '#ctl00_MainContent_password': ''
        # test: '#ctl00_MainContent_TextBox3'
        # test: ->
        #     this.fetchText('#contentBox > center > h2') is 'Account Information'
        test: ->
            @getCurrentUrl() is 'https://secure2.cityoftulsa.org/account/AccountInfo.aspx'
        # When the form submission is made harder by wonderful javascript validation we use a function
        handle_submit: ->
            # click da button!
            @mouseEvent('<click></click>', '#ctl00_MainContent_Button1')
    check_payment:
        url: 'https://secure2.cityoftulsa.org/account/AccountInfo.aspx'
        can_make_payment: false
        date:
            format: 'mm-dd-yyyy'
            sel: '#ctl00_MainContent_lblDateDue'
        owed:
            # sel: '#ctl00_MainContent_txtBalance'
            # for more complex lookups you can specify a function
            sel: ->
                '#ctl00_MainContent_txtBalance'
    make_payment: false
