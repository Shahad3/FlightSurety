pragma solidity >=0.4.21 <0.6.0;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    struct Airline {
        bool exist;
        string name ;
        bool participate;
        bool approved;
        uint votes;
    }
    mapping(address => Airline) public idToAirline;
    uint balance = 0;
    uint256 airlineCount = 0;

    Airline firstAirline;

    // --- Flights
    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
        uint256 userBalance;
    }
    mapping(bytes32 => Flight) private flights;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        firstAirline = Airline(true, "FS_Airline", false, true, 0);
        airlineCount = airlineCount + 1;
        idToAirline[msg.sender] = firstAirline;
        // registerAirline("FS_Airline");
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    modifier requireMoreThanFourAirlines() 
    {
        require(airlineCount>4, "You need to register at least 4 airlnes to vote");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier checkValue(uint256 _value) {
        require(msg.value >= _value, "The recieved payment is not sufficient.");
    _;
  }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            external 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline (string memory _name, address _newAirlineAddress)
                            public
    {
        if(airlineCount<=4){
            require(idToAirline[msg.sender].participate, "Only registered and funded Airlines can registed new airline.");
            idToAirline[_newAirlineAddress] = Airline(true, _name, false, true, 0);
        }
        else{
            idToAirline[_newAirlineAddress] = Airline(true, _name, false, false, 0);
        }
        airlineCount = airlineCount + 1;
        // idToAirline[msg.sender] = newAirline;
    }

    function isAirline(address _airlineAddress) external view returns (bool){
        return idToAirline[_airlineAddress].exist;
    }

    function getAirline(address _airlineAddress) external view returns(bool, string memory, bool, bool, uint){
        return(idToAirline[_airlineAddress].exist, idToAirline[_airlineAddress].name, idToAirline[_airlineAddress].participate, idToAirline[_airlineAddress].approved, idToAirline[_airlineAddress].votes);
    }
    function getOwner() external view returns(address){
        return contractOwner;
    }

    //---************* Flights function **********************----///

   function registerFlight (uint256 _updatedTimestamp, string memory flightNamuber, address _airlineAddress) public payable {
       require(msg.value > 1 ether, "Insurance should be at least one ether");
       bytes32 key = getFlightKey(_airlineAddress, flightNamuber, _updatedTimestamp);
       flights[key] = Flight(true, 10, _updatedTimestamp, _airlineAddress, msg.value);
    } 

    function processFlightStatus(
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 _statusCode
                                )
                                public
                {
                    bytes32 key = getFlightKey(airline, flight, timestamp);
                    require(flights[key].isRegistered, "This flight is not registered.");
                    flights[key].statusCode = _statusCode; 
                }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                            )
                            external
                            payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                address airline,
                                string memory flight,
                                uint256 timestamp 
                            )
                            public
                            payable
    {
        bytes32 key = getFlightKey(airline, flight, timestamp);
                    require(flights[key].isRegistered, "This flight is not registered.");
                    if(flights[key].statusCode == 10){
                        uint256 cost = flights[key].userBalance + (flights[key].userBalance/2);
                        msg.sender.transfer(cost);
                    }
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                            )
                            external 
                            payable
    {
        require(msg.value >= 10 ether);
        balance += msg.value;
        idToAirline[msg.sender].participate = true;
        idToAirline[msg.sender].name = "hahahahaahahahahaha";
    }

    function voteToRegisterAirline (address _airlineAddress) external requireMoreThanFourAirlines {
        require(!idToAirline[_airlineAddress].approved, "This Airline is already approved");
        require(idToAirline[msg.sender].approved, "The sender is not approved");
        idToAirline[_airlineAddress].votes++;
        if(idToAirline[_airlineAddress].votes>=(airlineCount/2)){
            idToAirline[_airlineAddress].approved = true;
        }
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                             
    {
        // fund();
    }


}

