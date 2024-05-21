local lib = import('lib')

function out_dir(file_dir)
    return file_dir:sub(1, #file_dir - 2) .. "cpp"
end