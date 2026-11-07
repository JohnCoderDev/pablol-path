using Progress.Lang.*.
using Pablol.Path.*.

class Pablol.Path.Path:
    define public property PathType       as character no-undo get. private set.
    define public property FullName       as character no-undo get. private set.
    define public property Name           as character no-undo get. private set.
    define public property BaseName       as character no-undo get. private set.
    define public property Extension      as character no-undo get. private set.
    define public property CreateTime     as datetime  no-undo get. private set.
    define public property ModifyTime     as datetime  no-undo get. private set.
    define public property IsDirectory    as logical   no-undo get. private set.
    define public property IsFile         as logical   no-undo get. private set.
    define public property IsWriteable    as logical   no-undo get. private set.
    define public property IsReadable     as logical   no-undo get. private set.
    define public property IsHidden       as logical   no-undo get. private set.
    define public property IsPipe         as logical   no-undo get. private set.
    define public property IsSymbolicLink as logical   no-undo get. private set.
    define public property Size           as integer   no-undo get. private set.
    define public property ChildCount     as integer   no-undo get. private set.
    define public property Exists         as logical   no-undo get. private set.

    define public property PathSeparator as character no-undo
        get:
            return (if opsys = "Unix" then "/" else "\").
        end.

    define public property Parent as Path no-undo
        get:
            define variable ds-parent-path-aux as character no-undo.

            if not this-object:Exists
            then return ?.

            assign ds-parent-path-aux = substring(
                                            this-object:FullName,
                                            1,
                                            r-index(FullName, PathSeparator) - 1
                                        ).

            if ds-parent-path-aux = ""
            then return ?.

            return new Path(ds-parent-path-aux).
        end.

    define private temp-table tt-childs no-undo
        field full-name        as character
        field path-type        as character
        field name             as character
        field base-name        as character
        field extension        as character
        field create-time      as datetime
        field modify-time      as datetime
        field is-file          as logical
        field is-directory     as logical
        field is-writeable     as logical
        field is-readable      as logical
        field is-hidden        as logical
        field is-pipe          as logical
        field is-symbolic-link as logical
        field size             as integer.

    constructor Path(
        input ds-path-par as character
    ):
        ReadPath(ds-path-par).
    end constructor.

    method public void ReadPath(
        input ds-path-par as character
    ):
        define variable ds-name-aux      as character no-undo.
        define variable ds-full-name-aux as character no-undo.

        _ResetPath().

        assign file-info:file-name = ds-path-par.

        if file-info:full-pathname = ?
        then return.

        assign this-object:Exists         = true
               this-object:FullName       = file-info:full-pathname
               this-object:Name           = substring(
                                                this-object:FullName,
                                                r-index(
                                                    this-object:FullName,
                                                    this-object:PathSeparator
                                                ) + 1
                                            )
               this-object:BaseName       = substring(Name, 1, r-index(Name, ".") - 1)
               this-object:Extension      = substring(Name, r-index(Name, ".") + 1)
               this-object:CreateTime     = datetime(file-info:file-create-date, file-info:file-create-time * 1000)
               this-object:ModifyTime     = datetime(file-info:file-mod-date, file-info:file-mod-time * 1000)
               this-object:Size           = file-info:file-size
               this-object:IsWriteable    = (index(file-info:file-type, "W") > 0)
               this-object:IsReadable     = (index(file-info:file-type, "R") > 0)
               this-object:IsHidden       = (index(file-info:file-type, "H") > 0)
               this-object:IsPipe         = (index(file-info:file-type, "P") > 0)
               this-object:IsSymbolicLink = (index(file-info:file-type, "L") > 0)
               this-object:IsDirectory    = (index(file-info:file-type, "D") > 0)
               this-object:IsFile         = (index(file-info:file-type, "F") > 0)
               this-object:PathType       = this-object:_GetPathType(file-info:file-type).

        if this-object:IsDirectory
        then do:
            input from os-dir(this-object:FullName).
                repeat:
                    import ds-name-aux ds-full-name-aux.

                    if ds-name-aux = "." or ds-name-aux = ".."
                    then next.

                    create tt-childs.
                    assign file-info:file-name        = ds-full-name-aux
                           tt-childs.name             = ds-name-aux
                           tt-childs.full-name        = file-info:full-pathname
                           tt-childs.base-name        = substring(ds-name-aux, 1, r-index(ds-name-aux, ".") - 1)
                           tt-childs.extension        = substring(ds-name-aux, r-index(ds-name-aux, ".") + 1)
                           tt-childs.create-time      = datetime(file-info:file-create-date, file-info:file-create-time * 1000)
                           tt-childs.modify-time      = datetime(file-info:file-mod-date, file-info:file-mod-time * 1000)
                           tt-childs.is-directory     = (index(file-info:file-type, "D") > 0)
                           tt-childs.is-file          = (index(file-info:file-type, "F") > 0)
                           tt-childs.is-writeable     = (index(file-info:file-type, "W") > 0)
                           tt-childs.is-readable      = (index(file-info:file-type, "R") > 0)
                           tt-childs.is-hidden        = (index(file-info:file-type, "H") > 0)
                           tt-childs.is-pipe          = (index(file-info:file-type, "P") > 0)
                           tt-childs.is-symbolic-link = (index(file-info:file-type, "L") > 0)
                           tt-childs.size             = file-info:file-size
                           tt-childs.path-type        = this-object:_GetPathType(file-info:file-type)
                           this-object:ChildCount     = this-object:ChildCount + 1.
                end.
            input close.
        end.
    end method.

    method private character _GetPathType(
        input ds-file-type-par as character
    ):
        case true:
            when index(ds-file-type-par, "D") > 0 then return "Directory".
            when index(ds-file-type-par, "F") > 0 then return "File".
            when index(ds-file-type-par, "M") > 0 then return "ABL Library Member".
            when index(ds-file-type-par, "S") > 0 then return "Special Device".
            when index(ds-file-type-par, "X") > 0 then return "Unknown".
        end case.
    end method.

    method public Path GetChild():
        return this-object:GetChild("").
    end method.

    method public Path GetChild(
        input ds-where-par as character
    ):
        define variable o-paths-aux as Path extent no-undo.
        assign o-paths-aux = this-object:GetChilds(ds-where-par).

        if extent(o-paths-aux) > 0
        then return o-paths-aux[1].
    end method.

    method public Path extent GetChilds():
        return this-object:GetChilds("").
    end method.

    method public Path extent GetChilds(
        input ds-where-par as character
    ):
        define variable h-query-tt-childs-aux as handle      no-undo.
        define variable o-paths-aux           as Path extent no-undo.

        if not this-object:IsDirectory
        then do:
            return error new AppError(
                "Path is not a directory. Cannot get childs.",
                -000100001
            ).
        end.

        create query h-query-tt-childs-aux.
        h-query-tt-childs-aux:set-buffers(buffer tt-childs:handle).
        h-query-tt-childs-aux:query-prepare(
            "preselect each " + (buffer tt-childs:name) + " no-lock " + ds-where-par
        ).
        h-query-tt-childs-aux:query-open().

        assign extent(o-paths-aux) = h-query-tt-childs-aux:num-results.

        h-query-tt-childs-aux:get-first().

        do while not h-query-tt-childs-aux:query-off-end:
            assign o-paths-aux[h-query-tt-childs-aux:current-result-row] = new Path(tt-childs.full-name).
            h-query-tt-childs-aux:get-next().
        end.

        h-query-tt-childs-aux:query-close().
        delete object h-query-tt-childs-aux.

        return o-paths-aux.
    end method.

    method private void _ResetPath():
        assign this-object:PathType       = ?
               this-object:FullName       = ?
               this-object:Name           = ?
               this-object:BaseName       = ?
               this-object:Extension      = ?
               this-object:CreateTime     = ?
               this-object:ModifyTime     = ?
               this-object:IsDirectory    = ?
               this-object:IsFile         = ?
               this-object:IsWriteable    = ?
               this-object:IsReadable     = ?
               this-object:IsHidden       = ?
               this-object:IsPipe         = ?
               this-object:IsSymbolicLink = ?
               this-object:Size           = 0
               this-object:ChildCount     = 0
               this-object:Exists         = false.

        empty temp-table tt-childs.
    end method.

    method public Path CreateChildDirectory(
        input ds-name-par as character
    ):
        define variable nr-os-status-aux as integer   no-undo.
        define variable ds-new-path-aux  as character no-undo.

        if this-object:Has(ds-name-par)
        then do:
            return error new AppError(
                "Child with given name already exists: '" + ds-name-par + "'",
                -000100002
            ).
        end.

        if not this-object:IsDirectory
        then do:
            return error new AppError(
                "Path is not a directory. Cannot create child directory: '" + ds-name-par + "'",
                -000100003
            ).
        end.

        assign ds-new-path-aux = this-object:FullName + this-object:PathSeparator + ds-name-par.

        os-create-dir value(this-object:FullName + this-object:PathSeparator + ds-name-par).

        assign nr-os-status-aux = os-error.

        if nr-os-status-aux <> 0
        then do:
            return error new AppError(
                "Failed to create directory: '" + ds-name-par + "'. OS error code: " + string(nr-os-status-aux),
                -000100004
            ).
        end.

        assign file-info:file-name = ds-new-path-aux.

        if file-info:full-pathname = ?
        then do:
            return error new AppError(
                "Failed to create directory: '" + ds-name-par + "'",
                -000100005
            ).
        end.

        create tt-childs.
        assign file-info:file-name        = ds-new-path-aux
               tt-childs.name             = ds-name-par
               tt-childs.full-name        = file-info:full-pathname
               tt-childs.base-name        = substring(ds-name-par, 1, r-index(ds-name-par, ".") - 1)
               tt-childs.extension        = substring(ds-name-par, r-index(ds-name-par, ".") + 1)
               tt-childs.create-time      = datetime(file-info:file-create-date, file-info:file-create-time * 1000)
               tt-childs.modify-time      = datetime(file-info:file-mod-date, file-info:file-mod-time * 1000)
               tt-childs.is-directory     = (index(file-info:file-type, "D") > 0)
               tt-childs.is-file          = (index(file-info:file-type, "F") > 0)
               tt-childs.is-writeable     = (index(file-info:file-type, "W") > 0)
               tt-childs.is-readable      = (index(file-info:file-type, "R") > 0)
               tt-childs.is-hidden        = (index(file-info:file-type, "H") > 0)
               tt-childs.is-pipe          = (index(file-info:file-type, "P") > 0)
               tt-childs.is-symbolic-link = (index(file-info:file-type, "L") > 0)
               tt-childs.size             = file-info:file-size
               tt-childs.path-type        = this-object:_GetPathType(file-info:file-type)
               this-object:ChildCount     = this-object:ChildCount + 1.
        
        return new Path(ds-new-path-aux).
    end method.

    method public Path CreateChildFile(
        input ds-name-par as character
    ):
        return this-object:CreateChildFile(ds-name-par, "").
    end method.

    method public Path CreateChildFile(
        input ds-name-par    as character,
        input ds-content-par as longchar
    ):
        define variable nr-os-status-aux as integer   no-undo.
        define variable ds-new-path-aux  as character no-undo.

        if this-object:Has(ds-name-par)
        then do:
            return error new AppError(
                "Child with given name already exists: '" + ds-name-par + "'",
                -000100006
            ).
        end.

        if not this-object:IsDirectory
        then do:
            return error new AppError(
                "Path is not a directory. Cannot create child file: '" + ds-name-par + "'",
                -000100007
            ).
        end.

        assign ds-name-par     = trim(ds-name-par, this-object:PathSeparator)
               ds-new-path-aux = this-object:FullName + this-object:PathSeparator + ds-name-par.

        copy-lob from ds-content-par to file ds-new-path-aux no-convert.

        assign file-info:file-name = ds-new-path-aux.

        create tt-childs.
        assign file-info:file-name        = ds-new-path-aux
               tt-childs.name             = ds-name-par
               tt-childs.full-name        = file-info:full-pathname
               tt-childs.base-name        = substring(ds-name-par, 1, r-index(ds-name-par, ".") - 1)
               tt-childs.extension        = substring(ds-name-par, r-index(ds-name-par, ".") + 1)
               tt-childs.create-time      = datetime(file-info:file-create-date, file-info:file-create-time * 1000)
               tt-childs.modify-time      = datetime(file-info:file-mod-date, file-info:file-mod-time * 1000)
               tt-childs.is-directory     = (index(file-info:file-type, "D") > 0)
               tt-childs.is-file          = (index(file-info:file-type, "F") > 0)
               tt-childs.is-writeable     = (index(file-info:file-type, "W") > 0)
               tt-childs.is-readable      = (index(file-info:file-type, "R") > 0)
               tt-childs.is-hidden        = (index(file-info:file-type, "H") > 0)
               tt-childs.is-pipe          = (index(file-info:file-type, "P") > 0)
               tt-childs.is-symbolic-link = (index(file-info:file-type, "L") > 0)
               tt-childs.size             = file-info:file-size
               tt-childs.path-type        = this-object:_GetPathType(file-info:file-type)
               this-object:ChildCount     = this-object:ChildCount + 1.

        return new Path(ds-new-path-aux).
    end method.

    method public logical DeleteChild(
        input ds-name-par as character
    ):
        define variable ds-full-name-aux as character no-undo.
        define variable nr-os-status-aux as integer   no-undo.

        if not this-object:IsDirectory
        then do:
            return error new AppError(
                "Path is not a directory. Cannot delete child: '" + ds-name-par + "'",
                -000100010
            ).
        end.

        if this-object:Has(ds-name-par)
        then do:
            assign ds-full-name-aux = this-object:FullName + this-object:PathSeparator + ds-name-par.

            os-delete value(ds-full-name-aux) recursive.

            assign nr-os-status-aux = os-error.

            if nr-os-status-aux <> 0
            then do:
                return error new AppError(
                    "Failed to delete child: '" + ds-name-par + "'. OS error code: " + string(nr-os-status-aux),
                    -000100011
                ).
            end.

            assign this-object:ChildCount = this-object:ChildCount - 1.

            return true.
        end.

        return false.
    end method.

    method public Path RenameChild(
        input ds-old-name-par as character,
        input ds-new-name-par as character
    ):
        define variable ds-old-full-name-aux as character no-undo.
        define variable ds-new-full-name-aux as character no-undo.
        define variable nr-os-status-aux     as integer   no-undo.

        if not this-object:Has(ds-old-name-par)
        then do:
            return error new AppError(
                "Child with given old name does not exist: '" + ds-old-name-par + "'",
                -000100008
            ).
        end.

        if this-object:Has(ds-new-name-par)
        then do:
            return error new AppError(
                "Child with given new name already exists: '" + ds-new-name-par + "'",
                -000100009
            ).
        end.

        assign ds-old-full-name-aux = this-object:FullName + this-object:PathSeparator + ds-old-name-par
               ds-new-full-name-aux = this-object:FullName + this-object:PathSeparator + ds-new-name-par.
        
        os-rename value(ds-old-full-name-aux) value(ds-new-full-name-aux).

        assign nr-os-status-aux = os-error.

        if nr-os-status-aux <> 0
        then do:
            return error new AppError(
                "Failed to rename child from '" + ds-old-name-par + "' to '" 
                    + ds-new-name-par + "'. OS error code: " + string(nr-os-status-aux),
                -000100012
            ).
        end.

        find first tt-childs
            where tt-childs.name = ds-old-name-par
        exclusive-lock.

        assign file-info:file-name        = ds-new-full-name-aux
               tt-childs.name             = ds-new-name-par
               tt-childs.full-name        = file-info:full-pathname
               tt-childs.base-name        = substring(ds-new-name-par, 1, r-index(ds-new-name-par, ".") - 1)
               tt-childs.extension        = substring(ds-new-name-par, r-index(ds-new-name-par, ".") + 1)
               tt-childs.create-time      = datetime(file-info:file-create-date, file-info:file-create-time * 1000)
               tt-childs.modify-time      = datetime(file-info:file-mod-date, file-info:file-mod-time * 1000)
               tt-childs.is-directory     = (index(file-info:file-type, "D") > 0)
               tt-childs.is-file          = (index(file-info:file-type, "F") > 0)
               tt-childs.is-writeable     = (index(file-info:file-type, "W") > 0)
               tt-childs.is-readable      = (index(file-info:file-type, "R") > 0)
               tt-childs.is-hidden        = (index(file-info:file-type, "H") > 0)
               tt-childs.is-pipe          = (index(file-info:file-type, "P") > 0)
               tt-childs.is-symbolic-link = (index(file-info:file-type, "L") > 0)
               tt-childs.size             = file-info:file-size
               tt-childs.path-type        = this-object:_GetPathType(file-info:file-type).

        return new Path(ds-new-full-name-aux).
    end method.

    method public logical Has(
        input ds-name-par as character
    ):
        return can-find(
            first tt-childs
                where tt-childs.name matches ds-name-par
        ).
    end method.

    method public override character ToString():
        return this-object:FullName.
    end method.
end class.
