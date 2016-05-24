syntax match agContext "\v^(\d+\-).*$"
highlight link agContext Comment

syntax match agPath "\v^(\d+[:-])@!.+$"
highlight link agPath Directory
