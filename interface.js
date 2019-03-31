window.addEventListener('load', async () => {
    // Modern dapp browsers...
    if (window.ethereum) {
        window.web3 = new Web3(web3.currentProvider);
        try {
            await ethereum.enable();
        } catch (error) {
            // User denied account access...
        }
    }
    // Legacy dapp browsers...
    else if (window.web3) {
        window.web3 = new Web3(web3.currentProvider);
    }
    // Non-dapp browsers...
    else {
        console.log('Non-Ethereum browser detected. You should consider trying MetaMask!');
    }
});

const ATS = web3.eth.contract(ATS_ABI).at(ATS_ADDR);
const ATS_multiplier = 100;

function get_wallet(index = 0) {
  return account = web3.eth.accounts[index];
}

async function get_balance(walletAddress = get_wallet()) {
  var promise = new Promise(function(resolve, reject) {
    ATS.balanceOf(walletAddress, (error, value) => { if (error) reject(error); else resolve(value); });
  });
  return await promise / ATS_multiplier;
}

async function total_supply() {
  var promise = new Promise(function(resolve, reject) {
    ATS.totalSupply((error, value) => { if (error) reject(error); else resolve(value); });
  });
  return await promise / ATS_multiplier;
}

async function mint(tokens) {
  tokens *= ATS_multiplier;
  var promise = new Promise(function(resolve, reject) {
    ATS.mint(tokens, (error, value) => { if (error) reject(error); else resolve(value); });
  });
  return await promise;
}

async function is_yeeter(walletAddress = get_wallet()) {
  var promise = new Promise(function(resolve, reject) {
    ATS.isYeeter(walletAddress, (error, value) => { if (error) reject(error); else resolve(value); });
  });
  return await promise;
}

async function transfer(target, amount) {
  if (!target || target == "")
    return Promise.reject("empty address");

  amount *= ATS_multiplier;

  var promise = new Promise(function(resolve, reject) {
    ATS.transfer(target, amount, (error, value) => { if (error) reject(error); else resolve(value); });
  });
  return await promise;
}

async function yeet() {
  if (confirm("Yeeting destroys all coins in circulation. Are you 100% positive?")) {
    var promise = new Promise(function(resolve, reject) {
      ATS.yeet((error, value) => { if (error) reject(error); else resolve(value); });
    });
    return await promise;
  }
  else {
    alert("You made the right choice");
  }
}

function make_qr_string(destination, amount) {
  amount *= ATS_multiplier;
  amount = Math.floor(amount);
  return `ethereum:${ATS_ADDR}/transfer?address=${destination}&uint256=${amount}`
}
