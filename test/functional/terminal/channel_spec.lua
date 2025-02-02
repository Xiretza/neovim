local helpers = require('test.functional.helpers')(after_each)
local clear = helpers.clear
local eq = helpers.eq
local command = helpers.command
local pcall_err = helpers.pcall_err
local feed = helpers.feed
local sleep = helpers.sleep
local poke_eventloop = helpers.poke_eventloop

describe('associated channel is closed and later freed for terminal', function()
  before_each(clear)

  it('opened by nvim_open_term() and deleted by :bdelete!', function()
    command([[let id = nvim_open_term(0, {})]])
    -- channel hasn't been freed yet
    eq("Vim(call):Can't send data to closed stream", pcall_err(command, [[bdelete! | call chansend(id, 'test')]]))
    -- channel has been freed after one main loop iteration
    eq("Vim(call):E900: Invalid channel id", pcall_err(command, [[call chansend(id, 'test')]]))
  end)

  it('opened by termopen(), exited, and deleted by pressing a key', function()
    command([[let id = termopen('echo')]])
    sleep(500)
    -- process has exited
    eq("Vim(call):Can't send data to closed stream", pcall_err(command, [[call chansend(id, 'test')]]))
    -- delete terminal
    feed('i<CR>')
    -- need to first process input
    poke_eventloop()
    -- channel has been freed after another main loop iteration
    eq("Vim(call):E900: Invalid channel id", pcall_err(command, [[call chansend(id, 'test')]]))
  end)

  -- This indirectly covers #16264
  it('opened by termopen(), exited, and deleted by :bdelete', function()
    command([[let id = termopen('echo')]])
    sleep(500)
    -- process has exited
    eq("Vim(call):Can't send data to closed stream", pcall_err(command, [[call chansend(id, 'test')]]))
    -- channel hasn't been freed yet
    eq("Vim(call):Can't send data to closed stream", pcall_err(command, [[bdelete | call chansend(id, 'test')]]))
    -- channel has been freed after one main loop iteration
    eq("Vim(call):E900: Invalid channel id", pcall_err(command, [[call chansend(id, 'test')]]))
  end)
end)
