using Pablol.Path.Path.

define variable o-path-aux as Path no-undo.

assign o-path-aux = new Path("C:\Temp").

message 
    o-path-aux
    o-path-aux:GetChild("where is-file")
    view-as alert-box.

