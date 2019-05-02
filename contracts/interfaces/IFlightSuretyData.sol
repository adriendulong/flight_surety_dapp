pragma solidity ^0.5.2;

interface IFlightSuretyData {
  function registerAirline(address airline) external;
  function getNumberRegisteredAirlines() external view returns(uint);
  function isAirlineRegistered(address airline) external view returns(bool);
  function fund(address airline) external payable;
  function isAirlineParticipating(address airline) external view returns(bool);
}