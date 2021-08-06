syntax match rgPath "\v^(\d+[:-])@!.+$"
highlight link rgPath Directory

syntax match rgContext "\v^(\d+\-).*$"
highlight link rgContext Comment

syntax match rgComment "\v^[#-].*"
highlight link rgComment Comment
