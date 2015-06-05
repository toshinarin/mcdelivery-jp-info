module.exports = class McDelivery
  shopName = 'マックデリバリー'
  q = require 'q'
  cheerio = require 'cheerio'
  request = require 'request'
  jarCache = undefined

  @shop:
    shopName: shopName
    url: 'https://mcdelivery.mcdonalds.com/jp/'
    keywords: ['mac', 'マック', 'mc']

  constructor: (@userName, @password) ->

  get: () ->
    d = q.defer()

    loginAndGet = (csrfValue) ->
      loginPromise = login(csrfValue)
      loginPromise.done (jar) ->
        jarCache = jar
        promise = getWithJar(jarCache)
        promise.done (message) ->
          d.resolve(message)
        promise.fail () ->
          jarCache = undefined
          d.reject("#{shopName}: 取得に失敗しました")

      loginPromise.fail (reason) ->
        jarCache = undefined
        d.reject(reason)

    promise = getWithJar(jarCache)
    promise.done (message) ->
      d.resolve(message)
    promise.fail (csrfValue) ->
      jarCache = undefined
      loginAndGet(csrfValue)

    return d.promise

  login = (csrfValue) ->
    d = q.defer()

    jar = request.jar()
    opt =
      jar: jar
      url: "https://mcdelivery.mcdonalds.com/jp/login.html"

    r = request.post(opt, (err, httpResponse, body) ->
      if err
        d.reject('ログインに失敗しました')
      else
        d.resolve(jar)
      return
    ).form
      userName: @userName
      password: @password
      rememberMe: 'true'
      _rememberMe: 'on'
      csrfValue: csrfValue

    return d.promise

  getWithJar = (jar) ->
    d = q.defer()
    if !jar
      d.reject "#{shopName}: 取得に失敗しました"
      return d.promise

    url = "https://mcdelivery.mcdonalds.com/jp/home.html"
    opt =
      jar: jar
      url: url

    request.get(opt, (err, httpResponse, body) ->
      return d.reject "#{shopName}: 取得に失敗しました" if err
      $ = cheerio.load(body)
      match = $(".address-status").text().match(/ご注文後およそ(.*)でお届けします。/)
      csrfValue = $('#form_login_masthead > input').val()
      if match and match.length == 2
        time = match[1]
        d.resolve "#{shopName}: #{time}"
      else
        d.reject csrfValue
      return
    )

    return d.promise
