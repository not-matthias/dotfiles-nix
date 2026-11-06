{
  lib,
  pkgs,
  osConfig,
  ...
}: let
  notifier =
    pkgs.writers.writePython3Bin "fingerprint-notify" {
      libraries = [pkgs.python3Packages.dbus-fast];
    } ''
      import asyncio

      from dbus_fast import BusType, Message, MessageFlag, MessageType
      from dbus_fast.aio import MessageBus

      FPRINT = "net.reactivated.Fprint"
      DEVICE = FPRINT + ".Device"
      PROPERTIES = "org.freedesktop.DBus.Properties"
      NOTIFICATIONS = "org.freedesktop.Notifications"
      MISSING_SERVICE = {
          "org.freedesktop.DBus.Error.ServiceUnknown",
          "org.freedesktop.DBus.Error.NameHasNoOwner",
      }


      async def call(bus, **kwargs):
          reply = await bus.call(Message(**kwargs))
          if reply.message_type == MessageType.ERROR:
              if reply.error_name in MISSING_SERVICE:
                  return None
              raise RuntimeError(f"{reply.error_name}: {reply.body}")
          return reply.body


      async def main():
          system = await MessageBus(bus_type=BusType.SYSTEM).connect()
          session = await MessageBus().connect()
          changed = asyncio.Event()
          notification_id = 0

          def on_message(message):
              if message.message_type == MessageType.SIGNAL:
                  changed.set()

          system.add_message_handler(on_message)
          for rule in (
              "type='signal',sender='net.reactivated.Fprint',"
              "interface='org.freedesktop.DBus.Properties',"
              "member='PropertiesChanged',arg0='net.reactivated.Fprint.Device'",
              "type='signal',sender='org.freedesktop.DBus',"
              "interface='org.freedesktop.DBus',member='NameOwnerChanged',"
              "arg0='net.reactivated.Fprint'",
          ):
              await call(
                  system, destination="org.freedesktop.DBus",
                  path="/org/freedesktop/DBus", interface="org.freedesktop.DBus",
                  member="AddMatch", signature="s", body=[rule],
              )

          changed.set()
          while True:
              await changed.wait()
              changed.clear()
              devices = await call(
                  system, destination=FPRINT, path="/net/reactivated/Fprint/Manager",
                  interface=FPRINT + ".Manager", member="GetDevices",
                  flags=MessageFlag.NO_AUTOSTART,
              )
              needed = False
              for path in devices[0] if devices else []:
                  properties = await call(
                      system, destination=FPRINT, path=path, interface=PROPERTIES,
                      member="GetAll", signature="s", body=[DEVICE],
                      flags=MessageFlag.NO_AUTOSTART,
                  )
                  if properties:
                      needed |= properties[0]["finger-needed"].value

              if needed and not notification_id:
                  result = await call(
                      session, destination=NOTIFICATIONS,
                      path="/org/freedesktop/Notifications", interface=NOTIFICATIONS,
                      member="Notify", signature="susssasa{sv}i",
                      body=["Fingerprint", 0, "dialog-information",
                            "Fingerprint required", "Touch the fingerprint reader",
                            [], {}, 0],
                  )
                  if result:
                      notification_id = result[0]
              elif not needed and notification_id:
                  await call(
                      session, destination=NOTIFICATIONS,
                      path="/org/freedesktop/Notifications", interface=NOTIFICATIONS,
                      member="CloseNotification", signature="u",
                      body=[notification_id],
                  )
                  notification_id = 0


      asyncio.run(main())
    '';
in {
  # Follow the host's fingerprint support without changing its PAM configuration.
  config = lib.mkIf (osConfig.hardware.fingerprint.enable or false) {
    systemd.user.services.fingerprint-notify = {
      Unit = {
        Description = "Fingerprint prompt notifications";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = lib.getExe notifier;
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
