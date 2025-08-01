let
  # Get system's ssh public key by command:
  #    cat /etc/ssh/ssh_host_ed25519_key.pub
  # If you do not have this file, you can generate all the host keys by command:
  #    sudo ssh-keygen -A
  laptop = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDvED6PbgTV9/yjDymEci/ATe6vQDb9c11hqUwNyEStvFmkDr5ili7+2fiUhTrNaefTX5RaDIRaKBu4jl+kjSn5tfv+lvdYbl/UM8yMN8YODcM4JbAUo5cyX76s5BXaBrqQH0TGEXhKlLkVdxCJCBLm9tpakkxgLruj0qEwSoSGruM/QCYgbhXrh9NcEtOBaOBZ39DUhT3MEKgZJBlbqIXqyeHN5L1GLBEgBN73dZhh7fsJdIpfaezqzIeu8FQnAnL94eOFlDx7PXm1Wiacpcb5S7GsIFnd1iEc/TlYyaXKN+12VK2qPe6KMZfF7lBvgnjEU868sHiU8OXpWkYWQ3RJs0uQqSylQum8jsJAOWcygavVRrOO+zDxzNkPXa+7H3Jah9XoywaKjz8rsPTs0qu/AWZG/KyV7EeQu+J6oIOXGv2OBcndRuQTBKIimHCdnGEnpgkAzw9gs14oc0MN97k1izb5zyK6zf4jsD8cHl+64Hevapto28yqcCanQk9p9+M= not-matthias@laptop";
  desktop = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDrhQhxtgcYUwjVwwJMkjxL1gdgs16jxKlIsoJZ+DXk6rjzlD1QtlhU0od6hsIMXOFQ7CG7UMcQgYhquilU9RGFKgFBJ+Sclu3MHQmy+X+i9Bm55uM/pM5MIC6eivbM1xwvX5bU9JkZKTQC+HXhWEsHCd03u8x09638ZKYTbTKM9LdZ+8SOsEutGu6OauemNRGKmaHMfQkA60TTzsmIm0MCTKicl520u8atY/wXMVxdZMyDiQw8C6CxDvdF1HlAcUil0+hn4HeZoTUBa0zaOd72vDuPYOM9vtnVv/NYWmo7CNtv3lappkUBGIhv/j9+g8bCXIUaE8Rbq0FFzCuKgl+Ht+BMriBf+zkUGdXO1wDZuew66wdxHJpFMWGHTTtvYmDlcnxY/b+0ODo3llWVOCXvq00UoFMKKss5eFp5DLmaj6ZWZi8U3x6wp5rM40HoZG6LD2fku6VZgNSiJTZY9UsghyLbG64btFw6P/BEhzgriS44CBc+BDllt4fYBA8BerILKazH4KWXEsR6vCbIjolIGCbFm4kOzHvU0X1kCvTKjL2x6MBbOJoQl2B2Hs8Fnu5lOUOFM4FWfniIcjhdgLPHv0+3vVY8S7p8844zAllJAgqMrWc2+fpkOOVQZhRjnxW8STcmpoD70/AhItUUsrYzvLPMk48tbALK7legLljmEw== root@desktop";

  # A key for recovery purpose, generated by `ssh-keygen -t ed25519 -a 256 -C "not-matthias@agenix-recovery"` with a strong passphrase
  # and keeped it offline in a safe place.
  recovery_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyFEKu0xZCi4gK+FD+aY+Ow8n5vVAzmTVWboghgcrX3 not-matthias@agenix-recovery";

  systems = [laptop desktop recovery_key];
in {
  "laptop.local.pem.age".publicKeys = systems;
  "laptop.local.key.age".publicKeys = systems;
  "desktop.local.pem.age".publicKeys = systems;
  "desktop.local.key.age".publicKeys = systems;
  "temp1.age".publicKeys = systems;
  "duckdns.age".publicKeys = systems;
  "restic-password.age".publicKeys = systems;
  "b2-restic-env.age".publicKeys = systems;
  "nitter-session.age".publicKeys = systems;
}
