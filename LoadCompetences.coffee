db = require './db'
csv = require 'csvtojson'
Promise = require 'bluebird'
_ = require 'lodash'

currentMat = undefined

insertDetail = () ->
  setAndCheckMatiere = (data, matieres) ->
    if data.field1 is '' and data.field2 isnt '' then return Promise.resolve()
    # console.log "-->", _.last(data.field1.split('-'))
    # matieres.forEach (matiere) -> console.log "-->", matiere.ec.nom
    if data.field1 isnt ''
      currentMat = _.last(data.field1.split('-'))
    console.log "--> ", _.find matieres, {ec: {nom: 'AGP'}, niveau: data.field4}
    res = _.find matieres, {ec: {nom: currentMat}, terme: {terme: data.field3}, niveau: data.field4}

    unless res
      return Promise.reject("Erreur sur #{currentMat}, #{data.field3}, #{data.field4}")

    # res = _.find matieres, {'ec.nom': _.last(data.field1.split('-'))}
    # console.log '--->', res
    # #
    #   unless res
    #     return Promise.reject("Matière introuvable #{data.field1}")
    #   if data.field3 isnt res.terme.terme
    #     return Promise.reject("Compétence introuvable #{data.field3}")
    #
    return Promise.resolve()

  setSemestre = (sem) ->
    # console.log "Ajout Sem", sem
    if sem is '' then return Promise.resolve()
    if currentSemestre?
      # console.log "-->", currentSemestre
      currentSemestre.save()
      .then () ->
        db.Semestre.create({nom: sem})
        .then (sem) ->
          currentSemestre = sem
          Promise.resolve()
    else
      db.Semestre.create({nom: sem})
      .then (sem) ->
        currentSemestre = sem
        Promise.resolve()


  setUE = (uneUE) ->
    # console.log "Ajout ue", uneUE
    if uneUE is '' then return Promise.resolve()
    if currentUE?
      currentUE.save()
      .then () ->
        db.UE.create({nom: uneUE})
        .then (lue) ->
          currentUE = lue
          currentSemestre.ues.push lue
          Promise.resolve()
    else
      db.UE.create({nom: uneUE})
      .then (lue) ->
        currentUE = lue
        currentSemestre.ues.push lue
        Promise.resolve()

  setEnseignant = (ens) ->
    if allEns[ens]? then return Promise.resolve(allEns[ens])
    db.Enseignant.create({nom: ens})
    .then (res) ->
      allEns[ens] = res
      Promise.resolve(res)

  setECandCompetences = (ens, data) ->
    # name : data.field4
    # C11-15, C21-C29, C31-C37 : data.field8 - data.field28
    getComp = (field, idx, ec) ->
      console.log 'Nouvelle comp'
      return {
        ec: ec
        terme: competencesIndices[idx]
        niveau: field
      }

    # console.log "ajout", data.field4,  ens

    db.EC.create({nom: data.field4, responsable: ens})
    .then (ec) ->

      currentUE.ecs.push ec
      inserts = []

      if data.field8 isnt '' then inserts.push(getComp(data.field8, 0, ec))
      if data.field9 isnt '' then inserts.push(getComp(data.field9, 1, ec))
      if data.field10 isnt '' then inserts.push(getComp(data.field10, 2, ec))
      if data.field11 isnt '' then inserts.push(getComp(data.field11, 3, ec))
      if data.field12 isnt '' then inserts.push(getComp(data.field12, 4, ec))
      if data.field13 isnt '' then inserts.push(getComp(data.field13, 5, ec))
      if data.field14 isnt '' then inserts.push(getComp(data.field14, 6, ec))
      if data.field15 isnt '' then inserts.push(getComp(data.field15, 7, ec))
      if data.field16 isnt '' then inserts.push(getComp(data.field16, 8, ec))
      if data.field17 isnt '' then inserts.push(getComp(data.field17, 9, ec))
      if data.field18 isnt '' then inserts.push(getComp(data.field18, 10, ec))
      if data.field19 isnt '' then inserts.push(getComp(data.field19, 11, ec))
      if data.field20 isnt '' then inserts.push(getComp(data.field20, 12, ec))
      if data.field21 isnt '' then inserts.push(getComp(data.field21, 13, ec))
      if data.field22 isnt '' then inserts.push(getComp(data.field22, 14, ec))
      if data.field23 isnt '' then inserts.push(getComp(data.field23, 15, ec))
      if data.field24 isnt '' then inserts.push(getComp(data.field24, 16, ec))
      if data.field25 isnt '' then inserts.push(getComp(data.field25, 17, ec))
      if data.field26 isnt '' then inserts.push(getComp(data.field26, 18, ec))
      if data.field27 isnt '' then inserts.push(getComp(data.field27, 19, ec))
      if data.field28 isnt '' then inserts.push(getComp(data.field28, 20, ec))

      console.log "comp", inserts
      Promise.map inserts, (insert) ->
        console.log "Ajout", insert
        db.NiveauCompetence.create(insert)

  readCsv = ->
    new Promise (resolve, reject) ->
      datas = []

      csv({flatKeys: true, delimiter: ";", noheader: true})
      .fromFile('./TC\ DetailCompetences\ 2017-12-04.csv')
      .on 'json', (data) ->
        datas.push data
      .on 'done', (error) ->
        if error
          return reject error
        resolve(datas)

  loadDataBase = ->
    db.NiveauCompetence
    .find()
    .populate 'terme'
    .populate 'ec'
    .exec()

  Promise.all [
    readCsv()
    loadDataBase()
  ]
  .then ([datas, matieres]) ->
    # console.log "matieres", matieres
    Promise.mapSeries datas, (data) ->
      setAndCheckMatiere(data, matieres)
      # .then () ->
      #   setUE(data.field2)
      # .then () ->
      #   setEnseignant(data.field7)
      # .then (ens) ->
      #   setECandCompetences(ens, data)

db.connect()
.then () ->
  return Promise.all [
    db.NiveauCompetence.update({}, {$set: {capacités: [], connaissances: []}}, multi: true).exec()
    db.Vocabulaire.remove({}).exec()
  ]
  .then insertDetail

.catch (err) ->
  console.log("erreur", err)
.finally () ->
  Promise.all [
    # currentSemestre.save()
    # currentUE.save()
  ]
  .then () ->
    db.disconnect()
