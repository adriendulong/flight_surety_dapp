import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';

import { useAppContract, useFetchFlights } from '../../hooks'

import './check-insurance.css'

function CheckInsurance() {
  const appContract = useAppContract()

  // State the manage the flight the user select
  const [selectedFlight, setSelectedFlight] = useState();

  // State that manages the flight datas
  const { flights, error } = useFetchFlights()
  
  const [insuranceAmount, setInsuranceAmount] = useState()

  useEffect(() => {
    if(flights) setSelectedFlight('0')
  }, [flights])

  /**
   * Function that will get the amount the passenger 
   * put in an insurance for a specific flight
   */
  async function checkInsuranceAmount(e) {
    e.preventDefault()
    try {
      let flight = flights[parseInt(selectedFlight)]
      let amount = await appContract.getInsuranceFundAmount(flight.airline, flight.flight, flight.timestamp.toString())
      console.log(ethers.utils.formatEther(amount.toString()))
      setInsuranceAmount(ethers.utils.formatEther(amount.toString()))
    }
    catch(e) {
      console.error(e)
    }
    
  }    

  return (
    <div id="check-insurance">
      <h3>Check Insurance</h3>
      <form className="column-form">
        <label htmlFor="selectFlight">Choose a flight: </label>
        {selectedFlight && (
          <select id="selectFlight" value={selectedFlight} onChange={(e) => setSelectedFlight(e.target.value)}>
            {flights.map((flight, index) => (
              <option value={index} key={index}>
                {flight.flight}
              </option>
            ))}
          </select>
        )}
        {error && (
          <p>{error.message}</p>
        )}
        <button onClick={checkInsuranceAmount}>Check insurance amount</button>
        {insuranceAmount && (
          <p>The amount you put for this flight in the insurance is {insuranceAmount} ETH</p>
        )}
      </form>
    </div>
  )
}

export default CheckInsurance