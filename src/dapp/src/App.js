import React, { useEffect } from 'react';
import { useWeb3Context } from 'web3-react'

import Airline from './components/Airline'

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
    text = "Everything ok 👍🏻"
    return (
      <div className="App">
        <p>{text}</p>
        <Airline/>
      </div>
    )
  }
}

export default App;
