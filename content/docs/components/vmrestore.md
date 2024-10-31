---
title: "vmrestore"
date: 2024-10-28T23:16:24+08:00
weight: 5
---

`vmrestore` restores data from backups created by [vmbackup](https://docs.victoriametrics.com/vmbackup/).

Restore process can be interrupted at any time. It is automatically resumed from the interruption point when restarting `vmrestore` with the same args.

Usage [#](https://docs.victoriametrics.com/vmrestore/#usage)
------------------------------------------------------------

VictoriaMetrics must be stopped during the restore process.

Run the following command to restore backup from the given `-src` into the given `-storageDataPath`:

```
./vmrestore -src=<storageType>://<path/to/backup> -storageDataPath=<local/path/to/restore>
```

Shell HelpCopy

*   `<storageType>://<path/to/backup>` is the path to backup made with [vmbackup](https://docs.victoriametrics.com/vmbackup/). `vmrestore` can restore backups from the following storage types:
    

*   [GCS](https://cloud.google.com/storage/). Example: `-src=gs://<bucket>/<path/to/backup>`
    
*   [S3](https://aws.amazon.com/s3/). Example: `-src=s3://<bucket>/<path/to/backup>`
    
*   [Azure Blob Storage](https://azure.microsoft.com/en-us/products/storage/blobs/). Example: `-src=azblob://<container>/<path/to/backup>`
    
*   Any S3-compatible storage such as [MinIO](https://github.com/minio/minio), [Ceph](https://docs.ceph.com/en/pacific/radosgw/s3/) or [Swift](https://platform.swiftstack.com/docs/admin/middleware/s3_middleware.html). See [these docs](https://docs.victoriametrics.com/vmrestore/#advanced-usage) for details.
    
*   Local filesystem. Example: `-src=fs://</absolute/path/to/backup>`. Note that `vmbackup` prevents from storing the backup into the directory pointed by `-storageDataPath` command-line flag, since this directory should be managed solely by VictoriaMetrics or `vmstorage`.
    

*   `<local/path/to/restore>` is the path to folder where data will be restored. This folder must be passed to VictoriaMetrics in `-storageDataPath` command-line flag after the restore process is complete.
    

The original `-storageDataPath` directory may contain old files. They will be substituted by the files from backup, i.e. the end result would be similar to [rsync –delete](https://askubuntu.com/questions/476041/how-do-i-make-rsync-delete-files-that-have-been-deleted-from-the-source-folder).

Troubleshooting [#](https://docs.victoriametrics.com/vmrestore/#troubleshooting)
--------------------------------------------------------------------------------

*   See [how to setup credentials via environment variables](https://docs.victoriametrics.com/vmbackup/#providing-credentials-via-env-variables).
    
*   If `vmrestore` eats all the network bandwidth, then set `-maxBytesPerSecond` to the desired value.
    
*   If `vmrestore` has been interrupted due to temporary error, then just restart it with the same args. It will resume the restore process.