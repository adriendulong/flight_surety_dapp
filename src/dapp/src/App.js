import React, { useEffect } from 'react';
import { useWeb3Context } from 'web3-react'

import InsurancePayment from './components/InsurancePayment'
import FetchFlightStatus from './components/FetchFlightStatus'
import CheckInsurance from './components/CheckInsurance'
import CheckBalance from './components/CheckBalance'

import './App.css';


function App() {
  const context = useWeb3Context()
  let text = "Loading"

  useEffect(() => {
    context.setConnector('Injected');
  }, [])
  

  if (!context.active && !context.error) {
    return (
      <div className="App">
        <p>Loading</p>
      </div>
    )
  } else if (context.error) {
    text = `Error: ${context.error.message}`
    return (
      <div className="App">
        <p>{text}</p>
      </div>
    )
  } else {
    return (
      <div className="App">
        <h1>Flight Surety Project</h1>
        <InsurancePayment/>
        <CheckInsurance/>
        <FetchFlightStatus/>
        <CheckBalance/>
      </div>
    )
  }
}

export default App;
