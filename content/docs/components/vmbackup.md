---
title: "vmbackup"
date: 2024-10-28T23:15:34+08:00
weight: 4
---

`vmbackup` creates VictoriaMetrics data backups from [instant snapshots](https://docs.victoriametrics.com/single-server-victoriametrics/#how-to-work-with-snapshots).

`vmbackup` supports incremental and full backups. Incremental backups are created automatically if the destination path already contains data from the previous backup. Full backups can be accelerated with `-origin` pointing to an already existing backup on the same remote storage. In this case `vmbackup` makes server-side copy for the shared data between the existing backup and new backup. It saves time and costs on data transfer.

Backup process can be interrupted at any time. It is automatically resumed from the interruption point when restarting `vmbackup` with the same args.

Backed up data can be restored with [vmrestore](https://docs.victoriametrics.com/vmrestore/).

See [this article](https://medium.com/@valyala/speeding-up-backups-for-big-time-series-databases-533c1a927883) for more details.

See also [vmbackupmanager](https://docs.victoriametrics.com/vmbackupmanager/) tool built on top of `vmbackup`. This tool simplifies creation of hourly, daily, weekly and monthly backups.

Supported storage types [#](https://docs.victoriametrics.com/vmbackup/#supported-storage-types)
-----------------------------------------------------------------------------------------------

`vmbackup` supports the following `-dst` storage types:

*   [GCS](https://cloud.google.com/storage/). Example: `gs://<bucket>/<path/to/backup>`
    
*   [S3](https://aws.amazon.com/s3/). Example: `s3://<bucket>/<path/to/backup>`
    
*   [Azure Blob Storage](https://azure.microsoft.com/en-us/products/storage/blobs/). Example: `azblob://<container>/<path/to/backup>`
    
*   Any S3-compatible storage such as [MinIO](https://github.com/minio/minio), [Ceph](https://docs.ceph.com/en/pacific/radosgw/s3/) or [Swift](https://platform.swiftstack.com/docs/admin/middleware/s3_middleware.html). See [these docs](https://docs.victoriametrics.com/vmbackup/#advanced-usage) for details.
    
*   Local filesystem. Example: `fs://</absolute/path/to/backup>`. Note that `vmbackup` prevents from storing the backup into the directory pointed by `-storageDataPath` command-line flag, since this directory should be managed solely by VictoriaMetrics or `vmstorage`.
    

Use cases [#](https://docs.victoriametrics.com/vmbackup/#use-cases)
-------------------------------------------------------------------

### Regular backups [#](https://docs.victoriametrics.com/vmbackup/#regular-backups)

Regular backup can be performed with the following command:

```
./vmbackup -storageDataPath=</path/to/victoria-metrics-data> -snapshot.createURL=http://localhost:8428/snapshot/create -dst=gs://<bucket>/<path/to/new/backup>
```

ShellCopy

*   `</path/to/victoria-metrics-data>` \- path to VictoriaMetrics data pointed by `-storageDataPath` command-line flag in single-node VictoriaMetrics or in cluster `vmstorage`. There is no need to stop VictoriaMetrics for creating backups since they are performed from immutable [instant snapshots](https://docs.victoriametrics.com/single-server-victoriametrics/#how-to-work-with-snapshots).
    
*   `http://victoriametrics:8428/snapshot/create` is the url for creating snapshots according to [these docs](https://docs.victoriametrics.com/single-server-victoriametrics/#how-to-work-with-snapshots). `vmbackup` creates a snapshot by querying the provided `-snapshot.createURL`, then performs the backup and then automatically removes the created snapshot.
    
*   `<bucket>` is an already existing name for [GCS bucket](https://cloud.google.com/storage/docs/creating-buckets).
    
*   `<path/to/new/backup>` is the destination path where new backup will be placed.
    

### Regular backups with server-side copy from existing backup [#](https://docs.victoriametrics.com/vmbackup/#regular-backups-with-server-side-copy-from-existing-backup)

If the destination GCS bucket already contains the previous backup at `-origin` path, then new backup can be accelerated with the following command:

```
./vmbackup -storageDataPath=</path/to/victoria-metrics-data> -snapshot.createURL=http://localhost:8428/snapshot/create -dst=gs://<bucket>/<path/to/new/backup> -origin=gs://<bucket>/<path/to/existing/backup>
```

ShellCopy

It saves time and network bandwidth costs by performing server-side copy for the shared data from the `-origin` to `-dst`. Typical object storage just creates new names for already existing objects when performing server-side copy, so this operation should be fast and inexpensive. Unfortunately, there are object storage systems such as [S3 Glacier](https://aws.amazon.com/s3/storage-classes/glacier/), which make full copies for the copied objects during server-side copy. This may significantly slow down server-side copy and make it very expensive.

### Incremental backups [#](https://docs.victoriametrics.com/vmbackup/#incremental-backups)

Incremental backups are performed if `-dst` points to an already existing backup. In this case only new data is uploaded to remote storage. It saves time and network bandwidth costs when working with big backups:

```
./vmbackup -storageDataPath=</path/to/victoria-metrics-data> -snapshot.createURL=http://localhost:8428/snapshot/create -dst=gs://<bucket>/<path/to/existing/backup>
```

ShellCopy

### Smart backups [#](https://docs.victoriametrics.com/vmbackup/#smart-backups)

Smart backups mean storing full daily backups into `YYYYMMDD` folders and creating incremental hourly backup into `latest` folder:

*   Run the following command every hour:
    

```
./vmbackup -storageDataPath=</path/to/victoria-metrics-data> -snapshot.createURL=http://localhost:8428/snapshot/create -dst=gs://<bucket>/latest
```

ShellCopy

This command creates an [instant snapshot](https://docs.victoriametrics.com/single-server-victoriametrics/#how-to-work-with-snapshots) and uploads it to `gs://<bucket>/latest`. It uploads only the changed data (aka incremental backup). This saves network bandwidth costs and time when backing up large amounts of data.

*   Run the following command once a day:
    

```
./vmbackup -origin=gs://<bucket>/latest -dst=gs://<bucket>/<YYYYMMDD>
```

ShellCopy

This command makes [server-side copy](https://docs.victoriametrics.com/vmbackup/#server-side-copy-of-the-existing-backup) of the backup from `gs://<bucket>/latest` to `gs://<bucket>/<YYYYMMDD>`, were `<YYYYMMDD>` is the current date like `20240125`. Server-side copy of the backup should be fast on most object storage systems, since it just creates new names for already existing objects. The server-side copy can be slow on some object storage systems such as [S3 Glacier](https://aws.amazon.com/s3/storage-classes/glacier/), since they may perform full object copy instead of creating new names for already existing objects. This may be slow and expensive.

The `smart backups` approach described above saves network bandwidth costs on hourly backups (since they are incremental) and allows recovering data from either the last hour (the `latest` backup) or from any day (`YYYYMMDD` backups).

Note that hourly backup shouldn’t run when creating daily backup.

Do not forget to remove old backups when they are no longer needed in order to save storage costs.

See also [vmbackupmanager tool](https://docs.victoriametrics.com/vmbackupmanager/) for automating smart backups.

### Server-side copy of the existing backup [#](https://docs.victoriametrics.com/vmbackup/#server-side-copy-of-the-existing-backup)

Sometimes it is needed to make server-side copy of the existing backup. This can be done by specifying the source backup path via `-origin` command-line flag, while the destination path for backup copy must be specified via `-dst` command-line flag. For example, the following command copies backup from `gs://bucket/foo` to `gs://bucket/bar`:

```
./vmbackup -origin=gs://bucket/foo -dst=gs://bucket/bar
```

ShellCopy

The `-origin` and `-dst` must point to the same object storage bucket or to the same filesystem.

The server-side backup copy is usually performed at much faster speed comparing to the usual backup, since backup data isn’t transferred between the remote storage and locally running `vmbackup` tool. Object storage systems usually just make new names for already existing objects during server-side copy. Unfortunately there are systems such as [S3 Glacier](https://aws.amazon.com/s3/storage-classes/glacier/), which perform full object copy during server-side copying. This may be slow and expensive.

If the `-dst` already contains some data, then its’ contents is synced with the `-origin` data. This allows making incremental server-side copies of backups.

### Backups for VictoriaMetrics cluster [#](https://docs.victoriametrics.com/vmbackup/#backups-for-victoriametrics-cluster)

`vmbackup` can be used for creating backups for [VictoriaMetrics cluster](https://docs.victoriametrics.com/cluster-victoriametrics/). In order to perform a complete backup for the cluster, `vmbackup` must be run on each `vmstorage` node in cluster. Backups must be placed into different directories on the remote storage in order to avoid conflicts between backups from different nodes.

For example, when creating a backup with 3 `vmstorage` nodes, the following commands must be run:

```
vmstorage-1$ /vmbackup -storageDataPath=</path/to/vmstorage-data> -snapshot.createURL=http://vmstorage1:8482/snapshot/create -dst=gs://<bucket>/vmstorage-1 vmstorage-2$ /vmbackup -storageDataPath=</path/to/vmstorage-data> -snapshot.createURL=http://vmstorage2:8482/snapshot/create -dst=gs://<bucket>/vmstorage-2 vmstorage-3$ /vmbackup -storageDataPath=</path/to/vmstorage-data> -snapshot.createURL=http://vmstorage3:8482/snapshot/create -dst=gs://<bucket>/vmstorage-3
```

ShellCopy

Note that `vmbackup` needs access to data folder of every `vmstorage` node. It is recommended to run `vmbackup` on the same machine where `vmstorage` is running. For Kubernetes deployments it is recommended to use [sidecar containers](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/) for running `vmbackup` on the same pod with `vmstorage`.

How does it work? [#](https://docs.victoriametrics.com/vmbackup/#how-does-it-work)
----------------------------------------------------------------------------------

The backup algorithm is the following:

1.  Create a snapshot by querying the provided `-snapshot.createURL`
    
2.  Collect information about files in the created snapshot, in the `-dst` and in the `-origin`.
    
3.  Determine which files in `-dst` are missing in the created snapshot, and delete them. These are usually small files, which are already merged into bigger files in the snapshot.
    
4.  Determine which files in the created snapshot are missing in `-dst`. These are usually small new files and bigger merged files.
    
5.  Determine which files from step 3 exist in the `-origin`, and perform server-side copy of these files from `-origin` to `-dst`. These are usually the biggest and the oldest files, which are shared between backups.
    
6.  Upload the remaining files from step 3 from the created snapshot to `-dst`.
    
7.  Delete the created snapshot.
    

The algorithm splits source files into 1 GiB chunks in the backup. Each chunk is stored as a separate file in the backup. Such splitting balances between the number of files in the backup and the amounts of data that needs to be re-transferred after temporary errors.

`vmbackup` relies on [instant snapshot](https://medium.com/@valyala/how-victoriametrics-makes-instant-snapshots-for-multi-terabyte-time-series-data-e1f3fb0e0282) properties:

*   All the files in the snapshot are immutable.
    
*   Old files are periodically merged into new files.
    
*   Smaller files have higher probability to be merged.
    
*   Consecutive snapshots share many identical files.
    

These properties allow performing fast and cheap incremental backups and server-side copying from `-origin` paths. See [this article](https://medium.com/@valyala/speeding-up-backups-for-big-time-series-databases-533c1a927883) for more details. `vmbackup` can work improperly or slowly when these properties are violated.

Troubleshooting [#](https://docs.victoriametrics.com/vmbackup/#troubleshooting)
-------------------------------------------------------------------------------

*   If the backup is slow, then try setting higher value for `-concurrency` flag. This will increase the number of concurrent workers that upload data to backup storage.
    
*   If `vmbackup` eats all the network bandwidth or CPU, then either decrease the `-concurrency` command-line flag value or set `-maxBytesPerSecond` command-line flag value to lower value.
    
*   If `vmbackup` consumes all the CPU on systems with big number of CPU cores, then try running it with `-filestream.disableFadvise` command-line flag.
    
*   If `vmbackup` has been interrupted due to temporary error, then just restart it with the same args. It will resume the backup process.
    
*   Backups created from [single-node VictoriaMetrics](https://docs.victoriametrics.com/single-server-victoriametrics/) cannot be restored at [cluster VictoriaMetrics](https://docs.victoriametrics.com/cluster-victoriametrics/) and vice versa.
    

Advanced usage [#](https://docs.victoriametrics.com/vmbackup/#advanced-usage)
-----------------------------------------------------------------------------

### Providing credentials as a file [#](https://docs.victoriametrics.com/vmbackup/#providing-credentials-as-a-file)

Obtaining credentials from a file.

Add flag `-credsFilePath=/etc/credentials` with the following content:

*   for S3 (AWS, MinIO or other S3 compatible storages):
    
    ```
    \[default\] aws\_access\_key\_id=theaccesskey aws\_secret\_access\_key=thesecretaccesskeyvalue
    ```
    
    ShellCopy
    
*   for GCP cloud storage:
    
    ```
    {        "type": "service\_account",        "project\_id": "project-id",        "private\_key\_id": "key-id",        "private\_key": "-----BEGIN PRIVATE KEY-----\\nprivate-key\\n-----END PRIVATE KEY-----\\n",        "client\_email": "service-account-email",        "client\_id": "client-id",        "auth\_uri": "https://accounts.google.com/o/oauth2/auth",        "token\_uri": "https://accounts.google.com/o/oauth2/token",        "auth\_provider\_x509\_cert\_url": "https://www.googleapis.com/oauth2/v1/certs",        "client\_x509\_cert\_url": "https://www.googleapis.com/robot/v1/metadata/x509/service-account-email" }
    ```
    
    JSONCopy
    

### Providing credentials via env variables [#](https://docs.victoriametrics.com/vmbackup/#providing-credentials-via-env-variables)

Obtaining credentials from env variables.

*   For AWS S3 compatible storages set env variable `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`. Also you can set env variable `AWS_SHARED_CREDENTIALS_FILE` with path to credentials file.
    
*   For GCE cloud storage set env variable `GOOGLE_APPLICATION_CREDENTIALS` with path to credentials file.
    
*   For Azure storage use one of these env variables:
    
    The `AZURE_STORAGE_DOMAIN` can be used for optionally overriding the default domain for the Azure storage service.
    

*   `AZURE_STORAGE_ACCOUNT_CONNECTION_STRING`: use a connection string (must be either SAS Token or Account/Key)
    
*   `AZURE_STORAGE_ACCOUNT_NAME` and `AZURE_STORAGE_ACCOUNT_KEY`: use a specific account name and key (either primary or secondary)
    
*   `AZURE_USE_DEFAULT_CREDENTIAL` and `AZURE_STORAGE_ACCOUNT_NAME`: use the `DefaultAzureCredential` to allow the Azure library to search for multiple options (for example, managed identity related variables). Note that if multiple credentials are available, it is required to specify the `AZURE_CLIENT_ID` to select specific credentials.
    

Please, note that `vmbackup` will use credentials provided by cloud providers metadata service [when applicable](https://docs.victoriametrics.com/vmbackup/#using-cloud-providers-metadata-service).

### Using cloud providers metadata service [#](https://docs.victoriametrics.com/vmbackup/#using-cloud-providers-metadata-service)

`vmbackup` and `vmbackupmanager` will automatically use cloud providers metadata service in order to obtain credentials if they are running in cloud environment and credentials are not explicitly provided via flags or env variables.

### Providing credentials in Kubernetes [#](https://docs.victoriametrics.com/vmbackup/#providing-credentials-in-kubernetes)

The simplest way to provide credentials in Kubernetes is to use [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) and inject them into the pod as environment variables. For example, the following secret can be used for AWS S3 credentials:

```
apiVersion: v1 kind: Secret metadata:   name: vmbackup-credentials data:   access\_key: key   secret\_key: secret
```

YAMLCopy

And then it can be injected into the pod as environment variables:

```
... env: - name: AWS\_ACCESS\_KEY\_ID   valueFrom:     secretKeyRef:       key: access\_key       name: vmbackup-credentials - name: AWS\_SECRET\_ACCESS\_KEY   valueFrom:     secretKeyRef:       key: secret\_key       name: vmbackup-credentials ...
```

YAMLCopy

A more secure way is to use IAM roles to provide tokens for pods instead of managing credentials manually.

For AWS deployments it will be required to configure [IAM roles for service accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html). In order to use IAM roles for service accounts with `vmbackup` or `vmbackupmanager` it is required to create ServiceAccount with IAM role mapping:

```
apiVersion: v1 kind: ServiceAccount metadata:   name: monitoring-backups   annotations:     eks.amazonaws.com/role-arn: arn:aws:iam::{ACCOUNT\_ID}:role/{ROLE\_NAME}
```

YAMLCopy

And [configure pod to use service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/). After this `vmbackup` and `vmbackupmanager` will automatically use IAM role for service account in order to obtain credentials.

For GCP deployments it will be required to configure [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity). In order to use Workload Identity with `vmbackup` or `vmbackupmanager` it is required to create ServiceAccount with Workload Identity annotation:

```
--- apiVersion: v1 kind: ServiceAccount metadata:   name: monitoring-backups   annotations:     iam.gke.io/gcp-service-account: {sa\_name}@{project\_name}.iam.gserviceaccount.com
```

YAMLCopy

And [configure pod to use service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/). After this `vmbackup` and `vmbackupmanager` will automatically use Workload Identity for service account in order to obtain credentials.

### Using custom S3 endpoint [#](https://docs.victoriametrics.com/vmbackup/#using-custom-s3-endpoint)

Usage with s3 custom url endpoint. It is possible to use `vmbackup` with s3 compatible storages like minio, cloudian, etc. You have to add a custom url endpoint via flag:

*   for MinIO
    
    ```
    -customS3Endpoint=http://localhost:9000
    ```
    
    ShellCopy
    
*   for aws gov region
    
    ```
    -customS3Endpoint=https://s3-fips.us-gov-west-1.amazonaws.com
    ```
    
    ShellCopy
    

### Permanent deletion of objects in S3-compatible storages [#](https://docs.victoriametrics.com/vmbackup/#permanent-deletion-of-objects-in-s3-compatible-storages)

`vmbackup` and [vmbackupmanager](https://docs.victoriametrics.com/vmbackupmanager/) use standard delete operation for S3-compatible object storage when performing [incremental backups](https://docs.victoriametrics.com/vmbackup/#incremental-backups). This operation removes only the current version of the object. This works OK in most cases.

Sometimes it is needed to remove all the versions of an object. In this case pass `-deleteAllObjectVersions` command-line flag to `vmbackup`.

Alternatively, it is possible to use object storage lifecycle rules to remove non-current versions of objects automatically. Refer to the respective documentation for your object storage provider for more details.

