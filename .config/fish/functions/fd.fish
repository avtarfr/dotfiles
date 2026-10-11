function fd
    if test (count $argv) -eq 1; and not string match -q -- "-*" $argv[1]
        command fd $argv[1] ~
    else
        command fd $argv
    end
end
