{pkgs}: let
  bridge =
    pkgs.writers.writePython3Bin "quickshell-status-bridge" {
      libraries = [pkgs.python3Packages.dbus-fast];
    } ''
      import asyncio
      import json
      import sys

      from dbus_fast import BusType, Message, MessageType
      from dbus_fast.aio import MessageBus


      DUNST_NAME = "org.freedesktop.Notifications"
      DUNST_PATH = "/org/freedesktop/Notifications"
      DUNST_INTERFACE = "org.dunstproject.cmd0"
      SYSTEMD_NAME = "org.freedesktop.systemd1"
      SYSTEMD_PATH = "/org/freedesktop/systemd1"
      SYSTEMD_MANAGER = "org.freedesktop.systemd1.Manager"
      SYSTEMD_UNIT = "org.freedesktop.systemd1.Unit"
      PROPERTIES = "org.freedesktop.DBus.Properties"
      UNIT_NAME = "quickshell-idle-inhibit.service"


      def dnd_status(paused):
          return {
              "text": "󰂛" if paused else "󰂚",
              "tooltip": "Do not disturb: ON" if paused else "Do not disturb: OFF",
              "class": "active" if paused else "inactive",
          }


      def idle_status(active):
          return {
              "text": "󰅶" if active else "󰾪",
              "tooltip": "Idle inhibit: ON" if active else "Idle inhibit: OFF",
              "class": "active" if active else "inactive",
          }


      class StatusBridge:
          def __init__(self, bus):
              self.bus = bus
              self.dnd = None
              self.idle_inhibit = None
              self.unit_path = None
              self.refresh_tasks = {}

          async def add_match(self, rule):
              await self.bus.call(
                  Message(
                      destination="org.freedesktop.DBus",
                      path="/org/freedesktop/DBus",
                      interface="org.freedesktop.DBus",
                      member="AddMatch",
                      signature="s",
                      body=[rule],
                  )
              )

          async def subscribe(self):
              await self.add_match(
                  "type='signal',sender='org.freedesktop.DBus',"
                  "interface='org.freedesktop.DBus',member='NameOwnerChanged',"
                  "arg0='org.freedesktop.Notifications'"
              )
              await self.add_match(
                  "type='signal',sender='org.freedesktop.DBus',"
                  "interface='org.freedesktop.DBus',member='NameOwnerChanged',"
                  "arg0='org.freedesktop.systemd1'"
              )
              await self.add_match(
                  "type='signal',sender='org.freedesktop.Notifications',"
                  "path='/org/freedesktop/Notifications',"
                  "interface='org.freedesktop.DBus.Properties',"
                  "member='PropertiesChanged',"
                  "arg0='org.dunstproject.cmd0'"
              )
              await self.add_match(
                  "type='signal',sender='org.freedesktop.systemd1',"
                  "path_namespace='/org/freedesktop/systemd1/unit',"
                  "interface='org.freedesktop.DBus.Properties',"
                  "member='PropertiesChanged',"
                  "arg0='org.freedesktop.systemd1.Unit'"
              )
              await self.add_match(
                  "type='signal',sender='org.freedesktop.systemd1',"
                  "path='/org/freedesktop/systemd1',"
                  "interface='org.freedesktop.systemd1.Manager',member='UnitNew'"
              )
              await self.add_match(
                  "type='signal',sender='org.freedesktop.systemd1',"
                  "path='/org/freedesktop/systemd1',"
                  "interface='org.freedesktop.systemd1.Manager',member='UnitRemoved'"
              )

          def start_refresh(self, kind):
              task = self.refresh_tasks.get(kind)
              if task is not None and not task.done():
                  return
              self.refresh_tasks[kind] = asyncio.create_task(self.refresh(kind))

          def message_handler(self, message):
              if message.message_type != MessageType.SIGNAL:
                  return

              if (
                  message.interface == "org.freedesktop.DBus"
                  and message.member == "NameOwnerChanged"
                  and len(message.body) == 3
              ):
                  name, _old_owner, new_owner = message.body
                  if name == DUNST_NAME and new_owner:
                      self.start_refresh("dnd")
                  elif name == SYSTEMD_NAME and new_owner:
                      self.unit_path = None
                      self.start_refresh("idle")
                  return

              if (
                  message.interface == PROPERTIES
                  and message.member == "PropertiesChanged"
                  and len(message.body) >= 2
              ):
                  changed = message.body[1]
                  if (
                      message.path == DUNST_PATH
                      and message.body[0] == DUNST_INTERFACE
                      and "paused" in changed
                  ):
                      self.set_dnd(bool(changed["paused"].value))
                  elif (
                      message.path == self.unit_path
                      and message.body[0] == SYSTEMD_UNIT
                      and "ActiveState" in changed
                  ):
                      self.set_idle(changed["ActiveState"].value == "active")
                  return

              if (
                  message.interface == SYSTEMD_MANAGER
                  and message.member in ("UnitNew", "UnitRemoved")
              ):
                  if message.body and message.body[0] == UNIT_NAME:
                      self.unit_path = (
                          message.body[1] if message.member == "UnitNew" else None
                      )
                      self.start_refresh("idle")

          def set_dnd(self, paused):
              self.dnd = dnd_status(paused)
              self.emit()

          def set_idle(self, active):
              self.idle_inhibit = idle_status(active)
              self.emit()

          def emit(self):
              if self.dnd is None or self.idle_inhibit is None:
                  return
              print(
                  json.dumps(
                      {"dnd": self.dnd, "idleInhibit": self.idle_inhibit},
                      ensure_ascii=False,
                      separators=(",", ":"),
                  ),
                  flush=True,
              )

          async def get_property(self, destination, path, interface, name):
              reply = await self.bus.call(
                  Message(
                      destination=destination,
                      path=path,
                      interface=PROPERTIES,
                      member="Get",
                      signature="ss",
                      body=[interface, name],
                  )
              )
              return reply.body[0].value

          async def refresh_dnd(self):
              try:
                  paused = await self.get_property(
                      DUNST_NAME, DUNST_PATH, DUNST_INTERFACE, "paused"
                  )
              except Exception:
                  if self.dnd is None:
                      self.set_dnd(False)
                  return
              self.set_dnd(bool(paused))

          async def refresh_idle(self):
              try:
                  reply = await self.bus.call(
                      Message(
                          destination=SYSTEMD_NAME,
                          path=SYSTEMD_PATH,
                          interface=SYSTEMD_MANAGER,
                          member="GetUnit",
                          signature="s",
                          body=[UNIT_NAME],
                      )
                  )
                  self.unit_path = reply.body[0]
                  active_state = await self.get_property(
                      SYSTEMD_NAME, self.unit_path, SYSTEMD_UNIT, "ActiveState"
                  )
              except Exception:
                  if self.idle_inhibit is None:
                      self.set_idle(False)
                  return
              self.set_idle(active_state == "active")

          async def refresh(self, kind):
              if kind == "dnd":
                  await self.refresh_dnd()
              elif kind == "idle":
                  await self.refresh_idle()
              else:
                  await asyncio.gather(self.refresh_dnd(), self.refresh_idle())


      async def monitor():
          bus = await MessageBus(bus_type=BusType.SESSION).connect()
          bridge = StatusBridge(bus)
          bus.add_message_handler(bridge.message_handler)
          # Install all signal matches before reading either initial property.
          await bridge.subscribe()
          await bridge.refresh("all")
          try:
              await bus.wait_for_disconnect()
          finally:
              bus.disconnect()


      async def main():
          retry_delay = 1
          while True:
              try:
                  await monitor()
                  retry_delay = 1
              except asyncio.CancelledError:
                  raise
              except Exception as error:
                  print(f"status bridge disconnected: {error}", file=sys.stderr)
                  await asyncio.sleep(retry_delay)
                  retry_delay = min(retry_delay * 2, 30)


      asyncio.run(main())
    '';
in {
  inherit bridge;
}
