"-------------------------------------------------------------------------------
"  Description: Use VMS style centralized versioned backup
"    Copyright: Copyright (C) 2010-2016 Jeff Lanzarotta
"   Maintainer: Jeff Lanzarotta
"      Version: 1.1
"        Usage: copy to plugin directory.
"-------------------------------------------------------------------------------
" Customize:
"   g:backup_directory  Name of backup directory local to edited file used for
"                       non VMS only. Since non VMS operating-systems don't
"                       know about version we would get ugly directory
"                       listings. So all backups are moved into a hidden
"                       directory.
"
"   g:backup_purge      Count of backups to hold - purge older ones. On VMS
"                       PURGE is used to delete older version 0 switched the
"                       feature off
"-------------------------------------------------------------------------------

if exists("s:loaded_centralized_backup") || version < 700
    finish
else
    let s:loaded_centralized_backup = 22

    if ! exists("g:backup_purge")
        let g:backup_purge = 10
    endif

    if has ("vms")
        " Backup not needed for vms as vms has a full featured filesystem
        " which includes versioning.
        set nowritebackup
        set nobackup
        set backupext=-Backup

        function s:Do_Purge(Doc_Path)
            if g:backup_purge > 0
                execute ":silent :!PURGE /NoLog /Keep=" . g:backup_purge . " " . a:Doc_Path
            endif
        endfunction Do_Purge

        autocmd BufWritePre * :call s:Do_Purge(expand('<afile>:p'))
    else
        " Non VMS type systems.
        if ! exists("g:backup_directory")
            if has('unix') || has('macunix')
                let g:backup_directory = $HOME . '/.backups'
            else
                let g:backup_directory = $VIM . '/.backups'
                if has('win32')
                    " MS-Windows.
                    if $USERPROFILE != ''
                        let g:backup_directory = $USERPROFILE . '/.backups'
                    endif
                endif
            endif
        endif

        set writebackup
        set backup
        set backupext=;1

        function s:MakeBackupDirectory(Path)
            if strlen (finddir (a:Path)) == 0
                call mkdir (a:Path, "p", 0775)

                if has ("os2")          ||
                    \ has ("win16")     ||
                    \ has ("win32")     ||
                    \ has ("win64")     ||
                    \ has ("dos16")     ||
                    \ has ("dos32")
                    execute '!attrib "' . a:Path . '"'
              endif
            endif
        endfunction

        function s:GetBackupFileVersion(Filename)
            return eval (
            \ strpart (
                \ a:Filename,
                \ strridx (a:Filename, ";") + 1))
        endfunction

        function s:Version_Compare(Left, Right)
            let l:Left_Ver = s:GetBackupFileVersion(a:Left)
            let l:Right_Ver = s:GetBackupFileVersion(a:Right)
            return l:Left_Ver == l:Right_Ver
                \ ? 0
                \ : l:Left_Ver > l:Right_Ver
                \ ? 1
                \ : -1
        endfunction

        function s:DoBackup(Backup_Root, Doc_Path, Doc_Name)
            let New_Doc_Path = substitute(a:Doc_Path, ":", "", "ge")

            let l:Backup_Path = a:Backup_Root . '/' . New_Doc_Path

            " Remove trailing / or \.
            if (l:Backup_Path[strlen(l:Backup_Path)-1] == '/') || (l:Backup_Path[strlen(l:Backup_Path)-1] == '\')
                let l:Backup_Path=strpart(l:Backup_Path, 0, strlen(l:Backup_Path)-1)
            endif

            call s:MakeBackupDirectory(l:Backup_Path)

            execute "set backupdir^=" . l:Backup_Path

            let l:Existing_Backups = sort (
                \ split (
                \ glob (l:Backup_Path . '/' . a:Doc_Name . ';*'), "\n"),
                \ "s:Version_Compare")

            if empty (l:Existing_Backups)
                set backupext=;1
            else
                let &backupext=';' . string (s:GetBackupFileVersion(l:Existing_Backups[-1]) + 1)

                if g:backup_purge > 0 && len (l:Existing_Backups) > g:backup_purge
                    for l:Item in l:Existing_Backups[0 :  len (l:Existing_Backups) - g:backup_purge]
                        call delete (l:Item)
                    endfor
                endif
            endif
        endfunction Do_Backup

        autocmd BufWritePre * :call s:DoBackup (
            \ g:backup_directory,
            \ expand ('<afile>:p:h'),
            \ expand ('<afile>:p:t'))
    endif

    finish
endif

"-------------------------------------------------------------------------------
" vim: filetype=vim foldmethod=marker
