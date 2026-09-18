import { niriState } from "./Workspaces"

export default function Language() {
  return (
    <box cssClasses={["right-group"]}>
      <label
        cssClasses={["right-item", "language"]}
        label={niriState((state) => state.language)}
      />
    </box>
  )
}
