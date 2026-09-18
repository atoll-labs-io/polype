# Référence — mustelinet (hébergement des prototypes)

Cloud OpenStack tenu par un ami. Doc tenant : https://doc.mustelinet.com/docs/ (lue le 2026-09-18).

- **Fourni** : VM (images Ubuntu, Debian, Fedora, Alma, Rocky, Alpine, CoreOS), volumes bloc, réseaux, routeurs, IP flottantes, security groups, Kubernetes managé créé par Terraform depuis un template tenant, application credentials pour Terraform et CI.
- **Non documenté** : base de données managée, stockage objet. On les héberge soi-même (VM ou Kubernetes).
- **Publication** : HTTP 80 et HTTPS 443 seulement, via un edge public qui route sur `<vm_id>.<project_id>.apps.mustelinet.com`. En HTTPS l'edge route par SNI : l'application présente elle-même un certificat couvrant le nom. Pas de TCP/UDP arbitraire.
- **Accès** : dashboard Skyline, SSH via `ssh.mustelinet.com:2222`, auth OpenStack `https://keystone.openstack.mustelinet.com`.
- **À savoir** : le certificat de `doc.mustelinet.com` a expiré le 2026-09-15 (Let's Encrypt), la section Kubernetes de la doc répond 403. Domaines personnalisés : non documentés, à demander.
- L'hébergeur est ouvert à nos besoins : une capacité manquante se demande plutôt qu'elle ne se contourne.
