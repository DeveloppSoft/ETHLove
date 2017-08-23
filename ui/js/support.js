window.addEventListener('load', function() {
  $('#support').click(function () {
    web3.eth.sendTransaction({from: web3.eth.accounts[0], to: "0x7726104068B4d19f416Ea7d44A15d07AB1f89980", value: web3.toWei(0.05, "ether")}, function (e, r) {
      if (e) {
        Materialize.toast("Transaction failed", 5000);
        throw e;
      } else {
        Materialize.toast("Thanks for your support!", 5000);
      }
    })
  })
})
