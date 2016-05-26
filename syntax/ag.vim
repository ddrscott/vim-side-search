syntax match agPath "\v^(\d+[:-])@!.+$"
highlight link agPath Directory

syntax match agContext "\v^(\d+\-).*$"
highlight link agContext Comment

syntax match agComment "\v^[#-].*"
highlight link agComment Comment

