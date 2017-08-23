$(document).ready(function() {
  $('#deploy_btn').click(function () {
    $('#deploy_btn').hide()
    $('#deploying').show()

    web3.eth.contract(abi).new(
      $('#party_one').val(),
      $('#party_two').val(),
      $('#document_url').val(),
      $('#days_timer').val(),
      {from: web3.eth.accounts[0], data: bin, gas: gas},
      function (e, r) {
        if (e) {
          $('#error_deploy').modal('open')

          $('#deploy').show()
          $('#deploying').hide()
        } else if (typeof r.address !== "undefined") {
          $('#address').text(r.address)
          $('#transaction').text(r.transactionHash)

          console.log ("Deployed at " + r.address + " (tx: " + r.transactionHash + ")");

          $('#success').modal('open')

          $('#deploy_btn').show()
          $('#deploying').hide()
        }
      }
    )
 })
})
