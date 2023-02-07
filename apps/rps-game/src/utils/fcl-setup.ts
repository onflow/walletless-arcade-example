import * as fcl from '@onflow/fcl'
import { FLOW } from '../constants'
import flowJSON from '../../../../flow.json'

const iconUrl =
  process.env.NEXT_PUBLIC_FLOW_NETWORK === 'emulator'
    ? 'http://localhost:' +
      process.env.NEXT_PUBLIC_PORT +
      '/static/flow-icon-bw-green.svg'
    : 'https://walletless-arcade-marketplace.vercel.app' +
      '/static/flow-icon-bw-green.svg'
const appTitle = process.env.NEXT_PUBLIC_APP_NAME || 'Flow Games'
const flowNetwork = process.env.NEXT_PUBLIC_FLOW_NETWORK as fcl.Environment

export const loadFCLConfig = () => {
  fcl
    .config({
      'flow.network': flowNetwork as fcl.Environment,
      'accessNode.api': FLOW.ACCESS_NODE_URLS[flowNetwork],
      'discovery.wallet': `https://fcl-discovery.onflow.org/${flowNetwork}/authn`,
      'app.detail.icon': iconUrl,
      'app.detail.title': appTitle,
    })
    .load({ flowJSON })
}
