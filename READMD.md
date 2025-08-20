docker-compose build
docker-compose up -d --force-recreate


# test
docker exec -it worker-agent bash -lc '
for h in 10.0.0.11 10.0.0.12; do
  echo "== $h ==";
  ssh -i /home/agent/.ssh/id_ed25519 \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o IdentitiesOnly=yes -F /dev/null \
    ubuntu@$h "echo OK && whoami";
done
'

docker exec -it worker-agent bash -lc \
'cd /opt/ansible && ansible web -m ping --private-key /home/agent/.ssh/id_ed25519'



# Access to worker-agent container
docker exec -it worker-agent bash

ansible-playbook /opt/ansible/playbooks/web.yml --private-key /home/agent/.ssh/id_ed25519
```
~/dev/worker-agent$ docker exec -it worker-agent bash
9bf951cb8233:/opt/ansible$ ansible-playbook /opt/ansible/playbooks/web.yml --private-key /home/agent/.ssh/id_ed25519

PLAY [web] ***************************************************************************************************************************

TASK [Gathering Facts] ***************************************************************************************************************
ok: [10.0.0.11]
ok: [10.0.0.12]

TASK [Show kernel version (no sudo)] *************************************************************************************************
changed: [10.0.0.12]
changed: [10.0.0.11]

TASK [Write MOTD (needs sudo)] *******************************************************************************************************
changed: [10.0.0.11]
changed: [10.0.0.12]

TASK [Install curl on Alpine (needs sudo)] *******************************************************************************************
changed: [10.0.0.11]
changed: [10.0.0.12]

PLAY RECAP ***************************************************************************************************************************
10.0.0.11                  : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
10.0.0.12                  : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

9bf951cb8233:/opt/ansible$ 
```

access http://127.0.0.1:8000