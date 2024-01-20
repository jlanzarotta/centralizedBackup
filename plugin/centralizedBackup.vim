"-------------------------------------------------------------------------------
"  Description: Use VMS style centralized versioned backup
"    Copyright: Copyright (C) 2010-2024 Jeff Lanzarotta
"   Maintainer: Jeff Lanzarotta
"      Version: 1.2
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

    " Check and see of the global value is set.  If not, default to 10
    " backups.
    if ! exists("g:backup_purge")
        let g:backup_purge = 10
    endif

    if has ("vms")
        " Backup not needed for vms as vms has a full featured filesystem
        " which includes versioning.
        set nowritebackup
        set nobackup
        set backupext=-Backup

        function s:do_purge(doc_path)
            if g:backup_purge > 0
                execute ":silent :!PURGE /NoLog /Keep=" . g:backup_purge . " " . a:doc_path
            endif
        endfunction do_purge

        autocmd BufWritePre * :call s:do_purge(fnameescape(expand('<afile>:p')))
    else
        " Non VMS type systems.
        if !exists("g:backup_directory")
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

        function s:make_backup_directory(path)
            if strlen (finddir(a:path)) == 0
                call mkdir(a:path, "p", 0775)

                if has ("os2")          ||
                    \ has ("win16")     ||
                    \ has ("win32")     ||
                    \ has ("win64")     ||
                    \ has ("dos16")     ||
                    \ has ("dos32")
                    execute '!attrib "' . a:path . '"'
              endif
            endif
        endfunction

        function s:get_backup_file_version(filename)
            return eval (
            \ strpart (
                \ a:filename,
                \ strridx (a:filename, ";") + 1))
        endfunction

        function s:version_compare(left, right)
            let l:left_version = s:get_backup_file_version(a:left)
            let l:right_version = s:get_backup_file_version(a:right)
            return l:left_version == l:right_version
                \ ? 0
                \ : l:left_version > l:right_version
                \ ? 1
                \ : -1
        endfunction

        function s:do_backup(backup_root, doc_path, doc_name)
            let new_doc_path = substitute(a:doc_path, ":", "", "ge")
            let l:backup_path = a:backup_root . '/' . new_doc_path

            " Remove trailing / or \.
            if (l:backup_path[strlen(l:backup_path)-1] == '/') || (l:backup_path[strlen(l:backup_path)-1] == '\')
                let l:backup_path=strpart(l:backup_path, 0, strlen(l:backup_path)-1)
            endif

            call s:make_backup_directory(l:backup_path)

            execute "set backupdir^=" . fnameescape(l:backup_path)

            let l:existing_backups = sort (
                \ split (
                \ glob (l:backup_path . '/' . a:doc_name . ';*'), "\n"),
                \ "s:version_compare")

            if empty (l:existing_backups)
                set backupext=;1
            else
                let &backupext=';' . string (s:get_backup_file_version(l:existing_backups[-1]) + 1)

                if g:backup_purge > 0 && len (l:existing_backups) > g:backup_purge
                    for l:Item in l:existing_backups[0 :  len (l:existing_backups) - g:backup_purge]
                        call delete (l:Item)
                    endfor
                endif
            endif
        endfunction do_backup

        autocmd BufWritePre * :call s:do_backup (
            \ g:backup_directory,
            \ expand('<afile>:p:h'),
            \ expand('<afile>:p:t'))
    endif

    finish
endif

"-------------------------------------------------------------------------------
" vim: filetype=vim foldmethod=marker
