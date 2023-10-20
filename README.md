# Demo Clusters
This repo is used to configure clusters via TMC's Continuous Delivery feature.  All clusters in a cluster group can be made to point to this repo, and then pick up specific configurations.

This work is heavily inspired by https://github.com/warroyo/infra-gitops and https://github.com/jeffellin/tmc-experiments.

To use this repo, download it and create your own copy of this repo and add it to your Git server.

Next, login to TMC.  
> [!NOTE]
> If this is the first time logging into your TMC tenant, you will first need to follow the installation and configuration process for the Tanzu CLI at https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzu-cli-ref-tmc/install-cli.html.
```console
$ tanzu context create --endpoint <your-tmc-tenant-hostname>
```

Now, if you don't already have one, create a cluster group for your clusters.  Clusters added to this group will automatically get the TMC Continuous Delivery feature enabled, and be configured to point to your repo.
```console
$ tanzu tmc clustergroup create -v <(<< EOF
Name: my-clusters
EOF
)
```

Next, enable the continuous delivery feature for your cluster group pointing to your cloned repo URL (modifying the exports on the first line to match your setup).
```console
$ export CLUSTER_GROUP=my-clusters GITOPS_URL=https://github.com/cdelashmutt-pivotal/demo-clusters && 
tanzu tmc continuousdelivery enable -s clustergroup -g $CLUSTER_GROUP &&
tanzu tmc continuousdelivery gitrepository create -s clustergroup -v <(<<- EOF
  ClusterGroupName: $CLUSTER_GROUP
  Name: tmc-cd
  Description: TMC CD based on Cluster Name
  Url: $GITOPS_URL
  Branch: origin/main
EOF
) &&
tanzu tmc continuousdelivery kustomization create -s clustergroup -v <(<<- EOF
  ClusterGroupName: $CLUSTER_GROUP
  Name: tmc-cd
  Description: TMC CD based on Cluster Name
  SourceName: tmc-cd
  Path: tmc-cd
EOF
)
```

This repository uses SOPS with `age` to read secrets that you encrypt and check in to your repo.  You will need to generate and import and `age` key to be distributed to your clusters.  If you need to generate a key, you can use the following command:
```console
$ age-keygen -o ~/.age/key.txt
```

Next, create a secret in AWS for your key:
aws secretsmanager create-secret age --secret-string "$(echo "{\"age_key\":\"$(cat ~/.age/key.txt | sed ':a;N;$!ba;s/\n/\\n/g')")"

Now, under the "clusters" path of this repo, add in directories cooresponding to the names of the clusters registed in TMC that you want to apply config to.

TODO: Use Carvel packages to capture the concept of "Roles" that you can add to your clusters.