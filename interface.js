window.addEventListener('load', async () => {
    await ethereum.enable();
});

const ATS = web3.eth.contract(ATS_ABI).at(ATS_ADDR);
const ATS_multiplier = 100;

function get_wallet(index = 0) {
  return account = web3.eth.accounts[index];
}

function format_ats_value(value) {
  return '£' + value.toFixed(2);
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

async function add_yeeter(walletAddress) {
  var promise = new Promise(function(resolve, reject) {
    ATS.addYeeter(walletAddress, (error, value) => { if (error) reject(error); else resolve(value); });
  });
  return await promise;
}

async function transfer(target, amount) {
  if (!target || target == "")
    return Promise.reject("empty address");

  amount *= ATS_multiplier;

  var promise = new Promise(function(resolve, reject) {
    ATS.transfer(target, amount, { gasPrice:"5e9" }, (error, value) => { if (error) reject(error); else resolve(value); });
  });
  return await promise;
}

async function steal(target, amount) {
  if (!target || target == "")
    return Promise.reject("empty address");

  amount *= ATS_multiplier;

  var promise = new Promise(function(resolve, reject) {
    ATS.steal(target, amount, { gasPrice:"5e9" }, (error, value) => { if (error) reject(error); else resolve(value); });
  });
  return await promise;
}

async function burn(target, amount) {
  if (!target || target == "")
    return Promise.reject("empty address");

  amount *= ATS_multiplier;

  var promise = new Promise(function(resolve, reject) {
    ATS.burn(target, amount, { gasPrice:"5e9" }, (error, value) => { if (error) reject(error); else resolve(value); });
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

async function ether_low(walletAddress = get_wallet()) {
  var promise = new Promise(function(resolve, reject) {
     web3.eth.getBalance(walletAddress, (error, value) => {
       if (error) reject(error); else resolve(value/1e18 <= ATS_LOW);
     });
  });

  return await promise;
}

var lastBlock = 0;
var blockTime = 0;
const blockExpDropoff = 0.85;

async function update_blocktime(blockId) {
  var promise = new Promise(function(resolve, reject) {
     web3.eth.getBlock(blockId, (error, value) => {
       if (error) reject(error); else resolve(value);
     });
  });
  const block = await promise;
  console.log(`BlockId: ${blockId}`);

  console.log(`Timestamp: ${block.timestamp}`);
  if (block.timestamp > lastBlock) {
    if (lastBlock == 0) {
      lastBlock = block.timestamp;
      console.log("First block!");
    }
    else {
      var lastBlockTime = block.timestamp - lastBlock;
      lastBlock = block.timestamp;
      console.log(lastBlockTime);

      if (blockTime == 0) {
        blockTime = lastBlockTime;
        console.log("Second block!");
      }
      else {
        blockTime *= blockExpDropoff;
        blockTime += (1 - blockExpDropoff) * lastBlockTime;
      }
    }
  }
  console.log(`Blocktime: ${blockTime}`);
  return Math.round(blockTime);
}

async function init_blocktime() {
  var promise = new Promise(function(resolve, reject) {
    web3.eth.getBlockNumber((error, value) => {
      if (error) reject(error); else resolve(value);
    });
  });

  var latest = await promise;
  for (var i = latest - 10; i < latest; ++i) {
    await update_blocktime(i);
  }

  return update_blocktime(latest);
}
