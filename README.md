
# How to use this repository to support Pisces V

I created this repository to implement a back-up path to store the configuration and datasets from Galaxy in CephS3 storage at the University of Minnesota.  I have used this strategy to back up and restore histories, workflows, and datasets through several iterations of the `Pisces` instance.  This is for the fifth iteration, `Pisces V`, when I have the chance to bring it up, populating it from the backup of `Pisces IV`.

The very terse summary is to invoke a backup on Galomix2 in two steps:
```bash
# Collect configuration data from the running instance.
sudo ssh galaxy rootless bash /datapool/galaxy/home/piquint/export/tardis.sh backup
# Transmit the configuration, histories, datasets, and even shed tools to CephS3 storage at MSI.
sudo ssh galaxy rootless bash /datapool/galaxy/home/piquint/export/tardis.sh transmit
```

In the long run I hope to make this more generalized.  Right now this exists to help me maintain our production Galaxy instance.
