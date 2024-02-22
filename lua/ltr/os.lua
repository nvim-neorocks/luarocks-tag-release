local OS = {}
---@param filename string
---@return string? content
function OS.read_file(filename)
  local content
  local f = io.open(filename, 'r')
  if f then
    content = f:read('*a')
    f:close()
  end
  return content
end

---@param filename string
---@return boolean file_exists
function OS.file_exists(filename)
  local f = io.open(filename, 'r')
  if f then
    f:close()
    return true
  end
  return false
end

---@param filename string
---@param content string
---@return nil
function OS.write_file(filename, content)
  local outfile = assert(io.open(filename, 'w'), 'Could not create ' .. filename .. '.')
  outfile:write(content)
  outfile:close()
end

---@param cmd string
---@param on_failure fun(error_msg:string)?
---@param verbose boolean|nil If true, will print stdout and stderr
---@return string stdout, string stderr
function OS.execute(cmd, on_failure, verbose)
  print('RUNNING: ' .. cmd)
  on_failure = on_failure or error
  local exec_out = 'exec_out.txt'
  local exec_err = 'exec_err.txt'
  local to_exec_out = ' >' .. exec_out .. ' 2>' .. exec_err
  local exit_code = os.execute(cmd .. to_exec_out)
  local stdout = OS.read_file(exec_out) or ''
  local stderr = OS.read_file(exec_err) or ''
  if exit_code ~= 0 then
    on_failure(cmd .. ' FAILED\nexit code: ' .. exit_code .. '\nstdout: ' .. stdout .. '\nstderr: ' .. stderr)
  elseif verbose then
    print(stdout)
    print(stderr)
  end
  return stdout, stderr
end

---Filter out directories that don't exist.
---@param directories string[] List of directories.
---@return string[] existing_directories
function OS.filter_existing_directories(directories)
  local existing_directories = {}
  for _, dir in pairs(directories) do
    if require('lfs').attributes(dir, 'mode') == 'directory' then
      existing_directories[#existing_directories + 1] = dir
    end
  end
  return existing_directories
end

return OS
