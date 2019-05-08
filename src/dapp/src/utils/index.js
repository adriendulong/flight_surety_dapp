import { ethers } from 'ethers'

// Insipration from https://github.com/Uniswap/uniswap-frontend/blob/beta/src/utils/index.js

export function isAddress(value) {
  try {
    ethers.utils.getAddress(value)
    return true
  } catch {
    return false
  }
}

export function getProviderOrSigner(library, account) {
  return account ? library.getSigner(account) : library
}

// account is optional
export function getContract(address, ABI, library, account) {
  if (!isAddress(address) || address === ethers.constants.AddressZero) {
    throw Error(`Invalid 'address' parameter '${address}'.`)
  }

  return new ethers.Contract(address, ABI, getProviderOrSigner(library, account))
}