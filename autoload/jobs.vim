" A dictionary with all the 'du' jobs in progress, The key is the
" directory to call 'du' for, the value is another dict with the following keys:
"    'dir': the directory on which 'du' was called upon
"    'jobstart': the starting time of the job
"    'callback': the callback to call with tthe result of the job
let b:running_du_jobs = {}

silent! let s:log = log#getLogger(expand('<sfile>:t'))


""
" Request the disk usage for the given {dirs}.
"
" This calls the external 'du' command to request the size.
" This function runs asynchronously. The size of the directories is not
" directly returned, but instead the given {callback} is called for each
" directory.
"
" For each given directory only one 'du' process may be queued. If there is
" already a process running for it, the request is silently being ignored.
"
" @param {dirs} a list of directories to call 'du' on.
" @param {callback} a funcref to call for each directory.
"                   the callback must take two parameters, the first one is
"                   the name of the directory (exactly as given in the
"                   {dirs} list) and the second one is the size returned
"                   from 'du'.
function! jobs#start_get_dir_size(dirs, callback) abort
  let dirs = []

  " Ensure that only directories are being processed that don't have an
  " already queued or running process
  for dir in a:dirs
    let l:job_already_running = v:false
    for running_job in values(b:running_du_jobs)
      if running_job['dir'] ==# dir
        silent! call s:log.debug("There is already a 'du' job running for '" . dir . "' since " . running_job['jobstart'])
        let l:job_already_running = v:true
        break
      endif
    endfor

    if !l:job_already_running
      let dirs = add(dirs, dir)
      let b:running_du_jobs[dir] = {'dir': dir, 'job_id': v:null, 'jobstart': strftime('%Y-%m-%d %H:%M:%S'), 'callback': a:callback}
    endif
  endfor

  " Call a timer for the actual execution of the 'du' process to have them
  " executed asynchronously.
  let b:stop_all_jobs = v:false
  let timer = timer_start(0, function('s:call_du', [dirs, a:callback]))

  " Update the running job info with the timer-id
  for dir in dirs
    let job_info = b:running_du_jobs[dir]
    if job_info is v:null
      silent! call s:log.error("No job-info found for dir " . dir . ". This is likely a bug.")
    else
      let job_info['job-id'] = timer
    endif
  endfor
endfunction


""
" Call 'du' on each dir in {dirs} and call the {callback} with the result.
"
" This calls 'du' for each dir in {dirs} in sequence. Therefore only one
" 'du' process will be running at a time (for this function call).
"
" This method is running recursively. For each call only one directory is
" processed. After that one finishes this function is called again for the
" remaining directories. This is done to let vim do other work in between.
" Otherwise all directories would be processed in one batch and the result
" would only be visible after all directories were processed.
"
" @param {dirs} a list of directories to call 'du' on.
" @param {callback} a funcref to call for the result of each directory.
"                   the callback must take two parameters, the first one is
"                   the name of the directory (exactly as given in the
"                   {dirs} list) and the second one is the size returned
"                   from 'du'.
function! s:call_du(dirs, callback, timer_id) abort
  if len(a:dirs) ==# 0
    return
  endif

  " Using systemlist merges stdout and stderr. To avoid this we change the
  " shellredir option of vim to not include stderr.
  " If we want to process stderr separately (for example to display it to the
  " user), we would have to resort to ':h job_start' (for vim) or ':h
  " jobstart' (for neovim).
  " Maybe it would also help to redirect stderr to a separate file and reread
  " that. But this seems to be even more of a hassle.
  silent! call s:log.trace("Running 'du' for " . a:dirs[0])
  let l:shellredir = &shellredir
  setl shellredir=>
  let l:stdout= systemlist(['/usr/bin/du', '-sh', a:dirs[0]])
  let &shellredir = l:shellredir
  let l:dir_and_size = s:process_du_stdout(l:stdout)
  let l:size= substitute(l:dir_and_size[0], ',', '.', '')  " naiive way to avoid locale differences for thousands separator
  let l:dir = l:dir_and_size[1]
  silent! call s:log.trace("Result of 'du' for " . a:dirs[0] . ": " . l:size . ' ' . l:dir)

  " Remove the directory from the list of queued/running jobs
  if has_key(b:running_du_jobs, l:dir)
    let l:jobdata = remove(b:running_du_jobs, l:dir)
  endif

  " Call the callback function with the result
  silent! call s:log.debug("du-job with id=".a:channel.' for dir='.l:jobdata['dir'].' finished.')
  call a:callback(l:dir, l:size)

  " If there are still directories left, call this function again (unless
  " aborting all jobs was requested).
  if len(a:dirs) ># 1 && !b:stop_all_jobs
    call timer_start(10, function('s:call_du', [a:dirs[1:], a:callback]))
  endif
endfunction


""
" Process the output of a 'du' job and split it into the size and directory
" name.
"
" @param {stdout} the output from the 'du' job. Must be a list returned
"                 from ':h systemlist()'
"
" @return a list with two values. The first one is the size, the second one
"         is the directory name
function! s:process_du_stdout(stdout) abort
  if len(a:stdout) ==# 0 || len(a:stdout[0]) ==# 0
    silent! call s:log.warn("stdout was unexpectedly empty")
    return '??'
  endif

  " Usually there should be only one value
  return matchlist(a:stdout[0], '^\(.\{-}\)\s\+\(.*\)$')[1:2]
endfunction


""
" This function is cancels all timers for the du-jobs and sets a flag to
" avoid running more already queued 'du' jobs.
function! jobs#cancel_all() abort
  let b:stop_all_jobs = v:true
  for job in values(b:running_du_jobs)
    let job_id= job['job_id']
    silent! call s:log.debug("Stopping job: " . string(job))
    call timer_stop(job_id)
    call remove(b:running_du_jobs, job_id)
  endfor
endfunction

