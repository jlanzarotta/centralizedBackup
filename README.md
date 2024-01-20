centralizedBackup
=================

Vim plugin that performs a "centralized" backup of files as they are edited.

As files are edited, the plugin automatically makes a backup copy of the file in the directory specified by the g:backup_directory variable.

On Windows, the default backup directory is %USERPROFILE%/.backup.  On other operating systems, $HOME/.backup.

When the backup is created, it is given a unique file extension using an autoicrementing number.  For example, ";1", ";2", ";3", etc.  The backup
is autoincremented up to the value set in the g:backup_purge variable.  The default is 10.  Once the number of backs reaches the limit, the oldest
backup is automatically deleted.

