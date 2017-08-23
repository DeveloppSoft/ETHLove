// TODO clean that piece of code
// TODO past events (bug with metamask)
// DISCLAIMER: be kind, I made that in just one day ;)

let accept_bid
let divorce_bid

function onError(e) {
  console.log(e)
  $('#error_content').text(e)
  $('#error_generic').show()
}

function onSuccess(r) {
  console.log(r)
  Materialize.toast('Transaction passed, please wait', 2000)
}

$(document).ready(function() {
  $('.collapsible').collapsible();

  $('#witness_btn').click(function () {
    witness = $('#witness_addr').val()
    love.addWitness(witness, function (e, r) {
      if (e) {
        onError(e)
        throw e
      }
      if (typeof r.address !== 'undefined') {
        onSuccess(r)
      }
    })
  })

  $('#initialization_btn').click(function () {
    love.endInitialization(function (e, r) {
      if (e) {
        onError(e)
        throw e
      }
      onSuccess(r)
    })
  })

  $('#accept_btn').click(function () {
    love.acceptUnion({value: accept_bid}, function (e, r) {
      if (e) {
        onError(e)
        throw e
      }
      onSuccess(r)
    })
  })

  $('#refund_btn').click(function () {
    love.refund(function (e, r) {
      if (e) {
        onError(e)
        throw e
      }
      onSuccess(r)
    })
  })

  $('#divorce_btn').click(function () {
    love.askDivorce({value: divorce_bid}, function (e, r) {
      if (e) {
        onError(e)
        throw e
      }
      onSuccess(r)
    })
  })


  $('#load_btn').click(function () {
    love = web3.eth.contract(abi).at($('#agreement_addr').val())

    $('#loader').hide()
    $('#control').show()

    // Welcome to the callback hell :(
    love.isInitialized(function (e, r) {
      if (e) throw e
      initialized = r

      love.isMarried(function (e, r) {
        if (e) throw e
        married = r

        love.isDivorced(function (e, r) {
          if (e) throw e
          divorced = r

          love.party_one(function (e, r) {
            if (e) throw e
            party_one = r

            love.party_two(function (e, r) {
              if (e) throw e
              party_two = r

              love.url_document(function (e, r) {
                if (e) throw e
                url_document = web3.toUtf8(r)

                love.refund_on(function (e, r) {
                  if (e) throw e
                  refund_on = r

                  love.required_signatures(function (e, r) {
                    if (e) throw e
                    required_signatures = r

                    love.ACCEPT_BID(function (e, r) {
                      if (e) throw e
                      accept_bid = r

                      love.DIVORCE_BID(function (e, r) {
                        if (e) throw e
                        divorce_bid = r

                        if (!initialized) {
                          $('#status_state').text('Waiting for initialization')
                        } else if (initialized && !married && !divorced) {
                          $('#status_state').text('Waiting for confirmations, remaining: ' + String(required_signatures))
                        } else if (married) {
                          $('#status_state').text('Married')
                        } else if (divorced) {
                          $('#status_state').text('Divorced')
                        } else {
                          $('#status_state').text('Unknown')
                        }

                        // TODO colors if user accepted union

                        if (url_document.indexOf(':\/\/') == -1) {
                          // No protocol included
                          url_document = "https:\/\/" + url_document
                        }

                        $('#status_url').html('<a target="_blank" href="' + url_document + '">' + url_document + '</a>')
                        $('#status_party_one').text(party_one)
                        $('#status_party_two').text(party_two)

                        date = new Date(parseInt(refund_on) * 1000)
                        $('#status_time_left').text(date.toString())

                        // Now set which controls are available, let's do a new callbacks! ...
                        love.is_witness(web3.eth.accounts[0], function (e, r) {
                          if (e) throw e
                          userIsWitness = r

                          if (!(party_one == web3.eth.accounts[0] || party_two == web3.eth.accounts[0]) || initialized) {
                            $('#add_witness').hide()
                            $('#end_initialization').hide()
                          }

                          // TODO do not show if already accepted
                          if (!initialized || married || divorced || !(party_one == web3.eth.accounts[0] || party_two == web3.eth.accounts[0] || userIsWitness)) {
                            $('#accept_union').hide()
                          }

                          today = new Date()
                          if (!initialized || !(party_one == web3.eth.accounts[0] || party_two == web3.eth.accounts[0] || userIsWitness) || married || divorced || !(today.getTime() >= date.getTime())) {
                            $('#refund').hide()
                          }

                          if (!(party_one == web3.eth.accounts[0] || party_two == web3.eth.accounts[0]) || !married || divorced) {
                            $('#divorce').hide()
                          }

                          // TODO events should update the UI

                          // Time to fill more data: witnesses and events
                          // 1) Witnesses
                          //var witness_added = love.WitnessAdded()
                          //witness_added.watch(function (e, r) {
                          //  if (e) throw e
                          //  $('#witness_list').append('<li class="collection-item">' + r["args"]["witness"] + '</li>')
                          //})

                          // 2) Event list
                          var allEvents = love.allEvents()
                          allEvents.watch(function (e, r) {
                            if (e) throw e
                            $('#events').append('<li class="collection-item">' + r.event + '</li>')
                            console.log(r)
                            Materialize.toast(r.event + ", you may need to reload the DAPP", 3000)
                          })

                          // Past events
                          // 1) Witnesses
                          //var witness_added_past = love.WitnessAdded()
                          //witness_added_past.get(function (e, r) {
                          //  if (e) throw e
                          //  $('#witness_list').append('<li class="collection-item">' + r["args"]["witness"] + '</li>')
                          //})

                          // 2) Event list
                          //var allEvents_past = love.allEvents()
                          //allEvents_past.get(function (e, r) {
                          //  if (e) throw e
                          //  $('#events').append('<li class="collection-item">' + JSON.stringify(r) + '</li>')
                          //})
                        })
                      })
                    })
                  })
                })
              })
            })
          })
        })
      })
    })
  })
})

