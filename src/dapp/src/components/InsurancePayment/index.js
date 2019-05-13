import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';

import { useAppContract, useFetchFlights } from '../../hooks'

import './insurance-payment.css'

function InsurancePayment() {
  const appContract = useAppContract()
  const [selectedFlight, setSelectedFlight] = useState();
  const [amount, setAmount] = useState(0);
  const { flights, error } = useFetchFlights()

  async function submitPayment(e) {
    e.preventDefault()
    try {
      const flight = flights[parseInt(selectedFlight)]
      await appContract.buy(flight.airline, flight.flight, flight.timestamp.toString(), {value: ethers.utils.parseEther(amount)})
      setAmount(0)
    }
    catch(e) {
      console.error(e)
    }
    
  } 

  useEffect(() => {
    if(flights) setSelectedFlight("0")
  }, [flights])

  return (
    <div id="insurance-payment">
      <h3>Get an insurance</h3>
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
        <label htmlFor="textInput">Insurance amount (up to 1 ether): </label>
        <input id="textInput" type="number" value={amount} onChange={(e) => setAmount(e.target.value)}/>
        <button onClick={submitPayment}>Get an insurance</button>
      </form>
    </div>
  )
}

export default InsurancePayment