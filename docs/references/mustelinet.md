# Exemple — mustelinet, un hébergeur auto-hébergé

Polype ne suppose aucun hébergeur : ce fichier décrit les particularités d'un seul, mustelinet, auquel renvoient les notes de `boilerplates/bricks/` comme exemple.

Cloud OpenStack tenu par un ami. Doc tenant : https://doc.mustelinet.com/docs/ (lue le 2026-11-28).

- **Fourni** : VM (images Ubuntu, Debian, Fedora, Alma, Rocky, Alpine, CoreOS), volumes bloc, réseaux, routeurs, IP flottantes, security groups, Kubernetes managé créé par Terraform depuis un template tenant, application credentials pour Terraform et CI.
- **Non documenté** : base de données managée, stockage objet, registre d'images, SMTP sortant, snapshots de volumes. On héberge soi-même ce qui manque (VM ou Kubernetes) et le reste se demande à l'hébergeur.
- **Publication** : HTTP 80 et HTTPS 443, plus 25565 quand Minecraft est activé ; pas de TCP/UDP arbitraire. Un edge public route sur `<vm_id>.<project_id>.apps.mustelinet.com` (port 80 par en-tête Host, port 443 par nom et SNI) : l'application présente elle-même un certificat couvrant le nom visité. L'edge fait proxy, la VM voit le proxy comme source.
- **Noms** : les noms générés sont des enregistrements Designate rapprochés des IP flottantes en une quinzaine de secondes, sous une zone enfant de `apps.mustelinet.com` par projet ; ils se lisent dans la page DNS ou Designate de Skyline.
- **Domaines personnalisés** (https://doc.mustelinet.com/docs/access/http-https-apps/, https://doc.mustelinet.com/docs/networking/dns-names/) : un enregistrement CNAME chez le fournisseur DNS, par exemple `app.example.com. CNAME <vm_id>.<project_id>.apps.mustelinet.com.`. On garde le nom généré comme cible et on met le CNAME à jour s'il change ; on ne pointe jamais vers l'IP flottante.
- **Accès** (https://doc.mustelinet.com/docs/access/ssh-access/) : SSH via `ssh.mustelinet.com` port 2222, `ssh -p 2222 <vm-user>@<vm-name>-<project-name>@ssh.mustelinet.com`, authentification GitHub SSO par `auth.mustelinet.com` ; la VM a une IP flottante et un security group qui autorise TCP 22 depuis `0.0.0.0/0`. Dashboard Skyline : `https://skyline.openstack.mustelinet.com` ; Keystone : `https://keystone.openstack.mustelinet.com`.
- **À savoir** : la section Kubernetes de la doc répond encore 403 (2026-11-28). (Certificat de la doc expiré du 2026-09-15 au 2026-09-18, renouvelé depuis.)
- L'hébergeur est ouvert à nos besoins : une capacité manquante se demande plutôt qu'elle ne se contourne.

## Par brique

- **Déploiement** : nom généré `<vm_id>.<project_id>.apps.mustelinet.com` pour le health check en HTTPS ; Terraform et CI s'authentifient par application credentials OpenStack, gardés dans le secret store de la CI. Questions ouvertes : détails Kubernetes (403), registre d'images.
- **Fichiers (Garage)** : les liens signés publics passent par le nom généré en HTTPS, avec le certificat présenté par le service ; un domaine personnalisé par CNAME est possible. Questions ouvertes : snapshots de volumes, copie hors site.
- **Courrier** : l'interface web du serveur de capture reste privée, atteinte par `ssh.mustelinet.com:2222`. Question ouverte : SMTP sortant depuis une VM.
- **Observabilité** : l'interface web d'un backend reste privée, atteinte par `ssh.mustelinet.com:2222`, ou publiée en HTTPS par l'edge avec son propre certificat.
- **Base de données (PostgreSQL)** : un administrateur atteint le port PostgreSQL par `ssh.mustelinet.com:2222`, jamais par l'edge ; le port n'est pas joignable depuis `<vm_id>.<project_id>.apps.mustelinet.com`. Questions ouvertes : snapshots de volumes, copie hors site.
- **Tâches** : rien de propre à l'hébergeur ; détails Kubernetes ouverts comme pour le déploiement.
