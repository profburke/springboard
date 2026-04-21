-- BUSTED! - what's busted precious? http://olivinelabs.com/busted/
-- sidenote: i don't condone calling dude's prescious.
--
-- Device-backed integration tests. These require a connected iOS device and
-- should not be treated as the default safety net. Run tests/offline.lua first.

package.path = '../?.lua;../?/init.lua;' .. package.path
package.cpath = '../?.so;../?/?.so;' .. package.cpath

inspect = require "inspect"
function pp(x,h) print(inspect(x)) return x end
traceback = debug.traceback

describe("springboard", function()
  local ios, conn, layout
  local plist_path = "test.plist"

  setup(function()
    ios = require "springboard"
  end)

  it("loaded ok", function() 
    assert.not_nil(ios) 
    assert.not_function(ios) 
  end)

  it("connects and disconnects", function() 
    conn = ios.connect() 
    conn:disconnect()
  end)

  it("retrieves layout", function() 
    conn = ios.connect() 
    layout = conn:layout()

    assert.not_nil(layout)
    assert.is.table(layout)
    assert.is.table(layout.dock)
    assert.is.table(layout.pages)

    conn:disconnect()
  end)

  it("searches", function() 
    conn = ios.connect() 
    layout = conn:layout()

    assert.not_nil(layout:find("Messages"))
    assert.is.table(layout:find_all("App"))

    local many = layout:find_all(".*")
    assert.is.truthy(#many > 1)

    conn:disconnect()
  end)

  -- !WARNING! this bad boy is live. backup your
  -- shit if u are planning on enabling it.
  -- it("sets icons", function() 
  --   conn = ios.connect() 
  --   layout = conn:layout()
  --   conn:set_layout(layout)
  --   conn:disconnect()
  -- end)

  it("complains when disconnected", function() 
    conn = ios.connect() 
    layout = conn:layout()
    conn:disconnect()

    assert.has_error(function() conn:layout() end)
  end)

  it("saves to disk", function() 
    conn = ios.connect() 
    layout = conn:layout()

    layout:save_plist(plist_path)
    data = io.open(plist_path,"r"):read()

    conn:disconnect()
  end)

  it("loads from disk", function() 
    conn = ios.connect() 

    layout = conn:layout()
    old = ios.load_plist(plist_path)
    assert.same(#layout.dock, #old.dock)
    assert.same(#layout.pages, #old.pages)
    for i=1,#layout.pages do
      assert.same(#layout.pages[i], #old.pages[i])
    end
    for j=1,#layout.dock do
      assert.same(layout.dock[j].name, old.dock[j].name)
    end
    for i=1,#layout.pages do
      for j=1,#layout.pages[i] do
        assert.same(layout.pages[i][j].name, old.pages[i][j].name)
      end
    end

    os.remove(plist_path)
    conn:disconnect()
  end)


  it("provides image data", function()
    conn = ios.connect() 
    layout = conn:layout()

    app = layout.dock[1]
    assert.not_nil(app.bundleIdentifier)
    assert.not_nil(conn:app_image(app))

    conn:disconnect()
  end)

end)


  
