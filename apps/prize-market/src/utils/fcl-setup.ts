import * as fcl from '@onflow/fcl'
import { FLOW } from '../constants'
import flowJSON from '../../../../flow.json'
import { getUrl } from './get-url'

const flowNetwork = process.env.NEXT_PUBLIC_FLOW_NETWORK as fcl.Environment
const iconUrl =
  flowNetwork === 'local'
    ? `${getUrl()}/static/flow-icon-bw-green.svg`
    : `${process.env.NEXT_PUBLIC_VERCEL_URL}/static/flow-icon-bw-green.svg`
const appTitle = process.env.NEXT_PUBLIC_APP_NAME || 'Flow Arcade Market'

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
