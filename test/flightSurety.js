
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    // await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline("newAirline", newAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) can fund', async () => {
    

    // ACT
    try {
        let owner = await config.flightSuretyData.getOwner.call();
        let fund = web3.utils.toWei("10", "ether");
        await config.flightSuretyData.fund({from: owner, value: fund});
        let result = await config.flightSuretyData.getAirline.call(owner); 
        // ASSERT
    console.log(config.firstAirline+" ::v ---------results "+result[1]+" - "+result[2]);
    assert.equal(result[2], true);
    }
    catch(e) {
        console.log(e);
    }

  });

  it('(airline) can register an Airline using registerAirline() if it is funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        let owner = await config.flightSuretyData.getOwner.call();
        let fund = web3.utils.toWei("10", "ether");
        await config.flightSuretyData.fund({from: owner, value: fund});
        await config.flightSuretyData.registerAirline("newAirline", newAirline, {from: owner});
        let result = await config.flightSuretyData.getAirline.call(newAirline); 
        // ASSERT
        assert.equal(result[0], true);
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, true, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines.', async () => {
    
    // ARRANGE
    let airline2 = accounts[2];
    let airline3 = accounts[2];
    let airline4 = accounts[2];
    let airline5 = accounts[2];

    // ACT voteToRegisterAirline
    try {
        let owner = await config.flightSuretyData.getOwner.call();
        let fund = web3.utils.toWei("10", "ether");
        await config.flightSuretyData.fund({from: owner, value: fund});
        await config.flightSuretyData.registerAirline("Airline2", airline2, {from: owner});
        await config.flightSuretyData.registerAirline("Airline3", airline3, {from: owner});
        await config.flightSuretyData.registerAirline("Airline4", airline4, {from: owner});
        await config.flightSuretyData.registerAirline("Airline5", airline5, {from: owner});
        let result = await config.flightSuretyData.getAirline.call(airline5); 
        // ASSERT
        assert.equal(result[3], false);
        assert.equal(result[4], 0);
        await config.flightSuretyData.voteToRegisterAirline("Airline5", airline5, {from: owner});
        await config.flightSuretyData.voteToRegisterAirline("Airline5", airline5, {from: airline2});
        // ASSERT
        assert.equal(result[3], true);
        assert.equal(result[4], 2);
    }
    catch(e) {

    }

  });
 

});
