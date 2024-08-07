# References:
# - https://discourse.nixos.org/t/how-to-run-bevy-game-in-nixos/17486/11
# - https://github.com/winston0410/bevy-nixos
# - https://discourse.nixos.org/t/getting-external-libraries-to-work-in-rust-graphics/21632
# -
{
  # Needed for winit/imgui/egui/other rust applications
  hardware.graphics.enable = true;
}
