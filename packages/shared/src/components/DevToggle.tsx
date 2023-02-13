import { Switch } from '@headlessui/react'

interface IDevToggle {
  enabled: boolean
  toggleEnabled: () => void
}
export default function DevToggle({ enabled, toggleEnabled }: IDevToggle) {
  return (
    <Switch
      checked={enabled}
      onChange={toggleEnabled}
      className={`${
        enabled ? 'bg-blue-600' : 'bg-gray-200'
      } relative inline-flex h-6 w-11 items-center rounded-full`}
    >
      <span className="sr-only">Fire Mode</span>
      <span
        className={`${
          enabled ? 'translate-x-6' : 'translate-x-1'
        } inline-block h-4 w-4 transform rounded-full bg-white transition`}
      />
    </Switch>
  )
}
