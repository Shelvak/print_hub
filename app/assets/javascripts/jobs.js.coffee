@Jobs =
  jobs: {},
  pagesList: {},
  pricesList: {},
  oddPagesTypes: {},

  getDataFromPrintJobs: (attr)->
    JSON.parse(document.querySelector('.jobs-container').dataset[attr])

  loadPricesData: ->
    @Jobs.pricesList = @Jobs.getDataFromPrintJobs('pricesList')
    @Jobs.oddPagesTypes = @Jobs.getDataFromPrintJobs('oddPagesTypes')

  assignDataToJob: (job)->
    @Jobs.jobs[job.id] ||= {
      copies: 0,
      oddPages: 0,
      evenPages: 0,
      rangePages: 0,
      pricePerCopy: 0.0,
      price: 0.0,
      printJobType: '',
      stock: 0
    }

  listenRangeChanges: ->
    $(document).on 'change blur', '.js-page-ranges', ->
      $element = $(this)
      elementValue = this.value
      [validRanges, maxPage, rangePages] = [true, null, 0]
      pages = parseInt($element.parents('.js-printable-job').find('.js-job-pages').val(), 10)
      ranges = elementValue.trim().split(/\s*,\s*/).sort (r1, r2)->
        r1Value = parseInt(r1.match(/^\d+/), 10) || 0
        r2Value = parseInt(r2.match(/^\d+/), 10) || 0

        r1Value - r2Value

      _.each ranges, (r, _i)->
        data = r.match /^(\d+)(-(\d+))?$/
        n1 = parseInt(data[1], 10) if data
        n2 = parseInt(data[3], 10) if data

        validRanges = validRanges && n1 && n1 > 0 && (!n2 || n1 < n2) && (!maxPage || maxPage < n1)

        maxPage = n2 || n1
        rangePages += if n2 then n2 + 1 - n1 else 1

      controlGroup = $element.parents('.control-group')

      if (/^\s*$/.test(elementValue) || validRanges) && (!pages || !maxPage || pages >= maxPage)
        controlGroup.removeClass('error')

        if /^\s*$/.test(elementValue) && pages
          @Jobs.jobs[this.id].rangePages = pages
          @Jobs.reCalcPages(this)
        else if !/^\s*$/.test(elementValue) && validRanges
          @Jobs.jobs[this.id].rangePages = rangePages
          @Jobs.reCalcPages(this)
      else
        controlGroup.addClass('error')

  updatePricePerCopyForJob: (job)->
      jobStorage = @Jobs.jobs[job.id]
      jobType = job.querySelector('.js-print_job_type-selector').value

      jobStorage.printJobType = jobType
      jobStorage.pricePerCopy = PriceChooser.choose(
        @Jobs.pricesList[jobType],
        @Jobs.pagesList[jobType] || 0
      )

  changeMoneyTitleAndBadge: (job)->
      jobPrice = @Jobs.jobs[job.id].price.toFixed(3)
      money = job.querySelector('span.money')
      regEx = /(\d+\.\d+)$/

      money.setAttribute(
        'title',
        Util.replaceWithRegEx(money.getAttribute('title'), regEx, jobPrice)
      )
      money.innerHTML = Util.replaceWithRegEx(money.innerText, regEx, jobPrice)

  updateCopiesForJob: (job) ->
    jobStorage = @Jobs.jobs[job.id]
    copies = parseInt(job.querySelector('.js-job-copies').value, 10)
    rangePages = jobStorage.rangePages

    if rangePages == 0
      rangePages = parseInt(job.querySelector('.js-job-pages').value, 10)
      jobStorage.rangePages = rangePages

    oddPages = rangePages % 2
    evenPages = rangePages - oddPages

    jobStorage.oddPages = copies * oddPages
    jobStorage.evenPages = copies * evenPages

  updateGlobalCopies: ->
    pagesList = {}
    _.each @Jobs.jobs, (jobStorage, _id)->
      printJobType = jobStorage.printJobType
      oddPagesType = @Jobs.oddPagesTypes[printJobType] || printJobType

      pagesList[oddPagesType] ||= 0
      pagesList[oddPagesType] += jobStorage.oddPages || 0
      pagesList[printJobType] ||= 0
      pagesList[printJobType] += jobStorage.evenPages || 0

    @Jobs.pagesList = pagesList

  updatePriceForJob: (job)->
    # Has to run before others
    evenPagesPrice = @Jobs.updatePricePerCopyForJob(job)

    jobStorage = @Jobs.jobs[job.id]
    jobType = jobStorage.printJobType
    oddPagesType = @Jobs.oddPagesTypes[jobType] || jobType
    oddPages = jobStorage.oddPages
    evenPages = jobStorage.evenPages

    oddPagesPrice = PriceChooser.choose(
      @Jobs.pricesList[oddPagesType],
      @Jobs.pagesList[oddPagesType] || 0
    )

    jobStorage.price = (
      evenPagesPrice * evenPages + oddPagesPrice * oddPages
    )

  updatePriceToAllJobs: ->
    _.each document.querySelectorAll('.js-printable-job'), (job, _i) ->
      @Jobs.updatePriceForJob(job)
      @Jobs.changeMoneyTitleAndBadge(job)

  updateGlobalPrice: ->
    @Jobs.globalPrice = _.reduce(
      _.values(@Jobs.jobs),
      (memo, job)-> memo + job.price,
      0.0
    )

  updateTotalPrices: ->
    Print.updateVisualTotallPrices()

  reCalcPrices: ->
    @Jobs.updatePriceToAllJobs()
    @Jobs.updateGlobalPrice()
    @Jobs.updateTotalPrices()

  reCalcEverything: ->
    console.log('milongueando')
    _.each document.querySelectorAll('.js-printable-job'), (job, _i) ->
      @Jobs.updateCopiesForJob(job)

    @Jobs.updateGlobalCopies()
    @Jobs.reCalcPrices()

  reCalcPages: (job)->
    oldPageList = _.clone(@Jobs.pagesList)
    needToReCalcAll = false

    @Jobs.updateCopiesForJob(job)
    @Jobs.updateGlobalCopies()

    _.each @Jobs.pageList, (pages, jobType) ->
      oldPages = oldPageList[jobType] || 0
      printJobPrice = @Jobs.pricesList[jobType]

      if (
        PriceChooser.choose(printJobPrice, oldPages).toFixed(3) !=
          PriceChooser.choose(printJobPrice, pages).toFixed(3)
      )
        needToReCalcAll = true
        return

    if needToReCalcAll
      @Jobs.updatePriceToAllJobs()
    else
      @Jobs.updatePriceForJob(job)

    @Jobs.updateGlobalPrice()
    @Jobs.updateTotalPrices()








