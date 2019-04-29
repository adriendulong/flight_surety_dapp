pragma solidity ^0.5.2;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./interfaces/IFlightSuretyData.sol";

contract FlightSuretyData is IFlightSuretyData {
	using SafeMath for uint256;

	/********************************************************************************************/
	/*                                       DATA VARIABLES                                     */
	/********************************************************************************************/

	address private contractOwner;                                      // Account used to deploy contract
	bool private operational = true;                                    // Blocks all state changes throughout the contract if false
	uint private countRegisteredAirlines = 0;													// A counter of registered airlines
	mapping(address => uint) private registeredAirlines;								// Registered airlines
	mapping(address => uint) private authorizedContracts;						// Contracts authorized to call this one

	event AirlineRegistered(address airline);
	/********************************************************************************************/
	/*                                       EVENT DEFINITIONS                                  */
	/********************************************************************************************/


	/**
	* @dev Constructor
	* The deploying account becomes contractOwner
	*/
	constructor(address firstAirline) public {
		contractOwner = msg.sender;

		// Add the first airline
		_registerAirline(firstAirline);
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

	/**
	* @dev Modifier that requires the "ContractOwner" account to be the function caller
	*/
	modifier requireContractOwner() {
		require(msg.sender == contractOwner, "Caller is not contract owner");
		_;
	}

	modifier requireIsCallerAuthorized() {
    require(authorizedContracts[msg.sender] == 1, "Caller is not contract owner");
    _;
  }

	/**
	* @dev Modifier that checks that an airline is registered
	*/
	modifier isRegisteredAirline(address airline) {
		 require(registeredAirlines[airline] == 1, "FlightSuretyData::isRegisteredAirline: This airline is not registered");
		 _;
	}

	/********************************************************************************************/
	/*                                       UTILITY FUNCTIONS                                  */
	/********************************************************************************************/

	function authorizeContract(address contractAddress) public requireContractOwner {
    authorizedContracts[contractAddress] = 1;
  }

	/**
	* @dev Get operating status of contract
	*
	* @return A bool that is the current operating status
	*/      
	function isOperational() public view returns(bool) {
		return operational;
	}


	/**
	* @dev Sets contract operations on/off
	*
	* When operational mode is disabled, all write transactions except for this one will fail
	*/    
	function setOperatingStatus(bool mode) external requireContractOwner {
		operational = mode;
	}

	/**
	* @dev Add an airline to the registered ones
	*/
	function _registerAirline(address airline) internal {
		registeredAirlines[airline] = 1;
		countRegisteredAirlines++;
		emit AirlineRegistered(airline);
	}

	/********************************************************************************************/
	/*                                     SMART CONTRACT FUNCTIONS                             */
	/********************************************************************************************/

	/**
	* @dev Get number of registered airlines
	*/
	function getNumberRegisteredAirlines() external view requireIsCallerAuthorized returns(uint){
		return countRegisteredAirlines;
	}

	/**
	* @dev Add an airline to the registration queue
	*      Can only be called from FlightSuretyApp contract
	*
	*/   
	function registerAirline(address airline) external requireIsCallerAuthorized {
		_registerAirline(airline);
	}

	/**
	* @dev Tell if an airline is registered or not
	*/
	function isAirlineRegistered(address airline) external view requireIsCallerAuthorized returns(bool){
		return (registeredAirlines[airline] == 1);
	}


// 	/**
// 	* @dev Buy insurance for a flight
// 	*
// 	*/   
// 	function buy() external payable {
// 	}

// 	/**
// 	*  @dev Credits payouts to insurees
// 	*/
// 	function creditInsurees() external pure {
// 	}
		

// 	/**
// 	 *  @dev Transfers eligible payout funds to insuree
// 	 *
// 	*/
// 	function pay() external pure {
// 	}

//  /**
// 	* @dev Initial funding for the insurance. Unless there are too many delayed flights
// 	*      resulting in insurance payouts, the contract should be self-sustaining
// 	*
// 	*/   
// 	function fund() public payable {
// 	}

	function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
		return keccak256(abi.encodePacked(airline, flight, timestamp));
	}

	// /**
	// * @dev Fallback function for funding smart contract.
	// *
	// */
	// function() external payable {
	// 	fund();
	// }


}

