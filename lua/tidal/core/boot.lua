local Ghci = require("tidal.util.repl.ghci")
local Sclang = require("tidal.util.repl.sclang")
local state = require("tidal.core.state")

local M = {}

---Start a tidal repl
---@param opts TidalProcConfig
---@param split? 'v' | 'h' | nil
function M.tidal(opts, split)
  if not opts.enabled then
    return
  end

  state.ghci = Ghci:new({
    name = "tidal",
    cmd = opts.cmd,
    args = vim.list_extend({
      "-XOverloadedStrings",
      "-ghci-script=" .. vim.fn.expand(opts.file),
    }, opts.args or {}),
    on_exit = function(_code, _signal)
      state.ghci = nil
    end,
  }):start({
    split = split or "v",
  })
end

---Start an sclang instance
---@param opts TidalProcConfig
---@param split? 'v' | 'h' | nil
function M.sclang(opts, split)
  if not opts.enabled then
    return
  end

  state.sclang = Sclang:new({
    name = "sclang",
    cmd = opts.cmd,
    args = vim.list_extend({
      "-i",
      "scnvim",
    }, opts.args or {}),
    on_exit = function(_code, _signal)
      state.sclang = nil
    end,
    window = {
      split = "h",
    },
  }):start({
    split = split or "h",
  })

  -- load the boot file
  local file = vim.fn.expand(opts.file)
  state.sclang:send_line('"' .. file .. '".load;')

  -- initialize MIDI if enabled (with delay to ensure SuperDirt is ready to receive messages)
  if opts.midi and opts.midi.enabled then
    vim.defer_fn(function()
      local message = require("tidal.core.message")

      local device_name = opts.midi.device_name or "Virtual Raw MIDI 4-0"
      local port_name = opts.midi.port_name or "VirMIDI 4-0"
      local latency = opts.midi.latency or 0.0
      local symbol = opts.midi.symbol or "midi"

      message.sclang.send_line(
        string.format(
          '(MIDIClient.init; ~midiOut = MIDIOut.newByName("%s", "%s"); ~midiOut.latency = %s; ~dirt.soundLibrary.addMIDI(\\%s, ~midiOut);)',
          device_name,
          port_name,
          latency,
          symbol
        )
      )
    end, 3000)
  end
end

return M
