# BTRFS

here I document the design of my setup and some core functionality.

## Subvolume Layout

- @ for Root: Contains your main operating system. Snapshots here cover most system directories.
- @home for User Data: Contains user directories. Typically excluded from system snapshots unless you want to back up user data as well.
- @srv for Services: Useful if you run server applications whose data you want to snapshot separately.
- @log for Logs: Keeping logs in a separate subvolume can be beneficial because logs can grow rapidly and are not usually necessary for system restoration. You might exclude this subvolume from snapshots.
- @cache for Cache Files: Similarly, caches are transient and can be excluded from snapshots.
- @tmp for Temporary Files: If you want to separate temporary files, which can also be excluded from snapshots.

Optional:
- @swap for Swapfile: to support hibernation or just generally swap
[docs](https://btrfs.readthedocs.io/en/latest/ch-swapfile.html) for more details.

## Snapshots

exclude: @tmp, @cache, @log
