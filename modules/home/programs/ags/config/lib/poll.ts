import { createState } from "ags"
import { execAsync } from "ags/process"
import { interval } from "ags/time"

export function createCommandState<T>(
  initial: T,
  intervalMs: number,
  command: string | string[],
) {
  const [state, setState] = createState(initial)

  const refresh = async () => {
    try {
      const output = await execAsync(command)
      setState(JSON.parse(output) as T)
    } catch (error) {
      console.error(`Failed to refresh ${Array.isArray(command) ? command[0] : command}:`, error)
    }
  }

  void refresh()
  interval(intervalMs, () => void refresh())

  return [state, refresh] as const
}
