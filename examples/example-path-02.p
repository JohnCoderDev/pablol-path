using Pablol.Path.Path.

define variable o-path-aux         as Path no-undo.
define variable o-created-dir-aux  as Path no-undo.
define variable o-created-file-aux as Path no-undo.

assign o-path-aux         = new Path("C:\Temp")
       o-created-dir-aux  = o-path-aux:CreateChildDirectory("TestDir")
       o-created-file-aux = o-path-aux:CreateChildFile("TestFile.txt", "Hello world!").

message
    o-path-aux skip
    o-created-dir-aux skip
    o-created-file-aux skip

    o-path-aux:ChildCount skip
    o-path-aux:Has("TestFile.txt") skip
    o-path-aux:Has("TestDir") skip
    view-as alert-box.

assign o-created-file-aux = o-path-aux:RenameChild("TestFile.txt", "TestFileRenamed.txt")
       o-created-dir-aux  = o-path-aux:RenameChild("TestDir", "TestDirRenamed").

message
    o-created-file-aux:Name
    o-created-dir-aux:Name
    view-as alert-box.

o-path-aux:DeleteChild(o-created-dir-aux:Name).
o-path-aux:DeleteChild(o-created-file-aux:Name).
