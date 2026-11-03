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
            then return.

            assign ds-parent-path-aux = substring(FullName, 1, r-index(FullName, PathSeparator) - 1).

            if ds-parent-path-aux = ""
            then return.

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

        ResetPath().

        assign file-info:file-name = ds-path-par.

        if file-info:full-pathname = ?
        then return.
        
        assign this-object:Exists         = true
               this-object:FullName       = file-info:full-pathname
               this-object:Name           = substring(FullName, r-index(FullName, PathSeparator) + 1)
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
               this-object:PathType       = GetPathType(file-info:file-type).
        
        if IsDirectory
        then do:
            input from os-dir(FullName).
                repeat:
                    import ds-name-aux ds-full-name-aux.

                    if ds-name-aux = "." or ds-name-aux = ".."
                    then next.

                    create tt-childs.
                    assign file-info:file-name        = ds-full-name-aux
                           tt-childs.name             = ds-name-aux
                           tt-childs.full-name        = ds-full-name-aux
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
                           tt-childs.path-type        = GetPathType(file-info:file-type)
                           ChildCount                 = ChildCount + 1.
                end.
            input close.
        end.
    end method.

    method private character GetPathType(
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

        if not IsDirectory
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

    method private void ResetPath():
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

    method public override character ToString():
        return this-object:FullName.
    end method.
end class.
